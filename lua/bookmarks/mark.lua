local M = {}
local core = require("bookmarks.core")
local config = require("bookmarks.config")

local ns = vim.api.nvim_create_namespace("bookmarks")

function M.get_treesitter_context(buf, line)
    local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
    if not ok then return nil end
    local parsers = require("nvim-treesitter.parsers")
    if not parsers.has_parser() then return nil end

    -- If a line was provided, temporarily move the cursor there to get the
    -- correct node; restore afterwards so the caller is not surprised.
    local saved_win, saved_cursor
    if line then
        saved_win = vim.api.nvim_get_current_win()
        saved_cursor = vim.api.nvim_win_get_cursor(saved_win)
        pcall(vim.api.nvim_win_set_cursor, saved_win, { line + 1, 0 })
    end

    local node = ts_utils.get_node_at_cursor()

    if saved_win then
        pcall(vim.api.nvim_win_set_cursor, saved_win, saved_cursor)
    end

    -- traverse up to find function or class
    while node do
        local type = node:type()
        if type == "function_declaration" or type == "method_declaration" or type == "class_declaration" then
            -- Get name node
            for child in node:iter_children() do
                if child:type() == "identifier" then
                    return vim.treesitter.get_node_text(child, buf)
                end
            end
            return type
        end
        node = node:parent()
    end
    return nil
end

function M.add_bookmark(buf, line, desc)
    local file = vim.api.nvim_buf_get_name(buf)
    if file == "" then return end

    if not desc or desc == "" then
        desc = "Bookmark"
    end

    local id = tostring(os.time()) .. "_" .. math.random(1000, 9999)

    local mark_data = {
        id = id,
        extmark_id = nil,
        line = line, -- 0-indexed
        desc = desc,
        fre = 0,
        updated_at = os.time(),
        tags = {},
    }

    core.add(file, mark_data)
    -- Re-render to create extmarks including the new bookmark
    M.render(buf)
end

function M.sync_extmarks(buf)
    local file = vim.api.nvim_buf_get_name(buf)
    if file == "" then return end

    local storage = require("bookmarks.storage")

    local marks = core.get_file_bookmarks(file)
    for _, mark in ipairs(marks) do
        if mark.extmark_id then
            local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, mark.extmark_id, {})
            if pos and #pos > 0 then
                if mark.line ~= pos[1] then
                    mark.line = pos[1]
                    storage.mark_dirty()
                end
            else
                -- Extmark no longer exists (buffer was wiped, etc.); clear stale ID
                -- so the next render() call will recreate it from the stored line.
                mark.extmark_id = nil
            end
        end
    end
end

function M.render(buf)
    local file = vim.api.nvim_buf_get_name(buf)
    if file == "" then return end
    
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    
    local marks = core.get_file_bookmarks(file)
    for _, mark in ipairs(marks) do
        local ok, extmark_id = pcall(vim.api.nvim_buf_set_extmark, buf, ns, mark.line, 0, {
            sign_text = config.options.sign_icon,
            sign_hl_group = config.options.sign_hl,
            virt_text = {{ config.options.virt_text_prefix .. mark.desc, config.options.virt_text_hl }},
            virt_text_pos = "eol",
        })
        if ok then
            mark.extmark_id = extmark_id
        end
    end
end

return M
