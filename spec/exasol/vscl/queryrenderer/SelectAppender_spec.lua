require("busted.runner")()
require("assertions.appender_assertions")
local SelectAppender = require("exasol.vscl.queryrenderer.SelectAppender")

---@param expected string
---@param original_query any
---@param appender_config AppenderConfig?
local function assert_yields(expected, original_query, appender_config)
    assert.append_yields(SelectAppender, expected, original_query, appender_config)
end

local function assert_select_error(expected, original_query)
    assert.append_error(SelectAppender, expected, original_query)
end

describe("SelectAppender", function()
    it("renders SELECT *", function()
        local original_query = {type = "select", from = {type = "table", name = "T1"}}
        assert_yields('SELECT * FROM "T1"', original_query)
    end)

    it("renders SELECT * from a table with given schema", function()
        local original_query = {type = "select", from = {type = "table", schema = "S1", name = "T1"}}
        assert_yields('SELECT * FROM "S1"."T1"', original_query)
    end)

    it("renders SELECT * from a table with given catalog and schema", function()
        local original_query = {type = "select", from = {type = "table", catalog = "C1", schema = "S1", name = "T1"}}
        assert_yields('SELECT * FROM "C1"."S1"."T1"', original_query)
    end)

    it("renders SELECT * with custom identifier quote", function()
        local original_query = {type = "select", from = {type = "table", catalog = "C1", schema = "S1", name = "T1"}}
        assert_yields('SELECT * FROM `C1`.`S1`.`T1`', original_query, {identifier_quote = "`"})
    end)

    it("renders SELECT * ignoring catalog when schema is missing", function()
        local original_query = {type = "select", from = {type = "table", catalog = "C1", name = "T1"}}
        assert_yields('SELECT * FROM "T1"', original_query)
    end)

    it("renders a SELECT with a table and two columns", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "C1", tableName = "T1"}, {type = "column", name = "C2", tableName = "T1"}
            },
            from = {type = "table", name = "T1"}
        }
        assert_yields('SELECT "T1"."C1", "T1"."C2" FROM "T1"', original_query)
    end)

    describe("renders literal", function()
        local literals = {
            {input = {type = "literal_null"}, expected = "null"},
            {input = {type = "literal_string", value = "a_string"}, expected = "'a_string'"},
            {input = {type = "literal_double", value = 3.1415}, expected = "3.1415"},
            {input = {type = "literal_exactnumeric", value = 9876543210}, expected = "9876543210"},
            {input = {type = "literal_bool", value = true}, expected = "true"},
            {input = {type = "literal_date", value = "2015-12-01"}, expected = "DATE '2015-12-01'"}, {
                input = {type = "literal_timestamp", value = "2015-12-01 12:01:01.1234"},
                expected = "TIMESTAMP '2015-12-01 12:01:01.1234'"
            }, {
                input = {type = "literal_timestamputc", value = "2015-12-01 12:01:01.1234"},
                expected = "TIMESTAMP '2015-12-01 12:01:01.1234'"
            }
        }
        for _, literal in ipairs(literals) do
            it("(" .. literal.input.type .. ") " .. tostring(literal.input.value), function()
                local original_query = {
                    type = "select",
                    selectList = {literal.input},
                    from = {type = "table", name = "T1"}
                }
                assert_yields('SELECT ' .. literal.expected .. ' FROM "T1"', original_query)
            end)
        end
    end)

    it("renders a single predicate filter", function()
        local original_query = {
            type = "select",
            selectList = {{type = "column", name = "NAME", tableName = "MONTHS"}},
            from = {type = "table", name = "MONTHS"},
            filter = {
                type = "predicate_greater",
                left = {type = "column", name = "DAYS_IN_MONTH", tableName = "MONTHS"},
                right = {type = "literal_exactnumeric", value = "30"}
            }
        }
        assert_yields('SELECT "MONTHS"."NAME" FROM "MONTHS" WHERE ("MONTHS"."DAYS_IN_MONTH" > 30)', original_query)
    end)

    it("renders nested predicate filter", function()
        local original_query = {
            type = "select",
            selectList = {{type = "column", name = "NAME", tableName = "MONTHS"}},
            from = {type = "table", name = "MONTHS"},
            filter = {
                type = "predicate_and",
                expressions = {
                    {
                        type = "predicate_equal",
                        left = {type = "literal_string", value = "Q3"},
                        right = {type = "column", name = "QUARTER", tableName = "MONTHS"}
                    }, {
                        type = "predicate_greater",
                        left = {type = "column", name = "DAYS_IN_MONTH", tableName = "MONTHS"},
                        right = {type = "literal_exactnumeric", value = "30"}
                    }
                }
            }
        }
        assert_yields('SELECT "MONTHS"."NAME" FROM "MONTHS" WHERE ((\'Q3\' = "MONTHS"."QUARTER") '
                              .. 'AND ("MONTHS"."DAYS_IN_MONTH" > 30))', original_query)
    end)

    it("renders a unary NOT filter", function()
        local original_query = {
            type = "select",
            selectList = {{type = "column", name = "NAME", tableName = "MONTHS"}},
            from = {type = "table", name = "MONTHS"},
            filter = {
                type = "predicate_not",
                expression = {
                    type = "predicate_equal",
                    left = {type = "literal_string", value = "Q3"},
                    right = {type = "column", name = "QUARTER", tableName = "MONTHS"}
                }
            }
        }
        assert_yields('SELECT "MONTHS"."NAME" FROM "MONTHS" WHERE (NOT (\'Q3\' = "MONTHS"."QUARTER"))', original_query)
    end)

    it("renders a scalar function in a filter in the WHERE clause", function()
        local original_query = {
            type = "select",
            selectList = {{type = "column", name = "LASTNAME", tableName = "PEOPLE"}},
            from = {type = "table", name = "PEOPLE"},
            filter = {
                type = "predicate_equal",
                left = {
                    type = "function_scalar",
                    name = "LOWER",
                    arguments = {{type = "column", name = "FIRSTNAME", tableName = "PEOPLE"}}
                },
                right = {type = "literal_string", value = "eve"}
            }
        }
        assert_yields([[SELECT "PEOPLE"."LASTNAME" FROM "PEOPLE" WHERE (LOWER("PEOPLE"."FIRSTNAME") = 'eve')]],
                      original_query)
    end)

    it("renders an aggregate function in the select list", function()
        local original_query = {
            type = "select",
            selectList = {
                {
                    type = "function_aggregate",
                    name = "COUNT",
                    arguments = {{type = "column", name = "LASTNAME", tableName = "PEOPLE"}}
                }
            },
            from = {type = "table", name = "PEOPLE"}
        }
        assert_yields([[SELECT COUNT("PEOPLE"."LASTNAME") FROM "PEOPLE"]], original_query)
    end)

    it("renders an aggregate function in the WHERE clause", function()
        local original_query = {
            type = "select",
            from = {type = "table", name = "PEOPLE"},
            filter = {
                type = "predicate_greater",
                left = {
                    type = "function_aggregate",
                    name = "COUNT",
                    arguments = {{type = "column", name = "LASTNAME", tableName = "PEOPLE"}}
                },
                right = {type = "literal_exactnumeric", value = 100}
            }
        }
        assert_yields([[SELECT * FROM "PEOPLE" WHERE (COUNT("PEOPLE"."LASTNAME") > 100)]], original_query)
    end)

    it("renders the predicate IN in the where clause", function()
        local original_query = {
            type = "select",
            selectList = {{type = "literal_string", value = "hello"}},
            from = {type = "table", name = "T1"},
            filter = {
                type = "predicate_in_constlist",
                expression = {type = "column", name = "C1", tableName = "T1"},
                arguments = {{type = "literal_string", value = "A1"}, {type = "literal_string", value = "A2"}}
            }
        }
        assert_yields([[SELECT 'hello' FROM "T1" WHERE ("T1"."C1" IN ('A1', 'A2'))]], original_query)
    end)

    it("renders a sub-SELECT", function()
        local original_query = {
            type = "select",
            selectList = {
                {type = "column", name = "NAME", tableName = "FRUITS"},
                {type = "column", name = "SUGAR_PERCENTAGE", tableName = "FRUITS"}
            },
            from = {type = "table", name = "FRUITS"},
            filter = {
                type = "predicate_greater",
                left = {type = "column", name = "SUGAR_PERCENTAGE", tableName = "FRUITS"},
                right = {
                    type = "sub_select",
                    selectList = {{type = "column", name = "SUGAR_PERCENTAGE", tableName = "SNACKS"}},
                    from = {type = "table", name = "SNACKS"},
                    filter = {
                        type = "predicate_equal",
                        left = {type = "column", name = "CATEGORY", tableName = "SNACKS"},
                        right = {type = "literal_string", value = "desert"}
                    }
                }
            }
        }
        assert_yields('SELECT "FRUITS"."NAME", "FRUITS"."SUGAR_PERCENTAGE" FROM "FRUITS"'
                              .. ' WHERE ("FRUITS"."SUGAR_PERCENTAGE"' .. ' > ('
                              .. 'SELECT "SNACKS"."SUGAR_PERCENTAGE" FROM "SNACKS" WHERE '
                              .. '("SNACKS"."CATEGORY" = \'desert\')))', original_query)
    end)

    it("renders a JOIN clause", function()
        for join_type, join_keyword in pairs(SelectAppender.get_join_types()) do
            local original_query = {
                type = "select",
                selectList = {
                    {type = "column", name = "AMOUNT", tableName = "ORDERS"},
                    {type = "column", name = "NAME", tableName = "ITEMS"}
                },
                from = {
                    type = "join",
                    join_type = join_type,
                    left = {type = "table", name = "ORDERS"},
                    right = {type = "table", name = "ITEMS"},
                    condition = {
                        type = "predicate_equal",
                        left = {type = "column", name = "ITEM_ID", tableName = "ORDERS"},
                        right = {type = "column", name = "ITEM_ID", tableName = "ITEMS"}
                    }
                }
            }
            assert_yields('SELECT "ORDERS"."AMOUNT", "ITEMS"."NAME"' .. ' FROM "ORDERS" ' .. join_keyword
                                  .. ' JOIN "ITEMS"' .. ' ON ("ORDERS"."ITEM_ID" = "ITEMS"."ITEM_ID")', original_query)
        end
    end)

    describe("renders a LIMIT clause", function()
        it("without OFFSET", function()
            local original_query = {type = "select", from = {type = "table", name = "T1"}, limit = {numElements = 10}}
            assert_yields('SELECT * FROM "T1" LIMIT 10', original_query)
        end)

        it("with OFFSET", function()
            local original_query = {
                type = "select",
                from = {type = "table", name = "T2"},
                limit = {numElements = 20, offset = 8}
            }
            assert_yields('SELECT * FROM "T2" LIMIT 20 OFFSET 8', original_query)
        end)
    end)

    describe("renders an ORDER BY clause", function()
        local unsorted_query = {
            type = "select",
            selectList = {{type = "column", name = "NAME", tableName = "USERS"}},
            from = {type = "table", name = "USERS"}
        }
        local variants = {
            {
                order = {{type = "order_by_element", expression = {type = "column", name = "ID", tableName = "USERS"}}},
                expected = 'ORDER BY "USERS"."ID"'
            }, {
                order = {
                    {
                        type = "order_by_element",
                        expression = {type = "column", name = "NUMBER", tableName = "USERS"},
                        isAscending = true
                    }
                },
                expected = 'ORDER BY "USERS"."NUMBER" ASC'
            }, {
                order = {
                    {
                        type = "order_by_element",
                        expression = {type = "column", name = "NUMBER", tableName = "USERS"},
                        isAscending = false
                    }
                },
                expected = 'ORDER BY "USERS"."NUMBER" DESC'
            }, {
                order = {
                    {
                        type = "order_by_element",
                        expression = {type = "column", name = "NUMBER", tableName = "USERS"},
                        nullsLast = true
                    }
                },
                expected = 'ORDER BY "USERS"."NUMBER" NULLS LAST'
            }, {
                order = {
                    {
                        type = "order_by_element",
                        expression = {type = "column", name = "NUMBER", tableName = "USERS"},
                        nullsLast = false
                    }
                },
                expected = 'ORDER BY "USERS"."NUMBER" NULLS FIRST'
            }, {
                order = {
                    {type = "order_by_element", expression = {type = "column", name = "ID", tableName = "USERS"}}, {
                        type = "order_by_element",
                        expression = {type = "column", name = "NUMBER", tableName = "USERS"},
                        nullsLast = false,
                        isAscending = true
                    }
                },
                expected = 'ORDER BY "USERS"."ID", "USERS"."NUMBER" ASC NULLS FIRST'
            }
        }
        for _, variant in ipairs(variants) do
            it(variant.expected, function()
                local original_query = unsorted_query
                original_query.orderBy = variant.order
                assert_yields('SELECT "USERS"."NAME" FROM "USERS" ' .. variant.expected, original_query)
            end)
        end
    end)

    it("renders a GROUP BY clause with a single grouping criteria", function()
        local original_query = {
            type = "select",
            selectList = {
                {name = "COUNT", type = "function_aggregate"}, {name = "TYPE", tableName = "TICKETS", type = "column"}
            },
            from = {type = "table", name = "TICKETS"},
            groupBy = {{name = "TYPE", tableName = "TICKETS", type = "column"}}
        }
        assert_yields('SELECT COUNT(*), "TICKETS"."TYPE" FROM "TICKETS" GROUP BY "TICKETS"."TYPE"', original_query)
    end)

    it("renders a GROUP BY clause with multiple grouping criteria", function()
        local original_query = {
            type = "select",
            selectList = {
                {name = "COUNT", type = "function_aggregate"}, {name = "TYPE", tableName = "TICKETS", type = "column"},
                {name = "PRIORITY", tableName = "TICKETS", type = "column"}
            },
            from = {type = "table", name = "TICKETS"},
            groupBy = {
                {name = "TYPE", tableName = "TICKETS", type = "column"},
                {name = "PRIORITY", tableName = "TICKETS", type = "column"}
            }
        }
        assert_yields('SELECT COUNT(*), "TICKETS"."TYPE", "TICKETS"."PRIORITY" FROM "TICKETS"'
                              .. ' GROUP BY "TICKETS"."TYPE", "TICKETS"."PRIORITY"', original_query)
    end)

    it("replaces a numeric literal in a GROUP BY with a string literal", function()
        local original_query = {
            type = "select",
            selectList = {
                {name = "COUNT", type = "function_aggregate"}, {name = "TYPE", tableName = "TICKETS", type = "column"}
            },
            from = {type = "table", name = "TICKETS"},
            groupBy = {{value = 0, type = "literal_exactnumeric"}}
        }
        assert_yields('SELECT COUNT(*), "TICKETS"."TYPE" FROM "TICKETS" GROUP BY \'0\'', original_query)
    end)

    it("raises an error if the WHERE clause type is unknown", function()
        local original_query = {
            type = "select",
            selectList = {{type = "literal_bool", value = false}},
            from = {type = "unknown"}
        }
        assert_select_error("unknown SQL FROM clause type", original_query)
    end)

    it("raises an error if the JOIN type is unknown", function()
        local original_query = {
            type = "select",
            selectList = {{type = "literal_bool", value = false}},
            from = {type = "join", join_type = "join_type_illegal"}
        }
        assert_select_error("unknown join type 'join_type_illegal'", original_query)
    end)

    it("raises an error if the predicate type is unknown", function()
        local original_query = {type = "select", selectList = {{type = "predicate_illegal"}}}
        assert_select_error("unknown SQL predicate type 'predicate_illegal'", original_query)
    end)

    it("raises an error if the expression type is unknown", function()
        local original_query = {type = "select", selectList = {{type = "illegal expression type"}}}
        assert_select_error("unknown SQL expression type 'illegal expression type'", original_query)
    end)

    it("raises an error if the data type is unknown", function()
        local original_query = {
            type = "select",
            selectList = {
                {
                    type = "function_scalar_cast",
                    name = "CAST",
                    dataType = {type = "illegal"},
                    arguments = {{type = "literal_string", value = "100"}}
                }
            }
        }
        assert_select_error("unknown data type", original_query)
    end)
end)
