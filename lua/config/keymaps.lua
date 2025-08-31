-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("n", "<leader>cc", "<cmd>close<cr>", { desc = "Close window" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit window" })
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit all (force)" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader>W", "<cmd>wa<cr>", { desc = "Save all files" })

-- Function to jump to the previously opened buffer
local function jump_to_prev_buffer()
  local alt_buf = vim.fn.bufnr("#")
  if alt_buf > 0 and vim.api.nvim_buf_is_valid(alt_buf) then
    vim.cmd("buffer #")
  else
    vim.notify("No previous buffer", vim.log.levels.WARN)
  end
end

-- Map it to <Tab><Tab> in normal mode
vim.keymap.set("n", "<Tab><Tab>", jump_to_prev_buffer, { desc = "Switch to previous buffer" })

map("n", "<A-Left>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
map("n", "<A-Right>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
