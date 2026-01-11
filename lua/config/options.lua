-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Indentation: Use 4 spaces (override LazyVim's 2-space default)
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- UI preferences
vim.opt.list = false          -- Hide invisible characters (tabs, trailing spaces)
vim.opt.updatetime = 50       -- Faster CursorHold events (LazyVim uses 200)
vim.opt.scrolloff = 8         -- More vertical context (LazyVim uses 4)
