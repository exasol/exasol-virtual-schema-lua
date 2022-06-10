local AbstractVirtualSchemaAdapter = require("exasolvs.AbstractVirtualSchemaAdapter")
local adapter_capabilities = require("exasolvs.adapter_capabilities")
local QueryRewriter = require("exasolvs.QueryRewriter")

--- Virtual Schema adapter for Exasol-to-Exasol Virtual Schemas.
-- @classmod ExasolAdapter
local ExasolAdapter = {}
ExasolAdapter.__index = ExasolAdapter
setmetatable(ExasolAdapter, {__index = AbstractVirtualSchemaAdapter})
local VERSION <const> = "0.1.0"

--- Create an `ExasolAdapter`.
-- @param metadata_reader metadata reader
-- @return new instance
function ExasolAdapter:new(metadata_reader)
    local instance = setmetatable({}, self)
    instance:_init(metadata_reader)
    return instance
end

function ExasolAdapter:_init(metadata_reader)
    AbstractVirtualSchemaAdapter._init(self)
    self._metadata_reader = metadata_reader
end

--- Get the version number of the Virtual Schema adapter.
-- @return Virtual Schema adapter version
function ExasolAdapter:get_version()
    return VERSION
end

--- Get the name of the Virtual Schema adapter.
-- @return Virtual Schema adapter name
function ExasolAdapter:get_name()
    return "Exasol Virtual Schema adapter (Lua)"
end

--- Create a virtual schema.
-- @param request virtual schema request
-- @param properties user-defined properties
-- @return response containing the metadata for the virtual schema like table and column structure
function ExasolAdapter:create_virtual_schema(request, properties)
    properties:validate()
    local metadata = self:_handle_schema_scanning_request(request, properties)
    return {type = "createVirtualSchema", schemaMetadata = metadata}
end

function ExasolAdapter:_handle_schema_scanning_request(_, properties)
    local schema_name = properties:get_schema_name()
    local table_filter = properties:get_table_filter()
    return self._metadata_reader:read(schema_name, table_filter)
end

--- Refresh the metadata of the Virtual Schema.
-- Re-reads the structure and data types of the schema protected by RLS.
-- @param request virtual schema request
-- @param properties user-defined properties
-- @return response containing the metadata for the virtual schema like table and column structure
function ExasolAdapter:refresh(request, properties)
    properties:validate()
    return {type = "refresh", schemaMetadata = self:_handle_schema_scanning_request(request, properties)}
end

--- Alter the schema properties.
-- @param request virtual schema request
-- @param properties user-defined properties
-- @return response containing the metadata for the virtual schema like table and column structure
function ExasolAdapter:set_properties(request, properties)
    properties:validate()
    return {type = "setProperties", schemaMetadata = self:_handle_schema_scanning_request(request, properties)}
end

--- Rewrite a pushed down query.
-- @param request virtual schema request
-- @param properties user-defined properties
-- @return response containing the list of reported capabilities
function ExasolAdapter:push_down(request, properties)
    properties:validate()
    local adapter_cache = request.schemaMetadataInfo.adapterNotes
    local rewritten_query = QueryRewriter.rewrite(request.pushdownRequest, properties:get_schema_name(),
            adapter_cache, request.involvedTables)
    return {type = "pushdown", sql = rewritten_query}
end

function ExasolAdapter:_define_capabilities()
    return adapter_capabilities
end

return ExasolAdapter