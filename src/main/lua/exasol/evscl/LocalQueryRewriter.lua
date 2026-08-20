--- This class rewrites the query for the local database.
-- @classmod LocalQueryRewriter
local LocalQueryRewriter = {_NAME = "LocalQueryRewriter"}
LocalQueryRewriter.__index = LocalQueryRewriter
local AbstractQueryRewriter = require("exasol.evscl.AbstractQueryRewriter")
setmetatable(LocalQueryRewriter, {__index = AbstractQueryRewriter})

local QueryRenderer = require("exasol.vscl.QueryRenderer")

--- Create a new instance of a `LocalQueryRewriter`.
-- @return new instance
function LocalQueryRewriter:new()
    local instance = setmetatable({}, self)
    instance:_init()
    return instance
end

function LocalQueryRewriter:_init()
    AbstractQueryRewriter:_init(self)
end

--- Get a the class of the object.
-- @return class
function LocalQueryRewriter:class()
    return LocalQueryRewriter
end

-- Override
-- [impl -> dsn~rewriting-a-query-for-local-access~0]
function LocalQueryRewriter:rewrite(original_query, source_schema_id, _, _)
    self:_validate(original_query)
    local query = self:_extend_query_with_source_schema(original_query, source_schema_id)
    self:_expand_select_list(query)
    local renderer = QueryRenderer:new(query, {})
    return renderer:render()
end

return LocalQueryRewriter