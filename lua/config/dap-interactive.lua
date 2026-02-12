-- DAP Interactive Features Implementation
-- Persistent REPL, Multi-line Scratchpad, Watch Expressions Panel

local M = {}

-- State management
local state = {
  repl_popup = nil,
  repl_buf = nil,
  scratchpad_popup = nil,
  scratchpad_buf = nil,
  scratchpad_result_popup = nil,
  watches_popup = nil,
}

-- Popup configuration
local popup_config = {
  relative = "editor",
  position = "50%",
  size = {
    width = "60%",
    height = "40%",
  },
  border = {
    style = "rounded",
    text = {
      top_align = "center",
    },
  },
  win_options = {
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  },
}

-- ============================================================================
-- PERSISTENT REPL POPUP
-- ============================================================================

function M.toggle_repl()
  local dap = require("dap")
  local Popup = require("nui.popup")

  -- Check if we have an active session
  if not dap.session() then
    vim.notify("No active debug session", vim.log.levels.WARN)
    return
  end

  -- If popup exists and is visible, hide it
  if state.repl_popup and state.repl_popup.winid and vim.api.nvim_win_is_valid(state.repl_popup.winid) then
    state.repl_popup:hide()
    return
  end

  -- If popup exists but hidden, show it
  if state.repl_popup and state.repl_buf and vim.api.nvim_buf_is_valid(state.repl_buf) then
    state.repl_popup:show()
    vim.api.nvim_set_current_win(state.repl_popup.winid)
    -- Go to insert mode at the end
    vim.cmd("startinsert")
    return
  end

  -- Create new popup with REPL buffer
  local repl = dap.repl

  -- Open REPL to get/create the buffer
  repl.open()
  local repl_buf = vim.api.nvim_get_current_buf()
  -- Close the split that was just opened
  vim.cmd("close")

  state.repl_buf = repl_buf

  -- Create floating popup
  state.repl_popup = Popup(vim.tbl_deep_extend("force", popup_config, {
    enter = true,
    focusable = true,
    bufnr = repl_buf,
    border = {
      style = "rounded",
      text = {
        top = " DAP REPL ",
        top_align = "center",
      },
    },
    size = {
      width = "70%",
      height = "50%",
    },
  }))

  state.repl_popup:mount()

  -- Keymaps for the REPL popup
  state.repl_popup:map("n", "q", function()
    state.repl_popup:hide()
  end, { noremap = true })

  state.repl_popup:map("n", "<Esc>", function()
    state.repl_popup:hide()
  end, { noremap = true })

  -- Go to insert mode
  vim.cmd("startinsert")
end

-- ============================================================================
-- MULTI-LINE SCRATCHPAD
-- ============================================================================

local function get_scratchpad_content()
  if not state.scratchpad_buf or not vim.api.nvim_buf_is_valid(state.scratchpad_buf) then
    return nil
  end
  local lines = vim.api.nvim_buf_get_lines(state.scratchpad_buf, 0, -1, false)
  return table.concat(lines, "\n")
end

local function evaluate_expression(expr)
  local dap = require("dap")

  if not dap.session() then
    vim.notify("No active debug session", vim.log.levels.WARN)
    return
  end

  -- Use dapui.eval for evaluation with result display
  local dapui = require("dapui")
  dapui.eval(expr)
end

local function evaluate_scratchpad()
  local content = get_scratchpad_content()
  if not content or content == "" then
    vim.notify("Scratchpad is empty", vim.log.levels.WARN)
    return
  end

  evaluate_expression(content)
end

local function evaluate_line_or_selection()
  local mode = vim.fn.mode()
  local expr

  if mode == "v" or mode == "V" then
    -- Visual mode: get selection
    vim.cmd('normal! "vy')
    expr = vim.fn.getreg("v")
  else
    -- Normal mode: get current line
    local line = vim.api.nvim_get_current_line()
    expr = line
  end

  if expr and expr ~= "" then
    evaluate_expression(expr)
  end
end

function M.toggle_scratchpad()
  local Popup = require("nui.popup")
  local dap = require("dap")

  -- Check for active debug session
  if not dap.session() then
    vim.notify("No active debug session", vim.log.levels.WARN)
    return
  end

  -- If popup exists and is visible, hide it
  if
    state.scratchpad_popup
    and state.scratchpad_popup.winid
    and vim.api.nvim_win_is_valid(state.scratchpad_popup.winid)
  then
    state.scratchpad_popup:hide()
    return
  end

  -- If popup exists but hidden, show it
  if state.scratchpad_popup and state.scratchpad_buf and vim.api.nvim_buf_is_valid(state.scratchpad_buf) then
    state.scratchpad_popup:show()
    vim.api.nvim_set_current_win(state.scratchpad_popup.winid)
    return
  end

  -- Create new scratchpad buffer
  state.scratchpad_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(state.scratchpad_buf, "filetype", "typescript")
  vim.api.nvim_buf_set_option(state.scratchpad_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_name(state.scratchpad_buf, "dap-scratchpad")

  -- Add placeholder text
  vim.api.nvim_buf_set_lines(state.scratchpad_buf, 0, -1, false, {
    "// DAP Scratchpad - Write code to evaluate",
    "// Keymaps:",
    "//   <C-CR> or <leader>r  - Evaluate all code",
    "//   <leader>e            - Evaluate current line/selection",
    "//   q                    - Close",
    "",
  })

  -- Create floating popup
  state.scratchpad_popup = Popup(vim.tbl_deep_extend("force", popup_config, {
    enter = true,
    focusable = true,
    bufnr = state.scratchpad_buf,
    border = {
      style = "rounded",
      text = {
        top = " DAP Scratchpad ",
        top_align = "center",
        bottom = " <C-CR> Eval All | <leader>e Eval Line | q Close ",
        bottom_align = "center",
      },
    },
    size = {
      width = "70%",
      height = "50%",
    },
  }))

  state.scratchpad_popup:mount()

  -- Keymaps for the scratchpad
  local opts = { noremap = true, silent = true }

  -- Close
  state.scratchpad_popup:map("n", "q", function()
    state.scratchpad_popup:hide()
  end, opts)

  -- Evaluate all (Ctrl+Enter)
  state.scratchpad_popup:map("n", "<C-CR>", evaluate_scratchpad, opts)
  state.scratchpad_popup:map("i", "<C-CR>", function()
    vim.cmd("stopinsert")
    evaluate_scratchpad()
  end, opts)

  -- Evaluate all with <leader>r
  state.scratchpad_popup:map("n", "<leader>r", evaluate_scratchpad, opts)

  -- Evaluate line/selection
  state.scratchpad_popup:map("n", "<leader>e", evaluate_line_or_selection, opts)
  state.scratchpad_popup:map("x", "<leader>e", evaluate_line_or_selection, opts)

  -- Move cursor to end
  vim.api.nvim_win_set_cursor(state.scratchpad_popup.winid, { 6, 0 })
end

-- ============================================================================
-- WATCH EXPRESSIONS
-- ============================================================================

function M.add_watch()
  local dap = require("dap")

  if not dap.session() then
    vim.notify("No active debug session", vim.log.levels.WARN)
    return
  end

  local expr

  -- Check if in visual mode
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" then
    -- Get visual selection
    vim.cmd('normal! "vy')
    expr = vim.fn.getreg("v")
  else
    -- Get word under cursor
    expr = vim.fn.expand("<cword>")
  end

  if expr and expr ~= "" then
    -- Use dapui's watches element
    local dapui = require("dapui")
    dapui.elements.watches.add(expr)
    vim.notify("Added watch: " .. expr, vim.log.levels.INFO)
  else
    -- Prompt for expression
    vim.ui.input({ prompt = "Watch expression: " }, function(input)
      if input and input ~= "" then
        local dapui = require("dapui")
        dapui.elements.watches.add(input)
        vim.notify("Added watch: " .. input, vim.log.levels.INFO)
      end
    end)
  end
end

function M.remove_watch()
  local dap = require("dap")

  if not dap.session() then
    vim.notify("No active debug session", vim.log.levels.WARN)
    return
  end

  local dapui = require("dapui")
  local watches = dapui.elements.watches.get()

  if #watches == 0 then
    vim.notify("No watches to remove", vim.log.levels.WARN)
    return
  end

  -- Create selection list
  local items = {}
  for i, watch in ipairs(watches) do
    table.insert(items, string.format("%d: %s", i, watch.expression))
  end

  vim.ui.select(items, { prompt = "Select watch to remove:" }, function(choice)
    if choice then
      local index = tonumber(choice:match("^(%d+):"))
      if index then
        dapui.elements.watches.remove(index)
        vim.notify("Removed watch", vim.log.levels.INFO)
      end
    end
  end)
end

function M.toggle_watches()
  local Popup = require("nui.popup")
  local dap = require("dap")

  if not dap.session() then
    vim.notify("No active debug session", vim.log.levels.WARN)
    return
  end

  -- If popup exists and is visible, hide it
  if state.watches_popup and state.watches_popup.winid and vim.api.nvim_win_is_valid(state.watches_popup.winid) then
    state.watches_popup:hide()
    return
  end

  local dapui = require("dapui")

  -- Get the watches buffer
  local watches_buf = dapui.elements.watches.buffer()

  -- If popup exists but hidden, show it
  if state.watches_popup then
    state.watches_popup:show()
    if state.watches_popup.winid then
      vim.api.nvim_set_current_win(state.watches_popup.winid)
    end
    return
  end

  -- Create floating popup with watches buffer
  state.watches_popup = Popup(vim.tbl_deep_extend("force", popup_config, {
    enter = true,
    focusable = true,
    bufnr = watches_buf,
    border = {
      style = "rounded",
      text = {
        top = " Watch Expressions ",
        top_align = "center",
        bottom = " <CR> Expand | d Remove | e Edit | q Close ",
        bottom_align = "center",
      },
    },
    size = {
      width = "50%",
      height = "40%",
    },
    position = {
      row = "20%",
      col = "70%",
    },
  }))

  state.watches_popup:mount()

  -- Trigger a render
  dapui.elements.watches.render()

  -- Keymaps
  local opts = { noremap = true, silent = true }

  state.watches_popup:map("n", "q", function()
    state.watches_popup:hide()
  end, opts)

  state.watches_popup:map("n", "<Esc>", function()
    state.watches_popup:hide()
  end, opts)
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

-- Clean up popups when debug session ends
vim.api.nvim_create_autocmd("User", {
  pattern = "DapTerminate",
  callback = function()
    -- Hide all popups but keep buffers for next session
    if state.repl_popup and state.repl_popup.winid and vim.api.nvim_win_is_valid(state.repl_popup.winid) then
      state.repl_popup:hide()
    end
    if
      state.scratchpad_popup
      and state.scratchpad_popup.winid
      and vim.api.nvim_win_is_valid(state.scratchpad_popup.winid)
    then
      state.scratchpad_popup:hide()
    end
    if state.watches_popup and state.watches_popup.winid and vim.api.nvim_win_is_valid(state.watches_popup.winid) then
      state.watches_popup:hide()
    end
  end,
})

return M
