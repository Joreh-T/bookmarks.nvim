local config = require("bookmarks.config")
local mark = require("bookmarks.mark")
local storage = require("bookmarks.storage")
local picker = require("bookmarks.picker")
local core = require("bookmarks.core")

local M = {}

function M.setup(opts)
    config.setup(opts)
    storage.load()
    
    local augroup = vim.api.nvim_create_augroup("BookmarksV2", { clear = true })
    
    -- Render for already opened buffers (useful if lazy-loaded)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            mark.render(buf)
        end
    end
    
    -- Auto render on BufReadPost (first load) and BufEnter (switch to already-open buffer)
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
        group = augroup,
        callback = function(args)
            mark.render(args.buf)
        end,
    })
    
    -- Auto sync and save on BufWritePre
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        callback = function(args)
            mark.sync_extmarks(args.buf)
            storage.save()
        end,
    })
    
    -- Save on VimLeavePre (force-save regardless of dirty flag)
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = augroup,
        callback = function()
            -- Sync all open buffers
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) then
                    mark.sync_extmarks(buf)
                end
            end
            storage.save(true)
        end,
    })
    
    -- User commands
    vim.api.nvim_create_user_command("BookmarksAdd", function()
        M.add()
    end, {})
    
    vim.api.nvim_create_user_command("BookmarksDelete", function()
        M.delete()
    end, {})

    vim.api.nvim_create_user_command("BookmarksList", function()
        M.list()
    end, {})
end

function M.delete()
    local buf = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(buf)
    if file == "" then
        vim.notify("BookmarksDelete: current buffer has no file", vim.log.levels.WARN)
        return
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1 -- 0-indexed

    local marks = core.get_file_bookmarks(file)
    local deleted = 0
    -- Iterate in reverse since we remove by ID while traversing
    for i = #marks, 1, -1 do
        if marks[i].line == line then
            core.remove(file, marks[i].id)
            deleted = deleted + 1
        end
    end

    if deleted > 0 then
        mark.render(buf)
        storage.mark_dirty()
        storage.save()
        vim.notify(string.format("Deleted %d bookmark(s)", deleted), vim.log.levels.INFO)
    else
        vim.notify("BookmarksDelete: no bookmark on this line", vim.log.levels.WARN)
    end
end

function M.add()
    local buf = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1 -- 0-indexed
    -- Use the current line's content as the default description
    local auto_desc = mark.get_line_context(buf, line)

    vim.ui.input({ prompt = "Bookmark Desc (" .. auto_desc .. "): " }, function(input)
        if input == nil then return end -- User cancelled
        local desc = (input == "") and auto_desc or input
        mark.add_bookmark(buf, line, desc)
        storage.mark_dirty()
        storage.save()
    end)
end

function M.list()
    picker.open_fzf()
end

return M
