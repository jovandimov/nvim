-- DAP Interactive Features
-- Provides: Persistent REPL popup, Multi-line scratchpad, Watch expressions panel
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      -- Persistent REPL popup
      {
        "<leader>dR",
        function()
          require("config.dap-interactive").toggle_repl()
        end,
        desc = "Toggle REPL Popup",
      },
      -- Multi-line scratchpad (<leader>ds stays LazyVim's "Session")
      {
        "<leader>dS",
        function()
          require("config.dap-interactive").toggle_scratchpad()
        end,
        desc = "Toggle Scratchpad",
      },
      -- Watch expressions (<leader>dW group; <leader>dw stays LazyVim's "Widgets")
      {
        "<leader>dWa",
        function()
          require("config.dap-interactive").add_watch()
        end,
        desc = "Add Watch Expression",
        mode = { "n", "x" },
      },
      {
        "<leader>dWr",
        function()
          require("config.dap-interactive").remove_watch()
        end,
        desc = "Remove Watch Expression",
      },
      {
        "<leader>dWw",
        function()
          require("config.dap-interactive").toggle_watches()
        end,
        desc = "Toggle Watches Panel",
      },
    },
  },
}
