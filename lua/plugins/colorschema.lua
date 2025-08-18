-- Function to set colorscheme with pure black background
local function ColorMyPencils(color)
  color = color or "tokyonight-night"
  vim.cmd.colorscheme(color)

  -- Set pure black background for Normal and NormalFloat
  vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#000000" })
end

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night", -- Darkest variant for pure black aesthetic
        transparent = false, -- Disable transparent background
        terminal_colors = true,
        styles = {
          comments = { italic = false }, -- Match your preference for non-italic comments
          keywords = { italic = false }, -- Match your preference for non-italic keywords
          functions = {},
          variables = {},
          sidebars = "dark",
          floats = "dark",
        },
        -- Enforce pure black background
        on_colors = function(colors)
          colors.bg = "#000000"
          colors.bg_dark = "#000000"
          colors.bg_float = "#000000"
          colors.bg_popup = "#000000"
          colors.bg_sidebar = "#000000"
          colors.bg_statusline = "#000000"
        end,
      })
      ColorMyPencils() -- Call your function to apply colorscheme and set black background
    end,
  },
}
