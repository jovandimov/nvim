-- your existing tab settings…
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

vim.opt.smartindent = true

-- then add:
vim.opt.list = true
vim.opt.listchars = {
  space = "·",
  eol = "↴",
  tab = "▸ ",
  trail = "·",
  extends = "❯",
  precedes = "❮",
}

vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.mouse = "a" -- Enable mouse support
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.undofile = true -- Persistent undo history
vim.opt.updatetime = 300 -- Faster completion
vim.opt.signcolumn = "yes" -- Show sign column (e.g., for Git/gutter)

vim.opt.ignorecase = true -- Ignore case in searches
vim.opt.smartcase = true -- But be smart when searching with caps
vim.opt.incsearch = true -- Incremental search
vim.opt.hlsearch = false -- Don’t highlight matches after search

vim.opt.wrap = false -- Don't wrap lines
vim.opt.scrolloff = 8 -- Keep 8 lines above/below cursor
vim.opt.sidescrolloff = 8 -- Keep cursor away from edges horizontally
vim.opt.cursorline = true -- Highlight current line
vim.opt.termguicolors = true -- Enable full color support
