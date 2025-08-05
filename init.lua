vim.api.nvim_create_user_command("PackwizWin", function()
    require("packwiz.ui").create_window()
end, {})
