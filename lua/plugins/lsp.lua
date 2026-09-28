return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                ["*"] = {
                    keys = {
                        -- Keep <leader>cc as "Close window" (lua/config/keymaps.lua) in LSP buffers too,
                        -- instead of LazyVim's buffer-local "Run Codelens". <leader>cC still refreshes codelens.
                        { "<leader>cc", false, mode = { "n", "x" } },
                    },
                },
            },
        },
    },
}
