package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local RemoteQueryRewriter = require("exasol.evsl.RemoteQueryRewriter")

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

    -- [utest -> dsn~evsl.preserving-top-level-literal-types~0]
    local literal_cases = {
        {name = "NULL", expression = {type = "literal_null"}, data_type = {type = "VARCHAR", size = 50},
         expected_type = "VARCHAR(50)", expected = "CAST(null AS VARCHAR(50))"},
        {name = "a string", expression = {type = "literal_string", value = "x"},
         data_type = {type = "VARCHAR", size = 50}, expected_type = "VARCHAR(50)",
         expected = "CAST(''x'' AS VARCHAR(50))"},
        {name = "an exact numeric", expression = {type = "literal_exactnumeric", value = 1},
         data_type = {type = "DECIMAL", precision = 18, scale = 0}, expected_type = "DECIMAL(18,0)",
         expected = "CAST(1 AS DECIMAL(18,0))"}
    }
    for _, literal_case in ipairs(literal_cases) do
        it("casts " .. literal_case.name .. " to its select-list result type", function()
            local original_query = {
                type = "select",
                selectList = {literal_case.expression},
                selectListDataTypes = {literal_case.data_type},
                from = {type = "table", name = "T1"}
            }
            assert_rewrite(original_query, "S", [[IMPORT INTO (c1 ]] .. literal_case.expected_type
                    .. [[) FROM EXA AT "TEST_CONNECTION" STATEMENT 'SELECT ]] .. literal_case.expected
                    .. [[ FROM "S"."T1"']])
        end)
    end
end)
