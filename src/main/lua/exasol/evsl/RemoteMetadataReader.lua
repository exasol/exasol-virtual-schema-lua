--- This class reads schema, table and column metadata from a schema on a remote Exasol database.
-- @classmod RemoteMetadataReader
local RemoteMetadataReader = {}
RemoteMetadataReader.__index = RemoteMetadataReader
local AbstractMetadataReader = require("exasol.evscl.AbstractMetadataReader")
setmetatable(RemoteMetadataReader, {__index = AbstractMetadataReader})

local ExaError = require("ExaError")
local ConnectionReader = require("exasol.evsl.ConnectionReader")
local driver = require("luasql.exasol")
local log = require("remotelog")

local TLS_PROPERTIES <const> = {tls_verify = "none", tls_protocol = "tlsv1_3"}

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

--- Get the metadata reader type
-- @return always 'REMOTE'
function AbstractMetadataReader:_get_type()
    return "REMOTE"
end

function RemoteMetadataReader:_read_connection_definition_from_context()
    local connection_reader = ConnectionReader:new(self._exasol_context)
    return connection_reader:read(self._connection_id)
end

-- [impl -> dsn~tls-connection~0]
function RemoteMetadataReader:_get_connection()
    if not self._connection then
        local connection_definition = self:_read_connection_definition_from_context()
        self._environment = driver.exasol()
        local address = connection_definition.host .. ":" .. connection_definition.port
        local connection, err = self._environment:connect(address, connection_definition.user,
                connection_definition.password, TLS_PROPERTIES)
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
        return false, tostring(ExaError
                :new("E-EVSL-RMR-2", "Unable to read column metadata from the remote data source: '{{cause}}'",
                        {cause = {value = err, description = "The error that prevented reading the column metadata"}}))
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
        return false, tostring(ExaError
                :new("E-EVSL-RMR-3", "Unable to read table metadata from the remote data source: '{{cause}}'",
                    {cause = {value = err, description = "The error that prevented reading the table metadata"}}))
    else
        local rows = fetch_all_rows(cursor)
        cursor:close()
        log.debug("Found " .. #rows .. " tables in schema '" .. schema_id .."'")
        return true, rows
    end
end

return RemoteMetadataReader