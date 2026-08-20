require("busted.runner")()
local LocalQueryRewriter = require("exasol.evscl.LocalQueryRewriter")

describe("Local query rewriter", function()
    local rewriter = LocalQueryRewriter:new()

    local function assert_rewrite(original_query, source_schema, adapter_cache, expected)
        local rewritten_query = rewriter:rewrite(original_query, source_schema, adapter_cache)
        assert.are_same(expected, rewritten_query)
    end

    -- [utest -> dsn~evscl.rewriting-a-query-for-local-access~0]
    it("rewrites a query with an simple table", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "A_table"},
                {type = "column", name = "C2", tableName = "A_table"}
            },
            from = {type = "table", name = "A_table"}
        }
        assert_rewrite(original_query, "S", nil, 'SELECT "A_table"."C1", "A_table"."C2" FROM "S"."A_table"')
    end)

    it("renders a timestamp with precision", function()
        local original_query = {
            type = "select",
            selectList = {
                {
                    type = "function_scalar_cast",
                    name = "CAST",
                    arguments = {
                        {
                            columnNr = 4,
                            name = "RECORDED",
                            tableName = "EVENTS",
                            type = "column"
                        }
                    },
                    dataType = {
                        type = "TIMESTAMP",
                        precision = 9
                    }
                }
            }
        }
        assert_rewrite(original_query, "S", nil, 'SELECT CAST("EVENTS"."RECORDED" AS TIMESTAMP(9))')
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