# lazysecrets.nvim

Brings [lazysecrets](https://github.com/karleinarb/lazysecrets) to Neovim.

## Features
- Prioritizes showing the secrets in the repo you are in
- The lazysecrets session stays alive for the whole nvim session
- A `lazysecrets://` link opened from the browser or chat brings the hidden
  session back, unless you're in the middle of something (typing, a
  command, a picker): then it opens elsewhere (lazysecrets 0.5 or later)
- `e` on a file in lazysecrets will open it in your current nvim session
- Follows the `:colorscheme` you have set in nvim

## Requirements
Needs Neovim 0.11 or later and `lazysecrets` on your `PATH`. No other
plugins.

## Install

With `vim.pack` (Neovim 0.12):

```lua
vim.pack.add({ "https://git.kebcloud.no/keb/lazysecrets.nvim" })
vim.keymap.set("n", "<leader>ls", function() require("lazysecrets").open() end, { desc = "lazysecrets" })
```

With lazy.nvim:

```lua
{
  url = "https://git.kebcloud.no/keb/lazysecrets.nvim",
  name = "lazysecrets.nvim",
  opts = {},
  cmd = "Lazysecrets",
  keys = { { "<leader>ls", function() require("lazysecrets").open() end, desc = "lazysecrets" } },
}
```

## Use

- `:Lazysecrets` opens it; `:Lazysecrets <link>` opens a `lazysecrets://`
  link, Key Vault URL or reference.
- `require("lazysecrets").open({ args = { ... }, cwd = ..., win = { ... } })`
  does the same from Lua.

## Options

`setup()` is only needed to change these. The defaults:

```lua
require("lazysecrets").setup({
  cmd = "lazysecrets",
  -- The floating window: fractions of the editor, and its border.
  win = { width = 0.9, height = 0.9, border = "rounded" },
  -- Where the generated theme is written.
  theme_path = vim.fn.stdpath("cache") .. "/lazysecrets-theme.yaml",
  -- lazysecrets theme roles from highlight groups, e.g.
  -- theme = { activeBorderColor = { fg = "MatchParen", bold = true } },
})
```

See `lua/lazysecrets/init.lua` for every theme role and its default.

## Repositories

The main repo of this codebase is at [git.kebcloud.no](https://git.kebcloud.no/keb/lazysecrets.nvim).
The [GitHub mirror](https://github.com/karleinarb/lazysecrets.nvim) is for discoverability, issue-tracking and releases.
It also makes it possible to give a ⭐ if you like lazysecrets.nvim!

## Contributing

I don't take pull requests as I don't have time to review and test them.
But bug reports and ideas are very welcome!
Open an [issue on GitHub](https://github.com/karleinarb/lazysecrets.nvim/issues) and I'll have a look.

## AI disclosure

Built with help from an agentic coding assistant. Every change is requested, reviewed and tested by me before it's merged.

## License

Copyright © 2026 Karl-Einar Bergstrøm.

lazysecrets.nvim is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version. See [LICENSE](LICENSE).
