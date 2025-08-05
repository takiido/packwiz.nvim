local M = {}

function M.create_window(content, active)
    local buf = vim.api.nvim_create_buf(false, true)

    local totalPlugins = #content
    local totalActivePlugins = #active

    table.insert(content, 1, "Loaded plugins:")
    table.insert(content, 2, string.format("   Total plugins: %s (%s active)", totalPlugins, totalActivePlugins))
    table.insert(content, 3, "")

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

    local width = vim.o.columns - 8
    local height = vim.o.lines - 12
    local ui = vim.api.nvim_list_uis()[1]
    local row = math.floor((ui.height - height) / 2)
    local col = math.floor((ui.width - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = "Packwiz",
    })

    return buf, win
end

return M
