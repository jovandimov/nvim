-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable LazyVim's auto-format on save (manual formatting only)
vim.g.autoformat = false

-- TypeScript: use the native TypeScript 7 language server (Mason `tsc`) instead of vtsls
vim.g.lazyvim_ts_lsp = "tsc"

-- Only run Prettier in projects that have a Prettier config; Biome projects use biome-check
vim.g.lazyvim_prettier_needs_config = true

-- Indentation: Use 4 spaces (override LazyVim's 2-space default)
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- UI preferences
vim.opt.list = false          -- Hide invisible characters (tabs, trailing spaces)
vim.opt.updatetime = 50       -- Faster CursorHold events (LazyVim uses 200)
vim.opt.scrolloff = 8         -- More vertical context (LazyVim uses 4)

local mise_shims = vim.fn.expand("~/.local/share/mise/shims")
if vim.fn.isdirectory(mise_shims) == 1 then
  vim.env.PATH = mise_shims .. ":" .. vim.env.PATH
end

local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if vim.fn.isdirectory(mason_bin) == 1 then
  vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
end
