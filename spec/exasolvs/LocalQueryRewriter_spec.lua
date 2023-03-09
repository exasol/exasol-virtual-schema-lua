package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local LocalQueryRewriter = require("exasolvs.LocalQueryRewriter")

describe("Local query rewriter", function()
    local rewriter = LocalQueryRewriter:new()

    local function assert_rewrite(original_query, source_schema, adapter_cache, expected)
        local rewritten_query = rewriter:rewrite(original_query, source_schema, adapter_cache)
        assert.are_same(expected, rewritten_query)
    end

    it("rewrites a query with an unprotected table", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "UNPROT"},
                {type = "column", name = "C2", tableName = "UNPROT"}
            },
            from = {type = "table", name = "UNPROT"}
        }
        assert_rewrite(original_query, "S", "UNPROT:---", 'SELECT "UNPROT"."C1", "UNPROT"."C2" FROM "S"."UNPROT"')
    end)

    it("raises an error if the query to be rewritten is nil.", function()
        assert.error_matches(function() rewriter:rewrite(nil, nil, nil) end,
                "Unable to rewrite query because it was <nil>.", 1, true)
    end)

    it("raises an error if the query to be rewritten is not a SELECT", function()
        local original_query = {type = "insert"}
        assert.error_matches(function() rewriter:rewrite(original_query) end,
                "Unable to rewrite push-down query of type 'insert'. Only 'select' is supported.", 1, true)
    end)
end)