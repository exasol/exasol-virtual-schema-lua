--- This class rewrites the query.
-- @classmod RemoteQueryRewriter
local RemoteQueryRewriter = {_NAME = "RemoteQueryRewriter"}
RemoteQueryRewriter.__index = RemoteQueryRewriter
local AbstractQueryRewriter = require("exasol.evscl.AbstractQueryRewriter")
setmetatable(RemoteQueryRewriter, {__index = AbstractQueryRewriter})

local QueryRenderer = require("exasol.vscl.QueryRenderer")
local ImportQueryBuilder = require("exasol.vscl.ImportQueryBuilder")
local AbstractQueryAppender = require("exasol.vscl.queryrenderer.AbstractQueryAppender")

--- Create a new instance of a `RemoteQueryRewriter`.
-- @param connection_id ID of the connection object that defines the details of the connection to the remote Exasol
-- @return new instance
function RemoteQueryRewriter:new(connection_id)
    local instance = setmetatable({}, self)
    instance:_init(connection_id)
    return instance
end

function RemoteQueryRewriter:_init(connection_id)
    AbstractQueryRewriter:_init()
    self._connection_id = connection_id
end

--- Get a the class of the object.
-- @return class
function RemoteQueryRewriter:class()
    return RemoteQueryRewriter
end

--- Cast literal NULL to the expected type on top level.
--
-- The IMPORT statement does not accept untyped null on top level, so we add a CAST around NULL using the information
-- from the select list data type structure.
--
-- @param query input query
-- @param select_list_data_types type the Exasol database expects to see in the rewritten push-down query
-- [impl -> dsn~evsl.casting-a-typed-null-literal-for-remote-import~0]
local function cast_top_level_null_literals(query, select_list_data_types)
    if query.selectList and select_list_data_types then
        for index, expression in ipairs(query.selectList) do
            local data_type = select_list_data_types[index]
            if expression.type == "literal_null" and data_type then
                query.selectList[index] = {
                    type = "function_scalar_cast",
                    name = "CAST",
                    arguments = {expression},
                    dataType = data_type
                }
            end
        end
    end
end

function RemoteQueryRewriter:_create_import(original_query, source_schema_id)
    local remote_query = self:_extend_query_with_source_schema(original_query, source_schema_id)
    self:_expand_select_list(remote_query)
    cast_top_level_null_literals(remote_query, original_query.selectListDataTypes)
    local import_query = ImportQueryBuilder:new()
            :connection(self._connection_id)
            :column_types(original_query.selectListDataTypes)
            :statement(remote_query)
            :build()
    local renderer = QueryRenderer:new(import_query, AbstractQueryAppender.DEFAULT_APPENDER_CONFIG)
    return renderer:render()
end

-- Override
function RemoteQueryRewriter:rewrite(original_query, source_schema_id, _, _)
    self:_validate(original_query)
    return self:_create_import(original_query, source_schema_id)
end

return RemoteQueryRewriter
