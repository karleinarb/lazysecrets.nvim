-- Loads the plugin as Neovim would and drives it, with `cat` standing in
-- for lazysecrets. Fails (exits non-zero) on the first broken assertion.
--
--   nvim --clean -l tests/smoke.lua

local root = vim.fn.getcwd()
local tmp = vim.fn.tempname()
vim.opt.rtp:prepend(root)
vim.cmd.runtime("plugin/lazysecrets.lua")

assert(vim.fn.exists(":Lazysecrets") == 2, ":Lazysecrets isn't defined without setup()")
assert(not package.loaded.lazysecrets, "the module loads before it's used")

local m = require("lazysecrets")
m.setup({ cmd = "cat", theme_path = tmp .. "/theme.yaml", win = { width = 0.5 } })
assert(m.config.win.height == 0.9, "setup() replaced the defaults it didn't set")

-- A second repo, to open from.
local other = tmp .. "/other"
vim.fn.mkdir(other .. "/sub", "p")
vim.fn.mkdir(other .. "/.git", "p")

local function job()
  return vim.b[vim.api.nvim_get_current_buf()].terminal_job_id
end

m.open({ cwd = root })
local first = job()
assert(first, "open() didn't start a terminal")
assert(vim.api.nvim_win_get_config(0).relative == "editor", "open() isn't in a float")
assert(vim.fn.filereadable(m.config.theme_path) == 1, "open() didn't write the theme")
assert(vim.fn.readfile(m.config.theme_path)[2] == "theme:", "the theme file has no theme")

vim.cmd.wincmd("p")
m.open({ cwd = root .. "/lua" })
assert(job() == first, "opening in the same repo started another lazysecrets")

m.open()
assert(job() == first, "opening from the float started another lazysecrets")

vim.cmd.wincmd("p")
m.open({ cwd = other .. "/sub" })
assert(job() ~= first, "opening in another repo reused the first one")

vim.fn.delete(tmp, "rf")
print("ok")
