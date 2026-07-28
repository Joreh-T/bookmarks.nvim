local M = {}
local core = require("bookmarks.core")
local config = require("bookmarks.config")

local ns = vim.api.nvim_create_namespace("bookmarks")

---Return a short default description for a bookmark at the given line.
---Uses the line content (trimmed and truncated) so it works with any file
---type, no treesitter dependency needed.
---@param buf  number  Buffer handle
---@param line number  0-indexed line number
---@return string
function M.get_line_context(buf, line)
    local text = vim.api.nvim_buf_get_lines(buf, line, line + 1, false)[1]
    if not text then return "Bookmark" end
    text = text:match("^%s*(.-)%s*$") -- trim leading/trailing whitespace
    if text == "" then return "Bookmark" end
    if #text > 50 then
        text = text:sub(1, 47) .. "..."
    end
    return text
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
