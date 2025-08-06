local M = {}

local pack_file = nil

local function is_executable(cmd)
    return vim.fn.executable(cmd) == 1
end

local function find_pack_file_lua(path)
    path = vim.fs.normalize(path)
    local stat = vim.uv.fs_stat(path)
    if not (stat and stat.type == "directory") then return end

    for name, type in vim.fs.dir(path) do
        local full_path = path .. "/" .. name
        if type == "file" and name:match("%.lua$") then
            local file = io.open(full_path, "r")
            if file then
                for line in file:lines() do
                    if line:match("vim%.pack%.add%(") then
                        file:close()
                        return full_path
                    end
                end
                file:close()
            end
        elseif type == "directory" then
            local result = find_pack_file_lua(full_path)
            if result then return result end
        end
    end
end

local function find_pack_file_rg(path)
    if not is_executable("rg") then return end
    local rg_cmd = string.format(
        "rg --files-with-matches --type lua -e 'vim\\.pack\\.add\\(' %s -m 1",
        vim.fn.shellescape(path)
    )
    return vim.fn.systemlist(rg_cmd)[1]
end

local function find_pack_file_fzf(path)
    if not (is_executable("rg") and is_executable("fzf") and vim.fn.exists("*fzf#run")) then return end
    local rg_cmd = string.format(
        "rg --files-with-matches --type lua -e 'vim\\.pack\\.add\\(' %s",
        vim.fn.shellescape(path)
    )
    vim.fn["fzf#run"](vim.fn["fzf#wrap"]("packwiz-scan", {
        source = rg_cmd,
        options = {
            "--prompt", "Packwiz: Select file > ",
            "--preview", "bat --style=numbers --color=always {} || cat {}",
        },
    }))
end

M.init = function(config)
    if config.pack_file_path then
        pack_file = vim.fs.normalize(config.pack_file_path)
        return
    end

    local path = vim.fs.normalize(config.scan_path or vim.fn.stdpath("config"))
    if config.use_fzf and config.use_rg then
        pack_file = find_pack_file_fzf(path) or find_pack_file_rg(path) or find_pack_file_lua(path)
    elseif config.use_rg then
        pack_file = find_pack_file_rg(path) or find_pack_file_lua(path)
    else
        pack_file = find_pack_file_lua(path)
    end
end

M.get_pack_file = function()
    return pack_file
end

return M
