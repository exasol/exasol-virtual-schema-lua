local AbstractVirtualSchemaAdapter = require("exasolvs.AbstractVirtualSchemaAdapter")
local adapter_capabilities = require("exasolvs.adapter_capabilities")
local log = require("remotelog")

--- Virtual Schema adapter for Exasol-to-Exasol Virtual Schemas.
-- @classmod ExasolAdapter
local ExasolAdapter = {}
ExasolAdapter.__index = ExasolAdapter
setmetatable(ExasolAdapter, {__index = AbstractVirtualSchemaAdapter})
local VERSION <const> = "0.5.0"

--- Create an `ExasolAdapter`.
-- @param metadata_reader_factory factory for the metadata reader (e.g. local or remote)
-- @param query_rewriter_factory factory for the query rewriter (e.g. local or remote)
-- @return new instance
function ExasolAdapter:new(metadata_reader_factory, query_rewriter_factory)
    local instance = setmetatable({}, self)
    instance:_init(metadata_reader_factory, query_rewriter_factory)
    return instance
end

function ExasolAdapter:_init(metadata_reader_factory, query_rewriter_factory)
    AbstractVirtualSchemaAdapter._init(self)
    self._metadata_reader_factory = metadata_reader_factory
    self._query_rewriter_factory = query_rewriter_factory
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

-- @cover [impl -> dsn~creating-a-local-virtual-schema~0]
-- @cover [impl -> dsn~creating-a-remote-virtual-schema~0]
function ExasolAdapter:_handle_schema_scanning_request(_, properties)
    local schema_id = properties:get_schema_name()
    local table_filter = properties:get_table_filter()
    local connection_id = properties:get_connection_name()
    if connection_id == nil then
        log.debug("Creating a metadata reader that reads directly from the local database")
        local metadata_reader = self._metadata_reader_factory:create_local_reader()
        return metadata_reader:read(schema_id, table_filter)
    else
        log.debug("Creating a remote metadata reader for connection '%s'", connection_id)
        local metadata_reader = self._metadata_reader_factory:create_remote_reader(connection_id)
        return metadata_reader:read(schema_id, table_filter)
    end
end

--- Refresh the metadata of the Virtual Schema.
-- Re-reads the structure and data types of the schema protected by RLS.
-- @param request virtual schema request
-- @param properties user-defined properties
-- @return response containing the metadata for the virtual schema like table and column structure
-- @cover [impl -> dsn~refreshing-a-virtual-schema~0]
function ExasolAdapter:refresh(request, properties)
    properties:validate()
    return {type = "refresh", schemaMetadata = self:_handle_schema_scanning_request(request, properties)}
end

--- Alter the schema properties.
-- This request provides two sets of user-defined properties. The old ones (i.e. the ones that where set before this
-- request) and the properties that the user changed.
-- @param request virtual schema request
-- @param old_properties old user-defined properties
-- @param new_properties new user-defined properties
-- @return response containing the metadata for the virtual schema like table and column structure
-- @cover [impl -> dsn~setting-properties~0]
function ExasolAdapter:set_properties(request, old_properties, new_properties)
    log.debug("Old properties " .. tostring(old_properties))
    log.debug("New properties " .. tostring(new_properties))
    local merged_properties = old_properties:merge(new_properties)
    log.debug("Merged properties " .. tostring(merged_properties))
    merged_properties:validate()
    return {type = "setProperties", schemaMetadata = self:_handle_schema_scanning_request(request, merged_properties)}
end

--- Rewrite a pushed down query.
-- @param request virtual schema request
-- @param properties user-defined properties
-- @return response containing the list of reported capabilities
-- @cover [impl -> dsn~local-push-down~0]
-- @cover [impl -> dsn~remote-push-down~0]
function ExasolAdapter:push_down(request, properties)
    properties:validate()
    local adapter_cache = request.schemaMetadataInfo.adapterNotes
    local connection_id = properties:get_connection_name()
    local rewriter = self._query_rewriter_factory:create_rewriter(connection_id)
    local rewritten_query = rewriter:rewrite(request.pushdownRequest, properties:get_schema_name(),
            adapter_cache, request.involvedTables)
    return {type = "pushdown", sql = rewritten_query}
end

-- [impl -> dsn~getting-the-supported-capabilities~0]
function ExasolAdapter:_define_capabilities()
    return adapter_capabilities
end

return ExasolAdapter