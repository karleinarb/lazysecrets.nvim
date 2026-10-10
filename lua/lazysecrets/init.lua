-- lazysecrets.nvim: lazysecrets in a floating terminal, themed from the
-- colorscheme. No dependencies beyond Neovim 0.11 and lazysecrets.
--
-- lazysecrets layers config files given comma-separated in
-- LAZYSECRETS_CONFIG_FILE, later ones winning per key. This writes a theme
-- file from highlight groups and layers it on top of the user's own
-- config, so the user's settings stay and only the colours follow nvim.
--
--   require("lazysecrets").setup({ ... })      -- optional, to change M.config
--   require("lazysecrets").open()              -- browse
--   require("lazysecrets").open({ args = { "lazysecrets://..." } }) -- open a link

local M = {}

---@class lazysecrets.Color
---@field fg? string|string[] highlight group whose foreground is the colour; with several, the first that has one
---@field bg? string|string[] highlight group whose background is the colour
---@field bold? boolean

M.config = {
  cmd = "lazysecrets",
  theme_path = vim.fn.stdpath("cache") .. "/lazysecrets-theme.yaml",
  -- lazysecrets theme roles (`lazysecrets` README, Theme) from highlight
  -- groups. A role taking a foreground can still read a group's
  -- background (`bg`), e.g. the search match colour from Search.
  -- stylua: ignore
  theme = {
    activeBorderColor               = { fg = "MatchParen", bold = true },
    inactiveBorderColor             = { fg = "FloatBorder" },
    selectedLineBgColor             = { bg = "Visual" },
    inactiveViewSelectedLineBgColor = { bg = "CursorLine" },
    defaultFgColor                  = { fg = "Normal" },
    optionsTextColor                = { fg = "Function" },
    searchMatchColor                = { bg = "IncSearch", bold = true },
    errorColor                      = { fg = "DiagnosticError" },
    warningColor                    = { fg = "DiagnosticWarn" },
    successColor                    = { fg = "DiagnosticOk", bold = true },
    noticeColor                     = { fg = "DiagnosticOk" },
    mutedColor                      = { fg = "Comment" },
    favouriteColor                  = { fg = "DiagnosticWarn" },
    valueColor                      = { fg = "String" },
    azureColor                      = { fg = "Function" },
    -- Not Constant: many schemes give it the search/match colour.
    databricksColor                 = { fg = { "@variable.builtin", "Exception" } },
    repoColor                       = { fg = "Statement" },
  },
  -- The floating window: width and height as fractions of the editor,
  -- border as nvim_open_win takes it.
  win = { width = 0.9, height = 0.9, border = "rounded" },
}

local dirty = true -- write the theme on first open, and after :colorscheme

---@param v lazysecrets.Color
---@return string[] # a theme value: "#rrggbb", then attributes
local function color(v)
  local out = {}
  local which = v.fg and "fg" or "bg"
  local groups = v.fg or v.bg
  for _, name in ipairs(type(groups) == "table" and groups or { groups }) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    if hl and hl[which] then
      table.insert(out, string.format("#%06x", hl[which]))
      break
    end
  end
  if v.bold then
    table.insert(out, "bold")
  end
  return out
end

local function write_theme()
  local lines = { "# Written by lazysecrets.nvim from the colorscheme; changes are overwritten.", "theme:" }
  local roles = vim.tbl_keys(M.config.theme)
  table.sort(roles)
  for _, role in ipairs(roles) do
    local c = color(M.config.theme[role])
    if #c > 0 then -- a group without that colour: lazysecrets keeps its default
      local quoted = vim.tbl_map(function(s)
        return string.format("%q", s)
      end, c)
      table.insert(lines, string.format("  %s: [%s]", role, table.concat(quoted, ", ")))
    end
  end
  vim.fn.mkdir(vim.fn.fnamemodify(M.config.theme_path, ":h"), "p")
  vim.fn.writefile(lines, M.config.theme_path)
  dirty = false
end

-- The user's config files, as lazysecrets would find them, then the theme.
local function config_files()
  local files = vim.tbl_filter(function(f)
    return f:match("%S")
  end, vim.split(vim.env.LAZYSECRETS_CONFIG_FILE or "", ",", { plain = true }))
  if #files == 0 then
    local base = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")
    files = { base .. "/lazysecrets/config.yaml" } -- a missing file is fine
  end
  if not vim.tbl_contains(files, M.config.theme_path) then
    table.insert(files, M.config.theme_path)
  end
  return table.concat(files, ",")
end

-- Where lazysecrets starts: the current file's folder when it's in a git
-- repo, so that repo opens with the files nearest this one first; else
-- nvim's working directory.
local function start_dir()
  local file = vim.api.nvim_buf_get_name(0)
  local dir = vim.fs.dirname(file)
  if vim.bo.buftype == "" and file ~= "" and vim.fn.isdirectory(dir) == 1 and vim.fs.root(dir, ".git") then
    return dir
  end
  return vim.fn.getcwd()
end

-- One lazysecrets at a time: hidden when you leave its window, shown
-- again by the next open, and replaced when opened with other arguments
-- or from another repo.
local term = {} ---@type { buf?: integer, win?: integer, job?: integer, key?: string, cfg?: table, stopped?: boolean }

local function running()
  return term.buf and vim.api.nvim_buf_is_valid(term.buf) and term.job and vim.fn.jobwait({ term.job }, 0)[1] == -1
end

local function geometry()
  local w = term.cfg or M.config.win
  local lines = vim.o.lines - vim.o.cmdheight
  local width = math.floor(vim.o.columns * w.width)
  local height = math.floor(lines * w.height)
  return {
    relative = "editor",
    width = width,
    height = height,
    col = math.max(0, math.floor((vim.o.columns - width) / 2) - 1), -- less the border
    row = math.max(0, math.floor((lines - height) / 2) - 1),
    style = "minimal",
    border = w.border,
  }
end

local function show()
  if not (term.win and vim.api.nvim_win_is_valid(term.win)) then
    term.win = vim.api.nvim_open_win(term.buf, true, geometry())
    vim.wo[term.win].winhighlight = "NormalFloat:Normal"
  else
    vim.api.nvim_set_current_win(term.win)
  end
  vim.cmd.startinsert()
end

local function hide()
  if term.win and vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_close(term.win, true)
  end
  term.win = nil
end

-- The last line lazysecrets printed: why it stopped, when it failed.
local function last_line(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i = #lines, 1, -1 do
    if lines[i]:match("%S") then
      return vim.trim(lines[i])
    end
  end
end

---@param opts? { args?: string[], win?: table, cwd?: string }
function M.open(opts)
  opts = opts or {}
  if vim.fn.executable(M.config.cmd) ~= 1 then
    vim.notify("lazysecrets isn't installed (no `" .. M.config.cmd .. "` on PATH)", vim.log.levels.ERROR)
    return
  end
  if running() and vim.api.nvim_get_current_buf() == term.buf then
    return show() -- from the float itself: there's no other repo to be in
  end
  local args = opts.args or {}
  local cwd = opts.cwd or start_dir() -- before the float is current
  local key = table.concat({ vim.fs.root(cwd, ".git") or cwd, unpack(args) }, "\0")
  if running() and term.key == key then
    return show()
  end
  if running() then
    term.stopped = true
    vim.fn.jobstop(term.job)
  end
  hide()
  if dirty then
    write_theme()
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local this = { buf = buf, key = key, cfg = vim.tbl_extend("force", M.config.win, opts.win or {}) }
  term = this
  show()
  this.job = vim.fn.jobstart(vim.list_extend({ M.config.cmd }, args), {
    term = true,
    cwd = cwd,
    env = { LAZYSECRETS_CONFIG_FILE = config_files() },
    on_exit = function(_, code)
      vim.schedule(function()
        local why = code ~= 0 and not this.stopped and vim.api.nvim_buf_is_valid(buf) and last_line(buf)
        if term == this then
          hide()
          term = {}
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        if why then
          vim.notify(why, vim.log.levels.ERROR)
        end
      end)
    end,
  })
  -- Scheduled: closing a window from its own WinLeave isn't allowed.
  -- Not if it's been replaced, or is current again by then.
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    callback = function()
      vim.schedule(function()
        if term == this and vim.api.nvim_get_current_win() ~= term.win then
          hide()
        end
      end)
    end,
  })
end

-- Here rather than in setup(), which is optional: they're needed once
-- the module is loaded, and before that there's nothing to update.
local group = vim.api.nvim_create_augroup("lazysecrets", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = function()
    dirty = true
  end,
})
vim.api.nvim_create_autocmd("VimResized", {
  group = group,
  callback = function()
    if term.win and vim.api.nvim_win_is_valid(term.win) then
      vim.api.nvim_win_set_config(term.win, geometry())
    end
  end,
})

---@param opts? table merged into M.config
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
