local M = {}

function M.get_plugins(active_only)
    local raw_data = vim.pack.get()
    local result = {}

    for _, plugin in ipairs(raw_data) do
        local plugin_str = format_plugin_str(plugin)
        if active_only then
            if plugin.active then
                table.insert(result, plugin_str)
            end
        else
            table.insert(result, plugin_str)
        end
    end

    return result
end

function format_plugin_str(plugin)
    return string.format(
        "   %s %s  -  [%s]",
        plugin.active and "■" or "□",
        plugin.spec.name or "unknown",
        plugin.spec.src
    )
end

return M
