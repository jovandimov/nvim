-- Vitest test runner integration for neotest
return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            "marilari88/neotest-vitest",
        },
        opts = {
            adapters = {
                ["neotest-vitest"] = {
                    -- Skip dependencies, dot-dirs (e.g. .claude worktrees) and Playwright e2e specs,
                    -- which are named *.e2e.test.ts and would otherwise be picked up as Vitest tests.
                    filter_dir = function(name)
                        return name ~= "node_modules" and name ~= "e2e" and not vim.startswith(name, ".")
                    end,
                },
            },
        },
    },
}
