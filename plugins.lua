local M = {}

function M.get_plugins(active_only)
    local raw_data = vim.pack.get()
    local result = {}

    for _, plugin in ipairs(raw_data) do
        if active_only then
            if plugin.active then
                table.insert(
                    result,
                    string.format(
                        "   ■ %s  -  [%s]",
                        plugin.spec.name or "unknown",
                        plugin.spec.src
                    )
                )
            end
        else
            table.insert(
                result,
                string.format(
                    "   %s %s  -  [%s]",
                    plugin.active and "■" or "□",
                    plugin.spec.name or "unknown",
                    plugin.spec.src
                )
            )
        end
    end

    return result
end

return M
