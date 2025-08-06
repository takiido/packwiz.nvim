local M = {}
local config = require('packwiz.config')
local plugin_utils = require('packwiz.plugins')
local config_utils = require('packwiz.utils')

vim.api.nvim_set_hl(0, "PackwizRestartLine", {
    fg = "#FFFF00",
    bold = true,
    italic = true,
})


local total_plugins_cnt = 0
local active_plugins_cnt = 0

local function create_buf()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'packwiz_plugins')
    return buf
end

local function open_floating_window(buf)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
    })

    vim.api.nvim_win_set_option(win, 'wrap', false)
    vim.api.nvim_win_set_option(win, 'cursorline', true)

    return win
end

local function render_header(lines)
    local notification_line_i = nil
    local notification_line = _G.needs_restart and "Restart nvim to apply changes" or ""

    local header_lines = {
        string.format("Loaded plugins: %s (active %s)", total_plugins_cnt, active_plugins_cnt),
    }

    if notification_line ~= "" then
        notification_line_i = #header_lines
        table.insert(header_lines, notification_line)
        table.insert(header_lines, "")
    end

    for i, line in ipairs(header_lines) do
        table.insert(lines, i, line)
    end

    return notification_line_i
end


local function render_plugins(buf, plugins)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    local lines = {}
    for _, plugin in ipairs(plugins) do
        local symbol = plugin.disabled and "□" or "■"
        total_plugins_cnt = total_plugins_cnt + 1
        if not plugin.disabled then active_plugins_cnt = active_plugins_cnt + 1 end
        table.insert(lines, string.format("   %s %s  -  [%s]", symbol, plugin.name, plugin.src))
    end

    local notification_line_i = render_header(lines)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    if notification_line_i then
        local ns = vim.api.nvim_create_namespace("packwiz_restart_highlight")
        vim.api.nvim_buf_add_highlight(buf, ns, "PackwizRestartLine", notification_line_i, 0, -1)
    end
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function setup_keymaps(buf)
    vim.keymap.set('n', 'q', '<cmd>bd!<CR>', { buffer = buf, nowait = true, silent = true })

    vim.keymap.set('n', 'x', function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local line = vim.api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1]
        if not line then return end

        local plugin_src = line:match("%[(.-)%]")
        if not plugin_src then return end

        local config_path = config_utils.scan_config_for_pack_add(vim.fn.stdpath("config"))
        if not config_path then
            vim.notify("No config file found with vim.pack.add", vim.log.levels.ERROR)
            return
        end

        local ok, err = plugin_utils.toggle_plugin(config_path, plugin_src)
        if ok then
            vim.notify("Toggled: " .. plugin_src)
            M.refresh(buf)
        else
            vim.notify("Toggle failed: " .. err, vim.log.levels.ERROR)
        end
    end, { buffer = buf, nowait = true, silent = true })
end

function M.refresh(buf)
    local config_path = config_utils.scan_config_for_pack_add(vim.fn.stdpath("config"))
    if not config_path then
        vim.notify("No config file found with vim.pack.add", vim.log.levels.ERROR)
        return
    end

    local plugins = plugin_utils.get_plugins(false)
    render_plugins(buf, plugins)
end

local function fzf_select(plugins)
    local has_fzf, fzf = pcall(require, "fzf-lua")
    if not has_fzf then
        vim.notify("fzf-lua not found, fallback to default UI", vim.log.levels.WARN)
        return false
    end

    local choices = {}
    for _, p in ipairs(plugins) do
        table.insert(choices, (p.disabled and "□ " or "■ ") .. p.name .. "  [" .. p.src .. "]")
    end

    fzf.fzf_exec(choices, {
        prompt = "Plugins> ",
        actions = {
            ["default"] = function(selected)
                local line = selected[1]
                local plugin_src = line:match("%[(.-)%]")
                if not plugin_src then return end

                local config_path = config_utils.scan_config_for_pack_add(vim.fn.stdpath("config"))
                if not config_path then
                    vim.notify("No config file found with vim.pack.add", vim.log.levels.ERROR)
                    return
                end

                local ok, err = plugin_utils.toggle_plugin(config_path, plugin_src)
                if ok then
                    vim.notify("Toggled: " .. plugin_src)
                else
                    vim.notify("Toggle failed: " .. err, vim.log.levels.ERROR)
                end
            end,
        },
    })

    return true
end

local function get_plugin_files_with_rg()
    local config_path = vim.fn.stdpath("config")
    local rg_cmd = { "rg", "--files-with-matches", "vim.pack.add", config_path }
    local result = vim.fn.systemlist(rg_cmd)

    if vim.v.shell_error ~= 0 then
        vim.notify("rg command failed or not found", vim.log.levels.ERROR)
        return nil
    end

    return result
end

function M.open_plugin_window()
    local plugins

    if config.use_rg then
        local files = get_plugin_files_with_rg()
        if files and #files > 0 then
            plugins = plugin_utils.get_plugins(false)
        else
            vim.notify("No plugin config files found with ripgrep. Using default plugin list.", vim.log.levels.WARN)
            plugins = plugin_utils.get_plugins(false)
        end
    else
        plugins = plugin_utils.get_plugins(false)
    end

    if config.use_fzf then
        if not fzf_select(plugins) then
            local buf = create_buf()
            open_floating_window(buf)
            render_plugins(buf, plugins)
            setup_keymaps(buf)
        end
    else
        local buf = create_buf()
        open_floating_window(buf)
        render_plugins(buf, plugins)
        setup_keymaps(buf)
    end
end

return M
