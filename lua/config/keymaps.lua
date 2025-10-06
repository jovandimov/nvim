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

-- local dap = require("dap")
--
-- vim.keymap.set("n", "<F5>", function()
--   dap.continue()
-- end, { desc = "Debug: Start/Continue" })
-- vim.keymap.set("n", "<F10>", function()
--   dap.step_over()
-- end, { desc = "Debug: Step Over" })
-- vim.keymap.set("n", "<F11>", function()
--   dap.step_into()
-- end, { desc = "Debug: Step Into" })
-- vim.keymap.set("n", "<F12>", function()
--   dap.step_out()
-- end, { desc = "Debug: Step Out" })
-- vim.keymap.set("n", "<leader>db", function()
--   dap.toggle_breakpoint()
-- end, { desc = "Debug: Toggle Breakpoint" })
-- vim.keymap.set("n", "<leader>dB", function()
--   dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
-- end, { desc = "Debug: Conditional Breakpoint" })
