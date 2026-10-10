-- :Lazysecrets, without setup(). The module loads on first use.
if vim.g.loaded_lazysecrets then
  return
end
vim.g.loaded_lazysecrets = true

vim.api.nvim_create_user_command("Lazysecrets", function(cmd)
  require("lazysecrets").open({ args = cmd.fargs })
end, { nargs = "*", desc = "Open lazysecrets (optionally on a link)" })
