-- return {
-- 	{
-- 		"LazyVim/LazyVim",
-- 		opts = {
-- 			colorscheme = "catppuccin",
-- 		},
-- 	},
-- }

return {
{
    -- Let LazyVim apply the colorscheme (otherwise it loads tokyonight first).
    "LazyVim/LazyVim",
    opts = {
        colorscheme = "vague",
    },
},
{
    "vague-theme/vague.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other plugins
    config = function()
        require("vague").setup({
            transparent = false,
            colors = {
                bg = "#000000",
            },
        })

        -- Force pure black bg while preserving fg from the colorscheme.
        -- nvim_set_hl REPLACES the highlight, so naively passing { bg = ... }
        -- wipes Normal.fg and breaks plugins that read it (snacks, etc.).
        local function override_bg()
            for _, group in ipairs({ "Normal", "NormalFloat", "NormalNC", "SignColumn" }) do
                local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
                hl.bg = "#000000"
                vim.api.nvim_set_hl(0, group, hl)
            end
        end
        override_bg()
        vim.api.nvim_create_autocmd("ColorScheme", { callback = override_bg })
    end
},
}
