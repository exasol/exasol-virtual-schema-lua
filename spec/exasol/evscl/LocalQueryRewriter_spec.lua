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

    -- [utest -> dsn~evsl.preserving-top-level-literal-types~0]
    local literal_cases = {
        {name = "NULL", expression = {type = "literal_null"}, data_type = {type = "VARCHAR", size = 50},
         expected = "CAST(null AS VARCHAR(50))"},
        {name = "a string", expression = {type = "literal_string", value = "x"},
         data_type = {type = "VARCHAR", size = 50}, expected = "CAST('x' AS VARCHAR(50))"},
        {name = "an exact numeric", expression = {type = "literal_exactnumeric", value = 1},
         data_type = {type = "DECIMAL", precision = 18, scale = 0}, expected = "CAST(1 AS DECIMAL(18,0))"},
        {name = "a double", expression = {type = "literal_double", value = 1.5}, data_type = {type = "DOUBLE"},
         expected = "CAST(1.5 AS DOUBLE)"},
        {name = "a boolean", expression = {type = "literal_bool", value = true}, data_type = {type = "BOOLEAN"},
         expected = "CAST(true AS BOOLEAN)"},
        {name = "a date", expression = {type = "literal_date", value = "2026-01-01"}, data_type = {type = "DATE"},
         expected = "CAST(DATE '2026-01-01' AS DATE)"},
        {name = "a timestamp", expression = {type = "literal_timestamp", value = "2026-01-01 12:00:00"},
         data_type = {type = "TIMESTAMP"}, expected = "CAST(TIMESTAMP '2026-01-01 12:00:00' AS TIMESTAMP)"}
    }
    for _, literal_case in ipairs(literal_cases) do
        it("casts " .. literal_case.name .. " to its select-list result type", function()
            local original_query = {
                type = "select",
                selectList = {literal_case.expression},
                selectListDataTypes = {literal_case.data_type},
                from = {type = "table", name = "T1"}
            }
            assert_rewrite(original_query, "S", nil,
                    "SELECT " .. literal_case.expected .. " FROM \"S\".\"T1\"")
        end)
    end

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
