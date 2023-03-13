local validator = require("exasol.validator")
local log = require("remotelog")

--- This class reads details of a named connection database object from Exasol's Lua script context.
-- @classmod ConnectionReader
local ConnectionReader = {};
ConnectionReader.__index = ConnectionReader;

local EXASOL_DEFAULT_PORT <const> = 8563

--- Create a new `ConnectionReader`.
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
    local slash_location = string.find(address, "/", 1, true) or 0
    local colon_location = string.find(address, ":", slash_location + 1, true) or 0
    if slash_location > 0 then
        if  colon_location > slash_location then
            local host = string.sub(address, 1, slash_location - 1)
            local fingerprint = string.sub(address, slash_location + 1, colon_location - 1)
            local port = string.sub(address, colon_location + 1)
            validator.validate_port(port)
            return host, port, fingerprint
        else
            local host = string.sub(address, 1, slash_location - 1)
            local fingerprint = string.sub(address, slash_location + 1)
            return host, EXASOL_DEFAULT_PORT, fingerprint
        end
    else
        if colon_location > 0 then
            local host = string.sub(address, 1, colon_location - 1)
            local port = string.sub(address, colon_location + 1)
            validator.validate_port(port)
            return host, port, nil
        end
    else
        if slash_location > 0 then
            local host = string.sub(address, 1, slash_location - 1)
            local fingerprint = string.sub(address, slash_location + 1)
            return host, EXASOL_DEFAULT_PORT, fingerprint
        else
            local host = string.sub(address, 1, colon_location - 1)
            return host, EXASOL_DEFAULT_PORT, nil
        end
    end
end

--- Read the details for the connection object with the given ID
-- @param connection_id name of the connection to be read
-- @return table with connection details: `host`, `port`, `user`, `password`
-- [[impl -> dsn~defining-the-remote-connection~0]]
function ConnectionReader:read(connection_id)
    local connection_details = self._exasol_context.get_connection(connection_id)
    local host, port, fingerprint = split_connection_address(connection_details.address)
    local user = connection_details.user
    validator.validate_user(user)
    local password = connection_details.password
    log.debug("Retrieved connection details for '" .. connection_id .. "' from Exasol script context: " .. host
            .. " on port " .. port .. " with user " .. user)
    return {host = host, port = tonumber(port), user = user, password = password, fingerprint = fingerprint}
end

return ConnectionReader;