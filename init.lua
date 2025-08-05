vim.api.nvim_create_user_command("PackwizWin", function()
    local content = require("packwiz.plugins").get_plugins(false)
    local active = require("packwiz.plugins").get_plugins(true)
    local config = require("packwiz.utils").scan_config_for_pack_add(vim.fn.stdpath("config"))

    require("packwiz.ui").open_plugin_window()
end, {})
