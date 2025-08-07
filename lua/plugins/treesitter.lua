return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")
      configs.setup({
        modules = {}, -- you can leave this empty unless you use TS playground, textobjects, etc.
        sync_install = false, -- install languages synchronously (only really needed on CI)
        ignore_install = {}, -- list of parsers to ignore installing
        ensure_installed = {
          "javascript",
          "typescript",
          "c",
          "c_sharp",
          "lua",
          "cpp",
          "rust",
          "bash",
          "go",
        },
        auto_install = true, -- install missing parsers automatically when entering buffer
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      })
    end,

    -- {
    --   "nvim-treesitter/nvim-treesitter-context",
    --   after = "nvim-treesitter",
    --   config = function()
    --     require("treesitter-context").setup({
    --       enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    --       multiwindow = false, -- Enable multiwindow support.
    --       max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    --       min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
    --       line_numbers = true,
    --       multiline_threshold = 20, -- Maximum number of lines to show for a single context
    --       trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    --       mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
    --       -- Separator between context and content. Should be a single character string, like '-'.
    --       -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
    --       separator = nil,
    --       zindex = 20, -- The Z-index of the context window
    --       on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
    --     })
    --   end,
    -- },
  },
}
