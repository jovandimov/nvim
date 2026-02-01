-- Jest test runner integration for neotest
return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-jest",
    },
    opts = {
      adapters = {
        ["neotest-jest"] = {
          jestCommand = "npm test --",
          jestConfigFile = "jest.config.ts",
          cwd = function()
            return vim.fn.getcwd()
          end,
        },
      },
    },
  },
}
