local M = {}

M.version = "0.0.1"

local default_config = {
    use_rg = false,
    use_fzf = false,
}

M.setup = function(user_config)
    local config = vim.tbl_deep_extend(
        "force", {
            scan_path = vim.fn.stdpath("config"),
            use_rg = false,
            use_fzf = false,
            pack_file_path = nil,
        },
        user_config or {}
    )

    require("packwiz.core").init(config)
    require("packwiz.scanner").init(config)
    require("packwiz.commands").init(config)
end

return M
