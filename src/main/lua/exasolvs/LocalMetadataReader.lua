local AbstractMetadataReader = require("exasolvs.AbstractMetadataReader")

--- This class reads schema, table and column metadata from the source.
-- @classmod LocalMetadataReader
local LocalMetadataReader = {}
LocalMetadataReader.__index = LocalMetadataReader
setmetatable(LocalMetadataReader, {__index = AbstractMetadataReader})

--- Create a new `MetadataReader`.
-- @param exasol_context handle to local database functions and status
-- @return metadata reader
function LocalMetadataReader:new(exasol_context)
    assert(exasol_context ~= nil,
            "The metadata reader requires an Exasol context handle in order to read metadata from the database")
    local instance = setmetatable({}, self)
    instance:_init(exasol_context)
    return instance
end

function LocalMetadataReader:_init(exasol_context)
    AbstractMetadataReader._init(self)
    self._exasol_context = exasol_context
end

-- Override
function LocalMetadataReader:_execute_column_metadata_query(schema_id, table_id)
    local sql = '/*snapshot execution*/ SELECT "COLUMN_NAME", "COLUMN_TYPE" FROM "SYS"."EXA_ALL_COLUMNS"'
            .. ' WHERE "COLUMN_SCHEMA" = :s AND "COLUMN_TABLE" = :t'
    return self._exasol_context.pquery_no_preprocessing(sql, {s = schema_id, t = table_id})
end

-- Override
function LocalMetadataReader:_execute_table_metadata_query(schema_id)
    local sql = '/*snapshot execution*/ SELECT "TABLE_NAME" FROM "SYS"."EXA_ALL_TABLES" WHERE "TABLE_SCHEMA" = :s'
    return self._exasol_context.pquery_no_preprocessing(sql, {s = schema_id})
end

return LocalMetadataReader