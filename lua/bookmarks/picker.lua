local M = {}
local core = require("bookmarks.core")
local mark = require("bookmarks.mark")
local storage = require("bookmarks.storage")
local config = require("bookmarks.config")

---Convert a vim highlight group to an ANSI foreground-color escape sequence.
---Returns nil if the group cannot be resolved.
local function hl_to_ansi_fg(hl_group)
    if not hl_group or hl_group == "" then return nil end
    local fg_hex = vim.fn.synIDattr(vim.fn.hlID(hl_group), "fg#")
    if not fg_hex or fg_hex == "" then return nil end
    local r = tonumber(fg_hex:sub(2, 3), 16)
    local g = tonumber(fg_hex:sub(4, 5), 16)
    local b = tonumber(fg_hex:sub(6, 7), 16)
    if not r then return nil end
    return string.format("\27[38;2;%d;%d;%dm", r, g, b)
end

function M.open_fzf()
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then
        vim.notify("fzf-lua is required for bookmarks UI", vim.log.levels.ERROR)
        return
    end

    -- Resolve description highlight color to ANSI (once, not per-item)
    local desc_ansi_start = hl_to_ansi_fg(config.options.desc_hl)
    local desc_ansi_end = desc_ansi_start and "\27[0m" or ""

    local items = {}
    local mark_lookup = {} -- plain (uncolored) display string → mark data
    local all_marks = core.get_all()

    -- Format (colored for fzf):  "[ANSI]desc[reset]  —  file:line (freq: X)"
    -- Lookup is keyed by the plain version so ANSI stripping in fzf output
    -- doesn't break the match.
    for _, m in ipairs(all_marks) do
        local line_1_indexed = m.line + 1
        local plain = string.format("%s  —  %s:%d (freq: %d)",
            m.desc, m.file, line_1_indexed, m.fre)
        local display = desc_ansi_start
            and string.format("%s%s%s  —  %s:%d (freq: %d)",
                desc_ansi_start, m.desc, desc_ansi_end, m.file, line_1_indexed, m.fre)
            or plain
        table.insert(items, display)
        mark_lookup[plain] = m
    end

    -- Helper: fzf may or may not preserve ANSI codes in its return value;
    -- strip them and use the plain string for lookup.
    local function resolve_sel(sel)
        if not sel then return nil end
        -- Try direct lookup first (no ANSI codes in the string)
        local m = mark_lookup[sel]
        if m then return m end
        -- Strip ANSI SGR sequences and retry
        local clean = sel:gsub("\027%[[0-9;]*m", "")
        return mark_lookup[clean]
    end

    local fzf_opts = vim.tbl_deep_extend("keep",
        config.options.fzf_opts or {}, {
            ["--ansi"] = "",
            ["--header"] = " <CR> jump  |  ctrl-d delete",
        })
    fzf.fzf_exec(items, {
        prompt = "Bookmarks> ",
        fzf_opts = fzf_opts,
        actions = {
            ["default"] = function(selected)
                local m = resolve_sel(selected[1])
                if not m then return end

                vim.cmd("edit " .. vim.fn.fnameescape(m.file))
                vim.api.nvim_win_set_cursor(0, { m.line + 1, 0 })

                -- Increment frequency on the exact bookmark by ID
                m.fre = m.fre + 1
                m.updated_at = os.time()
                storage.mark_dirty()
            end,
            ["ctrl-d"] = function(selected)
                local m = resolve_sel(selected[1])
                if not m then return end

                core.remove(m.file, m.id)
                storage.mark_dirty()
                vim.notify("Bookmark deleted", vim.log.levels.INFO)

                -- Re-render if buffer is loaded
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) == m.file then
                        mark.render(buf)
                    end
                end
                storage.save()
            end
        }
    })
end

return M
