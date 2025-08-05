local M = {}

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

local function render_plugins(buf, plugins)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    local lines = {}
    for _, plugin in ipairs(plugins) do
        local symbol = plugin.disabled and "□" or "■"
        table.insert(lines, string.format("   %s %s  -  [%s]", symbol, plugin.name, plugin.src))
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
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

        local plugin_utils = require('packwiz.plugins')
        local config_utils = require('packwiz.utils')

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
    local plugin_utils = require('packwiz.plugins')
    local config_utils = require('packwiz.utils')

    local config_path = config_utils.scan_config_for_pack_add(vim.fn.stdpath("config"))
    if not config_path then
        vim.notify("No config file found with vim.pack.add", vim.log.levels.ERROR)
        return
    end

    local plugins = plugin_utils.get_plugins(config_path)
    render_plugins(buf, plugins)
end

function M.open_plugin_window()
    local plugin_utils = require('packwiz.plugins')
    local config_utils = require('packwiz.utils')

    local config_path = config_utils.scan_config_for_pack_add(vim.fn.stdpath("config"))
    if not config_path then
        vim.notify("No config file found with vim.pack.add", vim.log.levels.ERROR)
        return
    end

    local plugins = plugin_utils.get_plugins(false)

    local buf = create_buf()
    local _ = open_floating_window(buf)

    render_plugins(buf, plugins)
    setup_keymaps(buf)
end

return M
