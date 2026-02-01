-- Show npm package versions in package.json
return {
  {
    "vuki656/package-info.nvim",
    dependencies = "MunifTanjim/nui.nvim",
    ft = "json",
    opts = {
      hide_up_to_date = true, -- Only show outdated packages
    },
    keys = {
      { "<leader>cpt", function() require("package-info").toggle() end, desc = "Toggle package versions" },
      { "<leader>cpu", function() require("package-info").update() end, desc = "Update package" },
      { "<leader>cpd", function() require("package-info").delete() end, desc = "Delete package" },
      { "<leader>cpc", function() require("package-info").change_version() end, desc = "Change version" },
    },
  },
}
