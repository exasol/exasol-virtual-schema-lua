require("busted.runner")()
require("assertions.appender_assertions")
local Query = require("exasol.vscl.Query")
local literal = require("exasol.vscl.queryrenderer.literal_constructors")
local reference = require("exasol.vscl.queryrenderer.reference_constructors")
local ExpressionAppender = require("exasol.vscl.queryrenderer.ExpressionAppender")
local AbstractQueryAppender = require("exasol.vscl.queryrenderer.AbstractQueryAppender")

---@param expression any
---@param expected string
---@param appender_config AppenderConfig?
local function assert_expression_yields(expression, expected, appender_config)
    assert.append_yields(ExpressionAppender, expected, expression, appender_config)
end

local function testee()
    return ExpressionAppender:new(Query:new(), AbstractQueryAppender.DEFAULT_APPENDER_CONFIG)
end

describe("ExpressionRenderer", function()
    it("renders column reference", function()
        assert_expression_yields(reference.column("the_table", --
        "the_column"), '"the_table"."the_column"')
    end)

    it("renders column reference with custom quote", function()
        assert_expression_yields(reference.column("the_table", "the_column"), '`the_table`.`the_column`',
                                 {identifier_quote = "`"})
    end)

    describe("renders literal:", function()
        it("null", function()
            assert_expression_yields(literal.null(), "null")
        end)

        it("true", function()
            assert_expression_yields(literal.bool(true), "true")
        end)

        it("false", function()
            assert_expression_yields(literal.bool(false), "false")
        end)

        it("exact numeric", function()
            assert_expression_yields(literal.exactnumeric(math.pi), tostring(math.pi))
        end)

        it("double", function()
            assert_expression_yields(literal.double(1.23456789), "1.23456789")
        end)

        it("string", function()
            assert_expression_yields(literal.string("hello world"), "'hello world'")
        end)

        it("date", function()
            assert_expression_yields(literal.date("2022-12-31"), "DATE '2022-12-31'")
        end)

        it("timestamp", function()
            assert_expression_yields(literal.timestamp("2022-12-31 12:30:24.007"), --
            "TIMESTAMP '2022-12-31 12:30:24.007'")
        end)

        it("interval YM with precision", function()
            assert_expression_yields(literal.interval_ym("+14-05", 5), "INTERVAL '+14-05' YEAR(5) TO MONTH")
        end)

        it("interval YM without precision", function()
            assert_expression_yields(literal.interval_ym("+14-05"), "INTERVAL '+14-05' YEAR TO MONTH")
        end)

        it("interval DS with precision and fraction", function()
            assert_expression_yields(literal.interval_ds("-123 01:02:03.456", 4, 3),
                                     "INTERVAL '-123 01:02:03.456' DAY(4) TO SECOND(3)")
        end)

        it("interval DS without precision and fraction", function()
            assert_expression_yields(literal.interval_ds("-234 12:23:34.001"),
                                     "INTERVAL '-234 12:23:34.001' DAY TO SECOND")
        end)
    end)

    describe("renders an embedded scalar function:", function()
        it("CURRENT_USER", function()
            assert_expression_yields({type = "function_scalar", name = "CURRENT_USER"}, "CURRENT_USER")
        end)
    end)

    describe("renders predicate:", function()
        it("unary NOT", function()
            assert_expression_yields({type = "predicate_not", expression = literal.bool(true)}, "(NOT true)")
        end)

        it("AND", function()
            assert_expression_yields({type = "predicate_and", expressions = {literal.bool(true), literal.bool(false)}},
                                     "(true AND false)")
        end)

        it("OR", function()
            assert_expression_yields({
                type = "predicate_or",
                expressions = {
                    literal.bool(true), literal.bool(false), {type = "predicate_not", expression = literal.bool(true)}
                }
            }, "(true OR false OR (NOT true))")
        end)

        it("=", function()
            assert_expression_yields({
                type = "predicate_equal",
                left = literal.exactnumeric(4),
                right = literal.exactnumeric(7)
            }, "(4 = 7)")
        end)

        it("<>", function()
            assert_expression_yields({
                type = "predicate_notequal",
                left = literal.exactnumeric(4),
                right = literal.exactnumeric(7)
            }, "(4 <> 7)")
        end)

        it("<", function()
            assert_expression_yields({
                type = "predicate_less",
                left = literal.exactnumeric(4),
                right = literal.exactnumeric(7)
            }, "(4 < 7)")
        end)

        it(">", function()
            assert_expression_yields({
                type = "predicate_greater",
                left = literal.exactnumeric(4),
                right = literal.exactnumeric(7)
            }, "(4 > 7)")
        end)

        it("<=", function()
            assert_expression_yields({
                type = "predicate_lessequal",
                left = literal.exactnumeric(4),
                right = literal.exactnumeric(7)
            }, "(4 <= 7)")
        end)

        it(">=", function()
            assert_expression_yields({
                type = "predicate_greaterequal",
                left = literal.exactnumeric(4),
                right = literal.exactnumeric(7)
            }, "(4 >= 7)")
        end)

        it("LIKE", function()
            assert_expression_yields({
                type = "predicate_like",
                expression = reference.column("ADDRESSES", "STREET"),
                pattern = literal.string("Bakerst%")
            }, "(\"ADDRESSES\".\"STREET\" LIKE 'Bakerst%')")
        end)

        it("LIKE with custom escape character", function()
            assert_expression_yields({
                type = "predicate_like",
                expression = reference.column("VARIABLES", "ID"),
                pattern = literal.string("MAX~_%"),
                escapeChar = literal.string('~')
            }, "(\"VARIABLES\".\"ID\" LIKE 'MAX~_%' ESCAPE '~')")
        end)

        it("LIKE with a regular expression", function()
            assert_expression_yields({
                type = "predicate_like_regexp",
                expression = reference.column("VARIABLES", "ID"),
                pattern = literal.string("(MIN|MAX)_[^_]+_VALUE")
            }, "(\"VARIABLES\".\"ID\" REGEXP_LIKE '(MIN|MAX)_[^_]+_VALUE')")
        end)

        it("EXISTS in the where clause", function()
            local original_query = {
                type = "predicate_exists",
                query = {
                    type = "sub_select",
                    selectList = {literal.exactnumeric(1)},
                    filter = {
                        type = "predicate_greater",
                        left = reference.column("people", "age"),
                        right = literal.exactnumeric(21)
                    }
                }
            }
            assert_expression_yields(original_query, 'EXISTS(SELECT 1 WHERE ("people"."age" > 21))')
        end)

        it("IN", function()
            local original_query = {
                type = "predicate_in_constlist",
                expression = reference.column("open", "weekday"),
                arguments = {literal.string("Mon"), literal.string("Tue"), literal.string("Wed"), literal.string("Thu")}
            }
            assert_expression_yields(original_query, [[("open"."weekday" IN ('Mon', 'Tue', 'Wed', 'Thu'))]])
        end)

        it("IS NULL", function()
            local original_query = {
                type = "predicate_is_null",
                expression = reference.column("deliveries", "return_address")
            }
            assert_expression_yields(original_query, [[("deliveries"."return_address" IS NULL)]])
        end)

        it("IS NOT NULL", function()
            local original_query = {
                type = "predicate_is_not_null",
                expression = reference.column("deliveries", "return_address")
            }
            assert_expression_yields(original_query, [[("deliveries"."return_address" IS NOT NULL)]])
        end)

        it("BETWEEN", function()
            local original_query = {
                type = "predicate_between",
                expression = reference.column("temperatures", "in_avg"),
                left = reference.column("temperatures", "out_min"),
                right = reference.column("temperatures", "out_max")
            }
            assert_expression_yields(original_query, '("temperatures"."in_avg" BETWEEN "temperatures"."out_min" '
                                             .. 'AND "temperatures"."out_max")')
        end)

        for predicate_key, predicate in pairs({predicate_is_json = "IS JSON", predicate_is_not_json = "IS NOT JSON"}) do
            describe(predicate .. ":", function()
                it("minimal", function()
                    local original_query = {
                        type = predicate_key,
                        expression = reference.column("configurations", "ui_settings")
                    }
                    assert_expression_yields(original_query, [["configurations"."ui_settings" ]] .. predicate)
                end)

                for _, constraint in ipairs({"VALUE", "ARRAY", "OBJECT", "SCALAR"}) do
                    it("with type constraint '" .. constraint .. "'", function()
                        local original_query = {
                            type = predicate_key,
                            expression = reference.column("configurations", "ui_settings"),
                            typeConstraint = constraint
                        }
                        assert_expression_yields(original_query,
                                                 [["configurations"."ui_settings" ]] .. predicate .. " " .. constraint)
                    end)
                end

                for _, uniqueness in ipairs({"WITH UNIQUE KEYS", "WITHOUT UNIQUE KEYS"}) do
                    it(uniqueness, function()
                        local original_query = {
                            type = predicate_key,
                            expression = literal.string("{\"enabled\" : true}"),
                            keyUniquenessConstraint = uniqueness
                        }
                        assert_expression_yields(original_query,
                                                 [['{"enabled" : true}' ]] .. predicate .. " " .. uniqueness)
                    end)
                end
            end)
        end
    end)

    it("raises an error if the output query is missing", function()
        assert.has_error(function()
            ExpressionAppender:new()
        end, "AbstractQueryAppender requires a query object that it can append to.")
    end)

    it("raises an error if the appender configuration is missing", function()
        assert.has_error(function()
            ExpressionAppender:new(Query:new())
        end, "AbstractQueryAppender requires an appender configuration.")
    end)

    it("raises an error if an unknown predicate type is used", function()
        local appender = testee()
        assert.error_matches(function()
            appender:_append_unary_predicate({type = "illegal predicate type"})
        end, "Cannot determine operator for unknown predicate type 'illegal predicate type'.", 1, true)
    end)

    it("raises an error if the expression type is unknown", function()
        local appender = testee()
        assert.error_matches(function()
            appender:append_expression({type = "illegal expression type"})
        end, "Unable to render unknown SQL expression type 'illegal expression type'.", 1, true)
    end)

    it("raises an error if the data type is unknown", function()
        local appender = testee()
        assert.error_matches(function()
            appender:_append_data_type({type = "illegal datatype"})
        end, "Unable to render unknown data type 'illegal datatype'.")
    end)
end)
