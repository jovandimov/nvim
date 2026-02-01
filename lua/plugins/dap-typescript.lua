-- TypeScript/JavaScript DAP configuration
return {
  -- Ensure mason-nvim-dap installs the js-debug-adapter
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      ensure_installed = { "js" }, -- installs js-debug-adapter
    },
  },

  -- Configure nvim-dap for TypeScript/JavaScript
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      -- Use the js-debug-adapter installed by mason
      if not dap.adapters["pwa-node"] then
        dap.adapters["pwa-node"] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            args = {
              require("mason-registry").get_package("js-debug-adapter"):get_install_path()
                .. "/js-debug/src/dapDebugServer.js",
              "${port}",
            },
          },
        }
      end

      -- TypeScript/JavaScript configurations
      local js_based_languages = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

      for _, language in ipairs(js_based_languages) do
        dap.configurations[language] = {
          -- Attach to running process (default port 9229)
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process (port 9229)",
            port = 9229,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
          },
          -- Attach with custom port
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach (pick port)",
            port = function()
              return tonumber(vim.fn.input("Port: ", "9229"))
            end,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
          },
          -- Launch current file with tsx
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file (tsx)",
            runtimeExecutable = "tsx",
            runtimeArgs = { "${file}" },
            cwd = "${workspaceFolder}",
            sourceMaps = true,
          },
          -- Launch current file with node
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file (node)",
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
          },
        }
      end
    end,
  },
}
