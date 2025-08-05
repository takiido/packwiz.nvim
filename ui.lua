local M = {}
local win_id = nil
local buf_id = nil
local width = vim.o.columns - 8
local height = vim.o.lines - 12

function M.create_window(config, content, active)
    buf_id = vim.api.nvim_create_buf(false, true)

    local totalPlugins = #content
    local totalActivePlugins = #active

    table.insert(content, 1, "Loaded plugins:")
    table.insert(content, 2, string.format("   Total plugins: %s (%s active)", totalPlugins, totalActivePlugins))
    table.insert(content, 3, "")
    table.insert(content, 4, config)
    table.insert(content, 5, "")

    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, content)


    local ui = vim.api.nvim_list_uis()[1]
    local row = math.floor((ui.height - height) / 2)
    local col = math.floor((ui.width - width) / 2)

    win_id = vim.api.nvim_open_win(buf_id, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = "Packwiz",
    })

    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            M.update_window()
        end,
    })
end

function M.update_window()
    if not vim.api.nvim_win_is_valid(win_id) then
        return
    end

    local ui = vim.api.nvim_list_uis()[1]
    local row = math.floor((ui.height - height) / 2)
    local col = math.floor((ui.width - width) / 2)

    vim.api.nvim_win_set_config(win_id, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
    })
end

return M
