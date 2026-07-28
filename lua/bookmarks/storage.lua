local M = {}
local core = require("bookmarks.core")
local config = require("bookmarks.config")

M.dirty = false

function M.mark_dirty()
    M.dirty = true
end

function M.get_project_file()
    local dir = config.options.storage_dir
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
    
    local cwd = vim.fn.getcwd()
    -- Replace each path separator with "%%" (double-percent) to produce a
    -- flat filename that encodes the project path, e.g. "/home/user/proj"
    -- becomes "%%home%%user%%proj.json".  The Lua pattern "[/\\]" has no
    -- captures, so "%%" in the replacement string means a literal '%'.
    local project_name = cwd:gsub("[/\\]", "%%")
    return dir .. "/" .. project_name .. ".json"
end

function M.save(force)
    if not force and not M.dirty then return end
    local path = M.get_project_file()
    local data = core.bookmarks

    local f = io.open(path, "w")
    if f then
        f:write(vim.json.encode(data))
        f:close()
        M.dirty = false
    else
        vim.notify("bookmarks.nvim: Failed to save bookmarks to " .. path, vim.log.levels.ERROR)
    end
end

function M.load()
    local path = M.get_project_file()
    local f = io.open(path, "r")
    if f then
        local content = f:read("*a")
        f:close()
        
        if content and content ~= "" then
            local ok, data = pcall(vim.json.decode, content)
            if ok and type(data) == "table" then
                core.bookmarks = data
            end
        end
    end
end

return M
