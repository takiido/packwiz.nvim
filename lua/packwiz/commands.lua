local M = {}

function M.init(config)
    vim.api.nvim_create_user_command("Packwiz", function()
        print("Packwiz: commands")
        -- require("packwiz.ui").open_plugin_window()
    end, { desc = "Open packwiz main window" })
end

return M
