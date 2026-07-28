local M = {}

M.options = {
    -- default options
    storage_dir = vim.fn.stdpath("data") .. "/bookmarks",
    sign_icon = "󰃃",
    sign_hl = "DiagnosticInfo",
    virt_text_hl = "Comment",
    virt_text_prefix = " 🔖 ",
    desc_hl = "Special",   -- highlight group for bookmark description in picker; "" = no color
    fzf_opts = {},
}

function M.setup(opts)
    if opts and type(opts) ~= "table" then
        vim.notify("bookmarks.nvim: setup() expects a table or nil", vim.log.levels.ERROR)
        return
    end
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})

    -- Validate critical options that would cause extmark errors if wrong type
    if type(M.options.sign_icon) ~= "string" then
        vim.notify("bookmarks.nvim: sign_icon must be a string", vim.log.levels.WARN)
        M.options.sign_icon = "󰃃"
    end
    if type(M.options.sign_hl) ~= "string" then
        vim.notify("bookmarks.nvim: sign_hl must be a string", vim.log.levels.WARN)
        M.options.sign_hl = "DiagnosticInfo"
    end
    if type(M.options.virt_text_hl) ~= "string" then
        vim.notify("bookmarks.nvim: virt_text_hl must be a string", vim.log.levels.WARN)
        M.options.virt_text_hl = "Comment"
    end
end

return M
