local AbstractMetadataReader = require("exasolvs.AbstractMetadataReader")
local ExaError = require("ExaError")
local driver = require("luasql.exasol")
local log = require("remotelog")

--- This class reads schema, table and column metadata from a schema on a remote Exasol database.
-- @classmod RemoteMetadataReader
local RemoteMetadataReader = {}
RemoteMetadataReader.__index = RemoteMetadataReader
setmetatable(RemoteMetadataReader, {__index = AbstractMetadataReader})

--- Create a new `RemoteMetadataReader`.
-- @param exasol_context handle to local database functions and status
-- @param connection_id name of the connection object that contains the details of the connection to the remote data
--                      source
-- @return metadata reader
function RemoteMetadataReader:new(exasol_context, connection_id)
    local instance = setmetatable({}, self)
    instance:_init(exasol_context, connection_id)
    return instance
end


function RemoteMetadataReader:_init(exasol_context, connection_id)
    AbstractMetadataReader._init(self, exasol_context)
    self._connection_id = connection_id
end

function RemoteMetadataReader:_read_connection_details_from_context()
    -- TODO: implement connection reader
    return "localhost", "8563", "sys", "exasol"
end

function RemoteMetadataReader:_get_connection()
    if not self._connection then
        local host, port, username, password = self:_read_connection_details_from_context()
        self._environment = driver.exasol()
        local connection, err = self._environment:connect(host .. ":" .. port, username, password)
        if err then
            ExaError:new("E-EVSL-RMR-1", "Unable to connect to remote data source: '{{cause}}'",
                    {cause = {value = err, description = "The error that caused the connection issue"}})
                    :raise(0)
        else
            self._connection = connection
        end
    end
    return self._connection
end

local function fetch_all_rows(cursor)
    local rows = {}
    local row = cursor:fetch({}, "a")
    while row do
        table.insert(rows, row)
        row = cursor:fetch({}, "a")
    end
    return rows
end

-- Override
function RemoteMetadataReader:_execute_column_metadata_query(schema_id, table_id)
    -- TODO: assert schema and table only contain valid characters.
    local sql = [[/*snapshot execution*/ SELECT "COLUMN_NAME", "COLUMN_TYPE" FROM "SYS"."EXA_ALL_COLUMNS"]]
            .. [[ WHERE "COLUMN_SCHEMA" = ']] .. schema_id .. [[' AND "COLUMN_TABLE" = ']] .. table_id
            .. [[' ORDER BY "COLUMN_ORDINAL_POSITION"]]
    local cursor, err = self:_get_connection():execute(sql)
    if err then
        ExaError:new("E-EVSL-RMR-2", "Unable to read column metadata from the remote data source: '{{cause}}'",
                {cause = {value = err, description = "The error that prevented reading the column metadata"}})
                :raise(0)
    else
        local rows = fetch_all_rows(cursor)
        cursor:close()
        log.debug("Found " .. #rows .. " columns in table '" .. table_id .. "'")
        return true, rows
    end
end

-- Override
function RemoteMetadataReader:_execute_table_metadata_query(schema_id)
    local sql = [[/*snapshot execution*/ SELECT "TABLE_NAME" FROM "SYS"."EXA_ALL_TABLES" WHERE "TABLE_SCHEMA" = ']]
            .. schema_id .. [[']]
    local cursor, err = self:_get_connection():execute(sql)
    if err then
        ExaError:new("E-EVSL-RMR-3", "Unable to read table metadata from the remote data source: '{{cause}}'",
                {cause = {value = err, description = "The error that prevented reading the table metadata"}})
                :raise(0)
    else
        local rows = fetch_all_rows(cursor)
        cursor:close()
        log.debug("Found " .. #rows .. " tables in schema '" .. schema_id .."'")
        return true, rows
    end
end

return RemoteMetadataReader