--[[
OmniSharp C# / .NET LSP configuration.

Extends lazyvim.plugins.extras.lang.dotnet (which is OmniSharp-based) with:
- ✅ Decompiled .NET source viewing (works offline)
- ✅ Official .NET source via source links (requires internet)
- ✅ Full Roslyn analyzer support + inlay hints
- ✅ Import completion and organization
- ✅ CSharpier only in projects that opt in; otherwise OmniSharp formatting (like `dotnet format`)
- ❌ F# tooling (fsautocomplete / fantomas / fsharp parser) disabled

Navigation keymaps (C#/VB buffers):
  gd / gr / gy / gI          - goto via omnisharp-extended (handles decompiled sources)
  <leader>co                 - organize imports (via OmniSharp format)

Decompilation comes from omnisharp-extended-lsp.nvim (the textDocument/definition
handler below) together with RoslynExtensionsOptions.EnableDecompilationSupport /
EnableSourceLinking.

Note: this file is named dotnet.lua because it configures OmniSharp, not
seblyng/roslyn.nvim. Debugging lives in dap-dotnet.lua.
--]]

-- True when the project opted into CSharpier: a .csharpierrc* config upward, or csharpier
-- listed in the repo's local dotnet tool manifest (.config/dotnet-tools.json).
local function uses_csharpier(dir)
  if vim.fs.root(dir, { ".csharpierrc", ".csharpierrc.json", ".csharpierrc.yaml", ".csharpierrc.yml" }) then
    return true
  end
  local root = vim.fs.root(dir, ".config")
  local manifest = root and vim.fs.joinpath(root, ".config", "dotnet-tools.json")
  if manifest and vim.uv.fs_stat(manifest) then
    return table.concat(vim.fn.readfile(manifest), "\n"):lower():find("csharpier", 1, true) ~= nil
  end
  return false
end

local omnisharp_settings = {
  FormattingOptions = {
    EnableEditorConfigSupport = true,
    OrganizeImports = true,
  },
  MsBuild = {
    LoadProjectsOnDemand = false,
  },
  RoslynExtensionsOptions = {
    EnableAnalyzersSupport = true,
    EnableImportCompletion = true,
    -- Decompilation + official source-link support.
    EnableDecompilationSupport = true,
    EnableSourceLinking = true,
    -- Analyzer diagnostics for open files only; whole-solution analysis is slow on large solutions.
    AnalyzeOpenDocumentsOnly = true,
    InlayHintsOptions = {
      EnableForParameters = true,
      ForLiteralParameters = true,
      ForIndexerParameters = true,
      ForObjectCreationParameters = true,
      ForOtherParameters = true,
      SuppressForParametersThatDifferOnlyBySuffix = false,
      SuppressForParametersThatMatchMethodIntent = false,
      SuppressForParametersThatMatchArgumentName = false,
      EnableForTypes = true,
      ForImplicitVariableTypes = true,
      ForLambdaParameterTypes = true,
      ForImplicitObjectCreation = true,
    },
  },
  Sdk = {
    -- Support prerelease .NET SDKs.
    IncludePrereleases = true,
  },
}

-- OmniSharp reads its options only from `Section:Key=value` command-line arguments; it ignores
-- LSP settings (workspace/didChangeConfiguration). So start it with nvim-lspconfig's default
-- command plus the settings above flattened into arguments.
local function omnisharp_cmd(settings)
  local cmd = {
    vim.fn.executable("OmniSharp") == 1 and "OmniSharp" or "omnisharp",
    "-z", -- https://github.com/OmniSharp/omnisharp-vscode/pull/4300
    "--hostPID",
    tostring(vim.fn.getpid()),
    "DotNet:enablePackageRestore=false",
    "--encoding",
    "utf-8",
    "--languageserver",
  }
  local function flatten(tbl, prefix)
    for key, value in pairs(tbl) do
      local name = prefix and (prefix .. ":" .. key) or key
      if type(value) == "table" then
        flatten(value, name)
      else
        table.insert(cmd, name .. "=" .. tostring(value))
      end
    end
  end
  flatten(settings)
  return cmd
end

return {
  -- Drop the F# parser that lang.dotnet pulls in.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(p)
        return p ~= "fsharp"
      end, opts.ensure_installed or {})
    end,
  },

  -- Drop the F# formatter (fantomas) from Mason's ensure_installed.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(p)
        return p ~= "fantomas"
      end, opts.ensure_installed or {})
    end,
  },

  -- Load omnisharp-extended (decompilation + navigation) for C#/VB buffers.
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
    ft = { "cs", "vb" },
  },

  -- Formatters: csharpier for C# (only where the project uses it), and ensure fantomas isn't
  -- wired up for F#. Without csharpier, conform falls back to OmniSharp formatting, which
  -- follows .editorconfig like `dotnet format` does.
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.cs = { "csharpier" }
      opts.formatters_by_ft.fsharp = nil
      opts.formatters = opts.formatters or {}
      opts.formatters.csharpier = {
        condition = function(_, ctx)
          return uses_csharpier(ctx.dirname)
        end,
      }
    end,
  },

  -- LSP servers: disable F# (fsautocomplete), configure OmniSharp.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        fsautocomplete = { enabled = false },

        omnisharp = {
          -- Route go-to-definition through omnisharp-extended so navigating into
          -- framework / 3rd-party types shows source-linked or decompiled source.
          handlers = {
            ["textDocument/definition"] = function(...)
              return require("omnisharp_extended").handler(...)
            end,
          },

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

            -- Organize imports via OmniSharp formatting (FormattingOptions.OrganizeImports below)
            {
              "<leader>co",
              function()
                vim.lsp.buf.format({ async = true, name = "omnisharp" })
              end,
              desc = "Organize Imports",
            },
          },

          cmd = omnisharp_cmd(omnisharp_settings),
          -- Not read by OmniSharp (see omnisharp_cmd); kept so the settings show up in :LspInfo.
          settings = omnisharp_settings,
        },
      },
    },
  },

  -- neotest-vstest settings (read when the adapter is first required).
  {
    "Nsidorenco/neotest-vstest",
    init = function()
      vim.g.neotest_vstest = {
        dap_settings = { type = "netcoredbg" },
        -- Don't crawl large trees (e.g. ~/projects) when no parent solution is found.
        broad_recursive_discovery = false,
        -- Skip dot-dirs (.git, .claude worktrees holding full solution copies) and node_modules.
        discovery_directory_filter = function(path)
          return path:find("/%.") ~= nil or path:find("/node_modules", 1, true) ~= nil
        end,
      }
    end,
  },
}
