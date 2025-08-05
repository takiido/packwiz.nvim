local M = {}

function M.get_plugins(active_only)
    local raw_data = vim.pack.get()
    local result = {}

    for _, plugin in ipairs(raw_data) do
        if not active_only or plugin.active then
            local name = plugin.path:match("([^/\\]+)$") or "unknown"

            local plugin_entry = {
                name = name,
                src = plugin.spec.src or plugin.url or "unknown",
                disabled = not plugin.active,
            }

            table.insert(result, plugin_entry)
        end
    end

    return result
end

local function read_lines(path)
    local file = io.open(path, "r")
    if not file then return nil, "Failed to open file" end

    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()
    return lines
end

local function write_lines(path, lines)
    local file = io.open(path, "w")
    if not file then return false, "Failed to write file" end

    for _, line in ipairs(lines) do
        file:write(line .. "\n")
    end
    file:close()
    return true
end

function M.toggle_plugin(path, plugin_src)
    local lines, err = read_lines(path)
    if not lines then return false, err end

    local function escape_pattern(s)
        return (s:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1"))
    end

    local escaped_src = escape_pattern(plugin_src)
    local pattern = 'src%s*=%s*"?' .. escaped_src .. '"?'

    local modified = false
    for i, line in ipairs(lines) do
        if line:match(pattern) then
            if line:match("^%s*%-%-") then
                lines[i] = line:gsub("^(%s*)%-%-%s*", "%1")
            else
                lines[i] = line:gsub("^(%s*)", "%1-- ")
            end
            modified = true
            break
        end
    end

    if not modified then
        return false, "No matching src line found for: " .. plugin_src
    end

    local ok, write_err = write_lines(path, lines)
    if not ok then
        return false, write_err
    end

    -- vim.cmd("source " .. path)

    return true
end

return M
