local M = {}

-- State: table of bookmarks, keyed by file path
-- M.bookmarks[file_path] = { { id, line, desc, updated_at, fre }, ... }
M.bookmarks = {}

function M.add(file, mark_data)
    if not M.bookmarks[file] then
        M.bookmarks[file] = {}
    end
    table.insert(M.bookmarks[file], mark_data)
end

function M.remove(file, id)
    if not M.bookmarks[file] then return end
    for i, mark in ipairs(M.bookmarks[file]) do
        if mark.id == id then
            table.remove(M.bookmarks[file], i)
            break
        end
    end
end

function M.get_file_bookmarks(file)
    return M.bookmarks[file] or {}
end

function M.get_all()
    local all = {}
    for file, marks in pairs(M.bookmarks) do
        for _, mark in ipairs(marks) do
            local copy = vim.deepcopy(mark)
            copy.file = file
            table.insert(all, copy)
        end
    end
    return all
end

---Increment the frequency counter on the original bookmark (not a copy).
---@param file string
---@param id   string
function M.increment_fre(file, id)
    local marks = M.bookmarks[file]
    if not marks then return end
    for _, mark in ipairs(marks) do
        if mark.id == id then
            mark.fre = mark.fre + 1
            mark.updated_at = os.time()
            return
        end
    end
end

return M
