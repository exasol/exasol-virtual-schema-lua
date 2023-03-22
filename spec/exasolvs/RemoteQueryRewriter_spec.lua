package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local RemoteQueryRewriter = require("exasolvs.RemoteQueryRewriter")

describe("Remote Query rewriter", function()
    local rewriter = RemoteQueryRewriter:new("TEST_CONNECTION")

    local function assert_rewrite(original_query, source_schema, expected)
        local rewritten_query = rewriter:rewrite(original_query, source_schema)
        assert.are_same(expected, rewritten_query)
    end

    it("rewrites a query with an unprotected table", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "T1"},
                {type = "column", name = "C2", tableName = "T1"}
            },
            from = {type = "table", name = "T1"}
        }
        assert_rewrite(original_query, "S",
                [[IMPORT FROM EXA AT "TEST_CONNECTION" STATEMENT 'SELECT "T1"."C1", "T1"."C2" FROM "S"."T1"']])
    end)

    it("rewrites a query with a list of select column types", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "T1"},
                {type = "column", name = "C2", tableName = "T1"}
            },
            selectListDataTypes = {
                {type = "BOOLEAN"},
                {type = "VARCHAR", size = 400}
            },
            from = {type = "table", name = "T1"}
        }
        assert_rewrite(original_query, "S",
                [[IMPORT INTO (c1 BOOLEAN, c2 VARCHAR(400)) FROM EXA AT "TEST_CONNECTION" ]]
                        .. [[STATEMENT 'SELECT "T1"."C1", "T1"."C2" FROM "S"."T1"']])
    end)
end)