--[[
OmniSharp LSP Configuration for C# Development

This configuration provides comprehensive C# support with:
- ✅ Decompiled .NET source viewing (works offline)
- ✅ Official .NET source from GitHub (via source links, requires internet)
- ✅ Full Roslyn analyzer support
- ✅ Inlay hints for types, parameters, and implicit declarations
- ✅ Import completion and organization

Keybindings:
  gd  - Goto Definition (quick, single result)
  gr  - References (quick)
  gy  - Goto Type Definition (quick)
  gI  - Goto Implementation (quick)
  
  <leader>gd - Goto Definition (with picker for multiple results)
  <leader>gr - References (with picker)
  <leader>gy - Goto Type Definition (with picker)
  <leader>gI - Goto Implementation (with picker)

How it works:
1. omnisharp-extended-lsp.nvim intercepts definition requests
2. When you navigate to .NET framework types (e.g., Console.WriteLine):
   - If source links are available → shows official Microsoft source
   - Otherwise → shows decompiled source code
3. Works seamlessly with your project code and external dependencies

Note: This overrides LazyVim's default dotnet extra configuration.
--]]

return {
  -- Force load omnisharp-extended when C# files are opened
  -- This plugin enables decompilation and proper navigation in .NET assemblies
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
    ft = { "cs", "vb" },
  },

  -- Override OmniSharp configuration from LazyVim dotnet extra
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = {
          -- Custom handler for textDocument/definition to enable decompilation
          handlers = {
            ["textDocument/definition"] = function(...)
              return require("omnisharp_extended").handler(...)
            end,
          },

          -- Keybindings: gd for quick navigation, <leader>gd for picker
          keys = {
            -- Quick navigation (single result, bypasses picker issues)
            {
              "gd",
              function()
                require("omnisharp_extended").lsp_definition()
              end,
              desc = "Goto Definition",
            },
            {
              "gr",
              function()
                require("omnisharp_extended").lsp_references()
              end,
              desc = "References",
            },
            {
              "gy",
              function()
                require("omnisharp_extended").lsp_type_definition()
              end,
              desc = "Goto Type Definition",
            },
            {
              "gI",
              function()
                require("omnisharp_extended").lsp_implementation()
              end,
              desc = "Goto Implementation",
            },

            -- Picker variants (when you want to see all results in a picker)
            {
              "<leader>gd",
              function()
                -- Use Telescope if available, otherwise fall back to LSP
                if LazyVim.has("telescope.nvim") then
                  require("omnisharp_extended").telescope_lsp_definition()
                else
                  require("omnisharp_extended").lsp_definition()
                end
              end,
              desc = "Goto Definition (Picker)",
            },
            {
              "<leader>gr",
              function()
                if LazyVim.has("telescope.nvim") then
                  require("omnisharp_extended").telescope_lsp_references()
                else
                  require("omnisharp_extended").lsp_references()
                end
              end,
              desc = "References (Picker)",
            },
            {
              "<leader>gy",
              function()
                if LazyVim.has("telescope.nvim") then
                  require("omnisharp_extended").telescope_lsp_type_definition()
                else
                  require("omnisharp_extended").lsp_type_definition()
                end
              end,
              desc = "Goto Type Definition (Picker)",
            },
            {
              "<leader>gI",
              function()
                if LazyVim.has("telescope.nvim") then
                  require("omnisharp_extended").telescope_lsp_implementation()
                else
                  require("omnisharp_extended").lsp_implementation()
                end
              end,
              desc = "Goto Implementation (Picker)",
            },
          },

          -- Enable all OmniSharp features
          enable_roslyn_analyzers = true,
          organize_imports_on_format = true,
          enable_import_completion = true,

          -- OmniSharp settings
          settings = {
            FormattingOptions = {
              EnableEditorConfigSupport = true,
              OrganizeImports = true,
            },
            MsBuild = {
              LoadProjectsOnDemand = false,
            },
            RoslynExtensionsOptions = {
              -- Enable Roslyn analyzers for better diagnostics
              EnableAnalyzersSupport = true,
              EnableImportCompletion = true,
              -- CRITICAL: Enable decompilation support for viewing .NET source
              EnableDecompilationSupport = true,
              AnalyzeOpenDocumentsOnly = false,
              -- Enable source link support for viewing official .NET source from GitHub
              EnableSourceLinking = true,
            },
            Sdk = {
              -- Support prerelease .NET SDKs
              IncludePrereleases = true,
            },
            -- C# specific settings
            csharp = {
              -- Enable all inlay hints for better code understanding
              inlayHints = {
                enableInlayHintsForImplicitObjectCreation = true,
                enableInlayHintsForImplicitVariableTypes = true,
                enableInlayHintsForLambdaParameterTypes = true,
                enableInlayHintsForTypes = true,
              },
            },
            omnisharp = {
              enableRoslynAnalyzers = true,
              enableEditorConfigSupport = true,
              enableImportCompletion = true,
              enableMsBuildLoadProjectsOnDemand = false,
              enableAsyncCompletion = true,
              organizeImportsOnFormat = true,
              useModernNet = true,
              -- Enable downloading source when available
              enablePackageRestoreOnOpen = true,
            },
          },
        },
      },
    },
  },

  --[[ ROSLYN CONFIG (commented out - can be re-enabled in the future)
  -- NOTE: Removed Crashdummyy registry since we're using manual installation
  -- If you need other packages from Crashdummyy registry, you can keep it
  -- Roslyn LSP for C# (manual installation for .NET 9 compatibility)
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "vb" },
    opts = {},
    config = function()
      local roslyn_path = vim.fn.expand("~/.local/share/roslyn/Microsoft.CodeAnalysis.LanguageServer.dll")
      
      vim.lsp.config("roslyn", {
        cmd = {
          "dotnet",
          roslyn_path,
          "--logLevel", "Information",
          "--extensionLogDirectory", vim.fn.expand("~/.local/state/nvim/roslyn"),
          "--stdio",
        },
        on_attach = function(client, bufnr)
          vim.notify("Roslyn LSP attached", vim.log.levels.INFO)
        end,
        settings = {
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_types = true,
            dotnet_enable_inlay_hints_for_indexer_parameters = true,
            dotnet_enable_inlay_hints_for_literal_parameters = true,
            dotnet_enable_inlay_hints_for_object_creation_parameters = true,
            dotnet_enable_inlay_hints_for_other_parameters = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
          },
          ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
          },
        },
      })
      vim.lsp.enable("roslyn")
    end,
  },
  --]]
}
