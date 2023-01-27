--- This class abstracts access to the user-defined properties of the Virtual Schema.
-- @classmod ExasolAdapterProperties

local text = require("text")
local ExaError = require("ExaError")
local AdapterProperties = require("exasolvs.AdapterProperties")

local ExasolAdapterProperties = {}
ExasolAdapterProperties.__index = ExasolAdapterProperties
setmetatable(ExasolAdapterProperties, AdapterProperties)

--- Create a new `ExasolAdapterProperties` instance
-- @param raw_properties unparsed user-defined properties
-- @return new instance
function ExasolAdapterProperties:new(raw_properties)
    local instance = setmetatable({}, self)
    instance:_init(raw_properties)
    return instance
end

function ExasolAdapterProperties:_init(raw_properties)
    AdapterProperties._init(self, raw_properties)
end

--- Get the class of the object
-- @return class
function ExasolAdapterProperties:class()
    return ExasolAdapterProperties
end

local SCHEMA_NAME_PROPERTY <const> = "SCHEMA_NAME"
local TABLE_FILTER_PROPERTY <const> = "TABLE_FILTER"
local CONNECTION_NAME_PROPERTY <const> = "CONNECTION_NAME"
local EXA_CONNECTION_PROPERTY <const> = "EXA_CONNECTION"

--- Validate the adapter properties.
-- @raise validation error
function ExasolAdapterProperties:validate()
    AdapterProperties.validate(self) -- super call
    if not self:has_value(SCHEMA_NAME_PROPERTY) then
        ExaError:new("F-RLS-PROP-1", "Missing mandatory property '" .. SCHEMA_NAME_PROPERTY .. "'.")
                :add_mitigations("Please define the name of the source schema."):raise(0)
    end
    if self:is_property_set(TABLE_FILTER_PROPERTY) and self:is_empty(TABLE_FILTER_PROPERTY) then
        ExaError:new("F-RLS-PROP-2", "Table filter property '" .. TABLE_FILTER_PROPERTY .. "' must not be empty.")
                :add_mitigations("Please either remove the property or provide a comma separated list of tables"
                .. " to be included in the Virtual Schema."):raise(0)
    end
    if self:has_value(CONNECTION_NAME_PROPERTY) and self:has_value(EXA_CONNECTION_PROPERTY) then
        ExaError:new("F-RLS-PROP-3", "Properties '" .. CONNECTION_NAME_PROPERTY .. "' and '" .. EXA_CONNECTION_PROPERTY
                .. "' cannot be used in combination.")
                :add_mitigations("Use only the '" .. CONNECTION_NAME_PROPERTY .. ' property.')
                :raise(0)
    end
end

--- Get the name of the Virtual Schema's source schema.
-- @return name of the source schema
function ExasolAdapterProperties:get_schema_name()
    return self:get(SCHEMA_NAME_PROPERTY)
end

--- Get the list of tables that the Virtual Schema should show after applying the table filter.
-- @return list of tables
function ExasolAdapterProperties:get_table_filter()
    local filtered_tables = self:get(TABLE_FILTER_PROPERTY)
    return text.split(filtered_tables)
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
    return AdapterProperties.__tostring(self)
end

return ExasolAdapterProperties