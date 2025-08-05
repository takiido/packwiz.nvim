vim.api.nvim_create_user_command("PackwizWin", function()
    _G.needs_restart = false
    require("packwiz.ui").open_plugin_window()
end, {})
