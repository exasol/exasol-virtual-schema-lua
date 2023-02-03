local log = require("remotelog")

--- This class reads details of a named connection database object from Exasol's Lua script context.
-- @classmod ConnectionDefinitionReader
local ConnectionReader = {};
ConnectionReader.__index = ConnectionReader;

local EXASOL_DEFAULT_PORT <const> = 8563

--- Create a new `ConnectionDefinitionReader`.
-- @param exasol_context handle to local database functions and status
-- @return connection definition reader
function ConnectionReader:new(exasol_context)
    local instance = setmetatable({}, self)
    instance:_init(exasol_context)
    return instance
end

function ConnectionReader:_init(exasol_context)
    self._exasol_context = exasol_context
end


local function split_connection_address(address)
    local colon_location = string.find(address, ":", 1, true)
    if colon_location then
        local host = string.sub(address, 1, colon_location - 1)
        local port = string.sub(address, colon_location + 1)
        return host, port
    else
        return address, EXASOL_DEFAULT_PORT
    end
end

--- Read the details for the connection object with the given ID
-- @param connection_id name of the connection to be read
-- @return table with connection details: `host`, `port`, `user`, `password`
function ConnectionReader:read(connection_id)
    local connection_details = self._exasol_context.get_connection(connection_id)
    local host, port = split_connection_address(connection_details.address)
    local user = connection_details.user
    local password = connection_details.password
    log.debug("Retrieved connection details for '" .. connection_id .. "' from Exasol script context: " .. host
            .. " on port " .. port .. " with user " .. user)
    return {host = host, port = tonumber(port), user = user, password = password}
end

return ConnectionReader;