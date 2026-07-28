# bookmarks.nvim

Remember file locations with descriptions, persist them per-project, and jump back
to them via [fzf-lua](https://github.com/ibhagwan/fzf-lua).

Bookmarks are rendered in-buffer as **sign-column icons + virtual text** using Neovim
native extmarks.

## Features

- Add / delete bookmarks with a description on any line
- **Sign icon** in the sign column and **virtual text** at end-of-line
- **fzf-lua** picker for browsing, jumping, and deleting bookmarks
- Treesitter-aware: auto-detects function/class name as the default description
- Per-project JSON storage (keyed by `getcwd()`)
- Frequency and last-used tracking
  
## Install

Requires **Neovim >= 0.7** and **fzf-lua**.

**lazy.nvim**

```lua
{
    'Joreh-T/bookmarks.nvim',
    keys = {
        { '<leader>ba', '<cmd>BookmarksAdd<cr>',    desc = 'Add bookmark' },
        { '<leader>bd', '<cmd>BookmarksDelete<cr>', desc = 'Delete bookmark' },
        { '<leader>bl', '<cmd>BookmarksList<cr>',   desc = 'List bookmarks' },
    },
    dependencies = { 'ibhagwan/fzf-lua' },
    config = function()
        require('bookmarks').setup()
    end,
}
```

**packer**

```lua
use {
    'Joreh-T/bookmarks.nvim',
    requires = { 'ibhagwan/fzf-lua' },
    config = function()
        require('bookmarks').setup()
    end,
}
```

## Commands

| Command             | Description                          |
| ------------------- | ------------------------------------ |
| `BookmarksAdd`      | Add a bookmark at the current line   |
| `BookmarksDelete`   | Delete all bookmarks on current line |
| `BookmarksList`     | Open the fzf-lua bookmark picker     |


## Default Configuration

```lua
require('bookmarks').setup({
    -- Where per-project JSON files are stored
    storage_dir = vim.fn.stdpath('data') .. '/bookmarks',

    -- Sign column icon and highlight
    sign_icon = '󰃃',
    sign_hl   = 'DiagnosticInfo',

    -- Inline virtual text prepended before the description
    virt_text_prefix = ' 🔖 ',
    virt_text_hl     = 'Comment',

    -- Highlight group for the description column in the fzf picker.
    -- Set to '' to disable color.
    desc_hl = 'Special',

    -- Extra options forwarded to fzf-lua's fzf_exec()
    fzf_opts = {},
})
```

## Picker

`:BookmarksList` opens an fzf window showing all bookmarks:

```
[colored desc]  —  /path/to/file:line (freq: N)
```

| Key       | Action                                    |
| --------- | ----------------------------------------- |
| `<CR>`    | Jump to bookmark (increments frequency)   |
| `ctrl-d`  | Delete the selected bookmark              |

The description is colorized using the `desc_hl` highlight group
(default: `Special`). Set `desc_hl = ''` to use the terminal default color.

## Data Storage

Bookmarks are saved as per-project JSON files under `storage_dir`. The filename
is derived from the current working directory so switching projects automatically
loads the right set of bookmarks.

```
~/.local/share/nvim/bookmarks/
  %%home%%user%%project.json
  %%home%%user%%other.json
```

Data is written:
- Immediately after `BookmarksAdd` / `BookmarksDelete`
- On `BufWritePre` — only if bookmark data actually changed (dirty-flag gated)
- On `VimLeavePre` — always (force-save)

## Highlights

| Highlight group       | Where                          |
| --------------------- | ------------------------------ |
| `DiagnosticInfo`      | Sign column icon (configurable via `sign_hl`) |
| `Comment`             | End-of-line virtual text (configurable via `virt_text_hl`) |
| `Special`             | Picker description text (configurable via `desc_hl`) |

## API

```lua
local bookmarks = require('bookmarks')

-- Add a bookmark at the current cursor position (same as :BookmarksAdd)
bookmarks.add()

-- Delete bookmarks on the current line (same as :BookmarksDelete)
bookmarks.delete()

-- Open the fzf-lua picker (same as :BookmarksList)
bookmarks.list()
```
