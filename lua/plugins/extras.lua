return {
  -- TypeScript support (vtsls LSP, icons, debugging)
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- ESLint integration with auto-fix
  { import = "lazyvim.plugins.extras.linting.eslint" },

  -- .NET support (adds csharpier formatter, netcoredbg debugger, neotest adapter)
  -- Note: OmniSharp is disabled in roslyn.lua since we use Roslyn LSP instead
  { import = "lazyvim.plugins.extras.lang.dotnet" },

  -- Debugging support (nvim-dap core)
  { import = "lazyvim.plugins.extras.dap.core" },

  -- Testing support (neotest core)
  { import = "lazyvim.plugins.extras.test.core" },

  -- JSON support (useful for package.json, tsconfig.json)
  { import = "lazyvim.plugins.extras.lang.json" },
}
