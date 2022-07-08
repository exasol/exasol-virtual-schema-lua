local QueryRenderer = require("exasolvs.QueryRenderer")
local log = require("remotelog")
local ExaError = require("ExaError")

--- This class rewrites the query.
-- @classmod QueryRewriter
local QueryRewriter = {}

local function validate(query)
    if not query then
        ExaError.error("E-RLSL-QRW-1", "Unable to rewrite query because it was <nil>.")
    end
    local push_down_type = query.type
    if(push_down_type ~= "select") then
        ExaError.error("E-RLSL-QRW-2", "Unable to rewrite push-down query of type {{query_type}}"
            .. ". Only 'select' is supported.", {query_type =  push_down_type})
    end
end

local function is_select_star(select_list)
    return select_list == nil
end

local function is_empty_select_list(select_list)
    return next(select_list) == nil
end

local function replace_empty_select_list_with_constant_expression(query)
    log.debug('Empty select list pushed down. Replacing with constant expression to get correct number of rows.')
    query.selectList = {{type = "literal_bool", value = "true"}}
end

local function expand_select_list_without_protection(query)
    if is_select_star(query.selectList) then
        log.debug('Missing select list interpreted as: SELECT *')
    elseif is_empty_select_list(query.selectList) then
        replace_empty_select_list_with_constant_expression(query)
    end
end

local function rewrite_without_protection(query)
    expand_select_list_without_protection(query)
end

local function extend_query_with_source_schema(query, source_schema_id)
    query.from.schema = source_schema_id
end

--- Rewrite the original query with RLS restrictions.
-- @param original_query structure containing the original push-down query
-- @param source_schema_id source schema RLS is put on top of
-- @param _ cache taken from the adapter notes
-- @param _ list of tables that appear in the query
-- @return string containing the rewritten query
function QueryRewriter.rewrite(original_query, source_schema_id, _, _)
    validate(original_query)
    local query = original_query
    rewrite_without_protection(query)
    extend_query_with_source_schema(query, source_schema_id)
    local renderer = QueryRenderer:new(query)
    return renderer:render()
end

return QueryRewriter