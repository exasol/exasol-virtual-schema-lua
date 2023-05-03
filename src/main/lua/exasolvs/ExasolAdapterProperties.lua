--- This class abstracts access to the user-defined properties of the Virtual Schema.
-- @classmod ExasolAdapterProperties
local ExasolAdapterProperties = {}
ExasolAdapterProperties.__index = ExasolAdapterProperties
local ExasolBaseAdapterProperties = require("exasol.evscl.ExasolBaseAdapterProperties")
setmetatable(ExasolAdapterProperties, ExasolBaseAdapterProperties)

local ExaError = require("ExaError")

--- Create a new `ExasolAdapterProperties` instance
-- @param raw_properties unparsed user-defined properties
-- @return new instance
function ExasolAdapterProperties:new(raw_properties)
    local instance = setmetatable({}, self)
    instance:_init(raw_properties)
    return instance
end

function ExasolAdapterProperties:_init(raw_properties)
    ExasolBaseAdapterProperties._init(self, raw_properties)
end

--- Get the class of the object
-- @return class
function ExasolAdapterProperties:class()
    return ExasolAdapterProperties
end

local CONNECTION_NAME_PROPERTY <const> = "CONNECTION_NAME"
local EXA_CONNECTION_PROPERTY <const> = "EXA_CONNECTION"

--- Validate the adapter properties.
-- @raise validation error
function ExasolAdapterProperties:validate()
    ExasolBaseAdapterProperties.validate(self) -- super call
    if self:has_value(CONNECTION_NAME_PROPERTY) and self:has_value(EXA_CONNECTION_PROPERTY) then
        ExaError:new("F-RLS-PROP-3", "Properties '" .. CONNECTION_NAME_PROPERTY .. "' and '" .. EXA_CONNECTION_PROPERTY
                .. "' cannot be used in combination.")
                :add_mitigations("Use only the '" .. CONNECTION_NAME_PROPERTY .. ' property.')
                :raise(0)
    end
end

-- The EXA_CONNECTION property is deprecated, but still supported for backward-compatibility
function ExasolAdapterProperties:_get_exa_connection()
    return self:get(EXA_CONNECTION_PROPERTY)
end

--- Get the name of the database object that defines the parameter of the connection to the remote data source.
-- @return name of the connection object
function ExasolAdapterProperties:get_connection_name()
    return self:get(CONNECTION_NAME_PROPERTY) or self:_get_exa_connection()
end

function ExasolAdapterProperties:__tostring()
    return ExasolBaseAdapterProperties.__tostring(self)
end

return ExasolAdapterProperties