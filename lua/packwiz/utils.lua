local uv = vim.loop
local M = {}

local function scan_dir_for_pack_add(path)
    local handle = uv.fs_scandir(path)
    if not handle then return end

    while true do
        local name, typ = uv.fs_scandir_next(handle)
        if not name then break end

        local full_path = path .. '/' .. name
        if typ == 'file' and name:match("%.lua$") then
            local file = io.open(full_path, "r")
            local content = file:read("*a")
            file:close()
            if content:match("vim%.pack%.add%(") then
                return full_path
            end
        elseif typ == 'directory' then
            local result = scan_dir_for_pack_add(full_path)
            if result then return result end
        end
    end

    return nil
end

function M.scan_config_for_pack_add(path)
    return scan_dir_for_pack_add(path)
end

return M
