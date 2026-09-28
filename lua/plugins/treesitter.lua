return {
    -- Parsers beyond LazyVim's defaults and language extras (c_sharp, go, typescript, ... are already covered)
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                "proto", -- gRPC contracts in Sharecat
            },
        },
    },
}
