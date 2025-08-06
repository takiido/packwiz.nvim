if vim.fn.has('nvim-0.12') == 0 then
    return
end

if vim.g.loaded_packwiz then
    return
end
vim.g.loaded_packwiz = 1

require("packwiz").setup()
