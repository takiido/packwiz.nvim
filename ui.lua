local M = {}

function M.create_window()
    local buf = vim.api.nvim_create_buf(false, true)

    local content = vim.pack.get()

    local lines = vim.split(vim.inspect(content), "\n", { trimempty = true })

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

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
