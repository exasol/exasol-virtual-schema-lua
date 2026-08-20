---@meta exasol_udf_context
local M = {}

---Context for Exasol Lua UDFs.
---@class ExasolUdfContext
M.ExasolUdfContext = {}

---Get the connection details for the named connection.
---@param connection_name string The name of the connection.
---@return Connection? connection connection details.
function M.ExasolUdfContext.get_connection(connection_name)
end

---An Exasol connection object
---@class Connection
---@field address string? The address of the connection.
---@field user string? The user name for the connection.
---@field password string? The password for the connection.
M.Connection = {}

return M
