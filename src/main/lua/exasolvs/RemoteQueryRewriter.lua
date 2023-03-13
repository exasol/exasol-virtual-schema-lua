local AbstractQueryRewriter = require("exasolvs.AbstractQueryRewriter")
local QueryRenderer = require("exasolvs.QueryRenderer")
local ImportBuilder = require("exasolvs.ImportBuilder")

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

function RemoteQueryRewriter:_wrap_in_import(query)
    return ImportBuilder:new("EXA")
        :statement(query)
        :connection(self._connection_id)
        :build()
end

-- Override
function RemoteQueryRewriter:rewrite(original_query, source_schema_id, _, _)
    self:_validate(original_query)
    local query = self:_extend_query_with_source_schema(original_query, source_schema_id)
    self:_expand_select_list(query)
    local renderer = QueryRenderer:new(query)
    local remote_query = renderer:render()
    return self:_wrap_in_import(remote_query)
end

return RemoteQueryRewriter