local AbstractQueryRewriter = require("exasolvs.AbstractQueryRewriter")
local QueryRenderer = require("exasolvs.QueryRenderer")
local ImportQueryBuilder = require("exasolvs.ImportQueryBuilder")

--- This class rewrites the query.
-- @classmod RemoteQueryRewriter
local RemoteQueryRewriter = {_NAME = "RemoteQueryRewriter"}
RemoteQueryRewriter.__index = RemoteQueryRewriter
setmetatable(RemoteQueryRewriter, {__index = AbstractQueryRewriter})

--- Create a new instance of a `RemoteQueryRewriter`.
-- @param connection_id ID of the connection object that defines the details of the connection to the remote Exasol
-- @return new instance
function RemoteQueryRewriter:new(connection_id)
    local instance = setmetatable({}, self)
    instance:_init(connection_id)
    return instance
end

function RemoteQueryRewriter:_init(connection_id)
    AbstractQueryRewriter:_init(self)
    self._connection_id = connection_id
end

--- Get a the class of the object.
-- @return class
function RemoteQueryRewriter:class()
    return RemoteQueryRewriter
end

function RemoteQueryRewriter:_create_import(original_query, source_schema_id)
    local remote_query = self:_extend_query_with_source_schema(original_query, source_schema_id)
    self:_expand_select_list(remote_query)
    local import_query = ImportQueryBuilder:new()
            :connection(self._connection_id)
            :column_types(original_query.selectListDataTypes)
            :statement(remote_query)
            :build()
    local renderer = QueryRenderer:new(import_query)
    return renderer:render()
end

-- Override
function RemoteQueryRewriter:rewrite(original_query, source_schema_id, _, _)
    self:_validate(original_query)
    return self:_create_import(original_query, source_schema_id)
end

return RemoteQueryRewriter