require("busted.runner")()
local literal = require("exasol.vscl.queryrenderer.literal_constructors")
local geo = require("exasol.vscl.queryrenderer.geo_constructors")
local Query = require("exasol.vscl.Query")
local ScalarFunctionAppender = require("exasol.vscl.queryrenderer.ScalarFunctionAppender")
local AbstractQueryAppender = require("exasol.vscl.queryrenderer.AbstractQueryAppender")

local function it_asserts(expected, actual, explanation)
    it(explanation or expected, function()
        assert.are.equals(expected, actual)
    end)
end

---@param name string
---@param extra_attributes table<string, any>
---@param ... number|integer|string|table
---@return string rendered_function function rendered as string
local function run_complex_function(name, extra_attributes, ...)
    local out_query = Query:new()
    local renderer = ScalarFunctionAppender:new(out_query, AbstractQueryAppender.DEFAULT_APPENDER_CONFIG)
    local scalar_function = renderer["_" .. string.lower(name)]
    assert(scalar_function ~= nil, "Scalar function " .. name .. " must be present in renderer")
    local wrapped_arguments = literal.wrap_literals(...)
    local attributes = {name = name, arguments = wrapped_arguments}
    for key, value in pairs(extra_attributes) do
        attributes[key] = value
    end
    scalar_function(renderer, attributes)
    return out_query:to_string()
end

--- Run a scalar function.
---@param name string name of the scalar function to run
---@param ... number|integer|string|table arguments passed to the function
---@return string rendered_function function rendered as string
local function run_function(name, ...)
    return run_complex_function(name, {}, ...)
end

describe("ScalarFunctionRenderer", function()
    describe("supports numeric function", function()
        describe("with a single argument", function()
            for _, name in ipairs({
                "ABS", "ACOS", "ASIN", "ATAN", "ATAN2", "CEIL", "COS", "COSH", "COT", "DEGREES", "EXP", "FLOOR", "LN",
                "LOG", "MIN_SCALE", "RADIANS", "ROUND", "SIGN", "SIN", "SINH", "SQRT", "TAN", "TANH"
            }) do
                it_asserts(name .. "(30)", run_function(name, 30))
            end

            it_asserts("-123.8", run_function("NEG", 123.8), "NEG (unary negation)")
        end)

        describe("with two arguments", function()
            it_asserts("1 + 2", run_function("ADD", 1, 2))
            it_asserts("DIV(7, 3)", run_function("DIV", 7, 3))
            it_asserts("7.0 / 3.0", run_function("FLOAT_DIV", 7.0, 3.0))
            it_asserts("42 - 47.11", run_function("SUB", 42, 47.11))
            it_asserts("MOD(13, 5)", run_function("MOD", 13, 5))
            it_asserts("21 * 167.6", run_function("MULT", 21, 167.6))
            it_asserts("POWER(4, 9)", run_function("POWER", 4, 9))
            it_asserts("RAND(2, 16)", run_function("RAND", 2, 16))

            it_asserts("TO_CHAR(12345.6789, '9999999.999999999')",
                       run_function("TO_CHAR", 12345.6789, "9999999.999999999"))

            it_asserts("TO_NUMBER('-123.45', '99999.999')", run_function("TO_NUMBER", "-123.45", "99999.999"))

            it_asserts("TRUNC(123.456, 2)", run_function("TRUNC", 123.456, 2))
        end)
    end)

    describe("supports string function", function()
        describe("with a single string argument", function()
            for _, name in ipairs({
                "ASCII", "BIT_LENGTH", "CHR", "COLOGNE_PHONETIC", "INITCAP", "LENGTH", "LOWER", "LTRIM", "OCTET_LENGTH",
                "REVERSE", "RTRIM", "TRIM", "UNICODE", "UNICODECHR", "UPPER", "SOUNDEX"
            }) do
                it_asserts(name .. "('the text')", run_function(name, "the text"))
            end
        end)

        describe("with a single non-string argument", function()
            it_asserts("SPACE(15)", run_function("SPACE", 15))
        end)

        describe("with two arguments", function()
            it_asserts("EDIT_DISTANCE('frog', 'dog')", run_function("EDIT_DISTANCE", "frog", "dog"))
            it_asserts("LEFT('foobar', 3)", run_function("LEFT", "foobar", 3))
            it_asserts("REPEAT('A', 11)", run_function("REPEAT", "A", 11))
            it_asserts("RIGHT('foobar', 3)", run_function("RIGHT", "foobar", 3))
        end)

        describe("with three arguments", function()
            it_asserts("LOCATE('user', 'user1,user2,user3,user4,user5', -1)",
                       run_function("LOCATE", "user", "user1,user2,user3,user4,user5", -1))

            it_asserts("LPAD('abc', 5, 'X')", run_function("LPAD", "abc", 5, "X"))

            it_asserts("REPLACE('Apple juice is great', 'Apple', 'Orange')",
                       run_function("REPLACE", "Apple juice is great", "Apple", "Orange"))

            it_asserts("RPAD('def', 7, 'Y')", run_function("RPAD", "def", 7, "Y"))

            it_asserts("SUBSTR('foobar', 2, 3)", run_function("SUBSTR", "foobar", 2, 3))

            it_asserts("TRANSLATE('abcd', 'abc', 'xy')", run_function("TRANSLATE", "abcd", "abc", "xy"))
        end)

        describe("with four arguments", function()
            it_asserts("DUMP('simsalabim', 16, 4, 3)", run_function("DUMP", "simsalabim", 16, 4, 3))

            it_asserts("INSERT('abcdef', 3, 2, 'CD')", run_function("INSERT", "abcdef", 3, 2, "CD"))

            it_asserts("INSTR('user1,user2,user3,user4,user5', 'user', -1, 2)",
                       run_function("INSTR", "user1,user2,user3,user4,user5", "user", -1, 2))
        end)

        describe("with variable number of arguments", function()
            it_asserts("CONCAT('FOO', 'BAR', 'BAZ')", run_function("CONCAT", "FOO", "BAR", "BAZ"))
        end)

        it_asserts("REGEXP_INSTR('the number is 42', '[0-9]+')",
                   run_function("REGEXP_INSTR", "the number is 42", "[0-9]+"))

        it_asserts("REGEXP_SUBSTR('the number is 42', '[0-9]+')",
                   run_function("REGEXP_SUBSTR", "the number is 42", "[0-9]+"))
    end)

    it("can nest functions", function()
        assert.are.equals("SIN(DEGREES(PI()))", run_function("SIN", {
            type = "function_scalar",
            name = "DEGREES",
            arguments = {{type = "function_scalar", name = "PI"}}
        }))
    end)

    describe("supports date / time function", function()
        describe("parameterless function", function()
            for _, name in pairs({
                "SYSDATE", "SYSTIMESTAMP", "CURRENT_DATE", "CURRENT_TIMESTAMP", "DBTIMEZONE", "LOCALTIMESTAMP",
                "SESSIONTIMEZONE"
            }) do
                it_asserts(name, run_function(name))
            end
        end)

        it_asserts("ADD_DAYS(DATE '2000-02-28', 1)", run_function("ADD_DAYS", literal.date("2000-02-28"), 1))

        it_asserts("ADD_HOURS(TIMESTAMP '2000-01-01 12:23:45', -1)",
                   run_function("ADD_HOURS", literal.timestamp("2000-01-01 12:23:45"), -1))

        it_asserts("ADD_MINUTES(TIMESTAMP '2000-02-01 12:23:45', 30)",
                   run_function("ADD_MINUTES", literal.timestamp("2000-02-01 12:23:45"), 30))

        it_asserts("ADD_MONTHS(TIMESTAMP '2000-01-02 12:23:45', 12)",
                   run_function("ADD_MONTHS", literal.timestamp("2000-01-02 12:23:45"), 12))

        it_asserts("ADD_SECONDS(TIMESTAMP '2001-01-01 12:23:45', 600)",
                   run_function("ADD_SECONDS", literal.timestamp("2001-01-01 12:23:45"), 600))

        it_asserts("ADD_WEEKS(TIMESTAMP '2022-01-01 12:23:45', -13)",
                   run_function("ADD_WEEKS", literal.timestamp("2022-01-01 12:23:45"), -13))

        it_asserts("ADD_YEARS(TIMESTAMP '2002-01-01 12:23:45', 1000)",
                   run_function("ADD_YEARS", literal.timestamp("2002-01-01 12:23:45"), 1000))

        it_asserts("CONVERT_TZ(TIMESTAMP '2012-03-25 02:30:00', 'Europe/Berlin', 'UTC', "
                           .. "'INVALID REJECT AMBIGUOUS REJECT')",
                   run_function("CONVERT_TZ", literal.timestamp("2012-03-25 02:30:00"), "Europe/Berlin", "UTC",
                                "INVALID REJECT AMBIGUOUS REJECT"))

        it_asserts("DATE_TRUNC('month', DATE '2006-12-31')",
                   run_function("DATE_TRUNC", 'month', literal.date("2006-12-31")))

        it_asserts("DAY(DATE '1970-01-01')", run_function("DAY", literal.date("1970-01-01")))

        it_asserts("DAYS_BETWEEN(DATE '2000-01-01', DATE '2000-12-31')",
                   run_function("DAYS_BETWEEN", literal.date("2000-01-01"), literal.date("2000-12-31")))

        describe("EXTRACT", function()
            local parameters = {
                {
                    to_extract = 'YEAR',
                    argument = {columnNr = 0, name = "col_1", tableName = "t", type = "column"},
                    expected = 'EXTRACT(YEAR FROM "t"."col_1")'
                }, {
                    to_extract = 'MONTH',
                    argument = {columnNr = 0, name = "col_1", tableName = "t", type = "column"},
                    expected = 'EXTRACT(MONTH FROM "t"."col_1")'
                }, {
                    to_extract = 'SECOND',
                    argument = {type = 'literal_timestamp', value = '2019-02-12 12:07:00'},
                    expected = "EXTRACT(SECOND FROM TIMESTAMP '2019-02-12 12:07:00')"
                }
            }
            for _, parameter in ipairs(parameters) do
                it_asserts(parameter.expected,
                           run_complex_function("EXTRACT", {toExtract = parameter.to_extract}, parameter.argument))
            end
        end)

        it_asserts("FROM_POSIX_TIME(1234567890)", run_function("FROM_POSIX_TIME", 1234567890))

        it_asserts("HOUR(TIMESTAMP '1901-02-03 04:05:06')",
                   run_function("HOUR", literal.timestamp('1901-02-03 04:05:06')))

        it_asserts("HOURS_BETWEEN(TIMESTAMP '1901-02-03 04:05:06', TIMESTAMP '1901-02-03 12:05:06')", run_function(
                "HOURS_BETWEEN", literal.timestamp('1901-02-03 04:05:06'), literal.timestamp('1901-02-03 12:05:06')))

        it_asserts("MINUTE(TIMESTAMP '1901-02-03 04:05:06')",
                   run_function("MINUTE", literal.timestamp('1901-02-03 04:05:06')))

        it_asserts("MINUTES_BETWEEN(TIMESTAMP '1901-02-03 04:05:06', TIMESTAMP '1901-02-03 12:05:06')", run_function(
                "MINUTES_BETWEEN", literal.timestamp('1901-02-03 04:05:06'), literal.timestamp('1901-02-03 12:05:06')))

        it_asserts("MONTH(TIMESTAMP '1901-03-03 04:05:06')",
                   run_function("MONTH", literal.timestamp('1901-03-03 04:05:06')))

        it_asserts("MONTHS_BETWEEN(TIMESTAMP '1901-03-03 04:05:06', TIMESTAMP '1901-07-03 12:05:06')", run_function(
                "MONTHS_BETWEEN", literal.timestamp('1901-03-03 04:05:06'), literal.timestamp('1901-07-03 12:05:06')))

        it_asserts("NUMTODSINTERVAL(3.2, 'HOUR')", run_function("NUMTODSINTERVAL", 3.2, "HOUR"))

        it_asserts("NUMTOYMINTERVAL(3.5, 'YEAR')", run_function("NUMTOYMINTERVAL", 3.5, "YEAR"))

        it_asserts("POSIX_TIME('1970-01-01 00:00:01')", run_function("POSIX_TIME", "1970-01-01 00:00:01"))

        it_asserts("SECOND(TIMESTAMP '1901-03-03 04:05:06')",
                   run_function("SECOND", literal.timestamp('1901-03-03 04:05:06')))

        it_asserts("SECONDS_BETWEEN(TIMESTAMP '1901-03-03 04:05:06', TIMESTAMP '1901-07-03 12:05:06')", run_function(
                "SECONDS_BETWEEN", literal.timestamp('1901-03-03 04:05:06'), literal.timestamp('1901-07-03 12:05:06')))

        it_asserts("TO_DATE('31-12-1999', 'DD-MM-YYYY')", run_function("TO_DATE", "31-12-1999", "DD-MM-YYYY"))

        it_asserts("TO_DSINTERVAL('3 10:59:59.123')", run_function("TO_DSINTERVAL", "3 10:59:59.123"))

        it_asserts("TO_TIMESTAMP('23:59:00 31-12-1999', 'HH24:MI:SS DD-MM-YYYY')",
                   run_function("TO_TIMESTAMP", "23:59:00 31-12-1999", "HH24:MI:SS DD-MM-YYYY"))

        it_asserts("TO_YMINTERVAL('3-11')", run_function("TO_YMINTERVAL", "3-11"))

        it_asserts("WEEK(DATE '2012-01-05')", run_function("WEEK", literal.date("2012-01-05")))

        it_asserts("YEAR(TIMESTAMP '1901-03-03 04:05:06')",
                   run_function("YEAR", literal.timestamp('1901-03-03 04:05:06')))

        it_asserts("YEARS_BETWEEN(TIMESTAMP '1901-03-03 04:05:06', TIMESTAMP '1981-07-03 12:05:06')", run_function(
                "YEARS_BETWEEN", literal.timestamp('1901-03-03 04:05:06'), literal.timestamp('1981-07-03 12:05:06')))
    end)

    describe("supports geospacial functions", function()
        it_asserts("ST_X('POINT (1 2)')", run_function("ST_X", geo.point(1, 2)))

        it_asserts("ST_Y('POINT (1 2)')", run_function("ST_Y", geo.point(1, 2)))

        it_asserts("ST_ENDPOINT('LINESTRING (0 0, 0 1, 1 1)')",
                   run_function("ST_ENDPOINT", geo.linestring(0, 0, 0, 1, 1, 1)))

        it_asserts("ST_ISCLOSED('LINESTRING (0 0, 0 1, 1 1)', 'LINESTRING (2 3, 3 4)')",
                   run_function("ST_ISCLOSED", geo.linestring(0, 0, 0, 1, 1, 1), geo.linestring(2, 3, 3, 4)))

        it_asserts("ST_ISRING('LINESTRING (0 0, 0 1, 1 1)')",
                   run_function("ST_ISRING", geo.linestring(0, 0, 0, 1, 1, 1)))

        it_asserts("ST_LENGTH('LINESTRING (0 0, 0 1)', 'LINESTRING (2 3, 3 4)')",
                   run_function("ST_LENGTH", geo.linestring(0, 0, 0, 1), geo.linestring(2, 3, 3, 4)))

        it_asserts("ST_NUMPOINTS('LINESTRING (1 2, 3 4)')", run_function("ST_NUMPOINTS", geo.linestring(1, 2, 3, 4)))

        it_asserts("ST_POINTN('LINESTRING (0 5, 10 20)', 2)", --
        run_function("ST_POINTN", geo.linestring(0, 5, 10, 20), 2))

        it_asserts("ST_STARTPOINT('LINESTRING (0 0, 0 1, 1 1)')",
                   run_function("ST_STARTPOINT", geo.linestring(0, 0, 0, 1, 1, 1)))

        it_asserts("ST_AREA('POLYGON ((0 0, 0 4, 4 4, 4 0, 0 0), (1 1, 1 2, 2 2, 2 1, 1 1))')",
                   run_function("ST_AREA", geo.polygon({0, 0, 0, 4, 4, 4, 4, 0, 0, 0}, {1, 1, 1, 2, 2, 2, 2, 1, 1, 1})))

        it_asserts("ST_EXTERIORRING('POLYGON ((1 2, 2 3, 3 4, 1 2))')",
                   run_function("ST_EXTERIORRING", geo.polygon({1, 2, 2, 3, 3, 4, 1, 2})))

        it_asserts("ST_INTERIORRINGN('POLYGON ((1 2, 2 3, 3 4, 1 2))', 1)",
                   run_function("ST_INTERIORRINGN", geo.polygon({1, 2, 2, 3, 3, 4, 1, 2}), 1))

        it_asserts("ST_NUMINTERIORRINGS('POLYGON ((1 2, 2 3, 3 4, 1 2))')",
                   run_function("ST_NUMINTERIORRINGS", geo.polygon({1, 2, 2, 3, 3, 4, 1, 2})))

        it_asserts("ST_GEOMETRYN('GEOMETRYCOLLECTION (POINT (1 2), LINESTRING (0 0, 0 10))', 2)",
                   run_function("ST_GEOMETRYN", geo.collection(geo.point(1, 2), geo.linestring(0, 0, 0, 10)), 2))

        it_asserts("ST_NUMGEOMETRIES('GEOMETRYCOLLECTION (POINT (1 2), LINESTRING (0 0, 0 10))')",
                   run_function("ST_NUMGEOMETRIES", geo.collection(geo.point(1, 2), geo.linestring(0, 0, 0, 10))))

        it_asserts("ST_BOUNDARY('LINESTRING (0 1, 1 1)')", run_function("ST_BOUNDARY", geo.linestring(0, 1, 1, 1)))

        it_asserts("ST_BUFFER('POINT (0 1)', 3)", run_function("ST_BUFFER", geo.point(0, 1), 3))

        it_asserts("ST_CENTROID('POLYGON ((0 0, 0 2, 2 2, 2 0, 0 0))')",
                   run_function("ST_CENTROID", geo.polygon({0, 0, 0, 2, 2, 2, 2, 0, 0, 0})))

        it_asserts("ST_CONTAINS('POLYGON ((0 0, 2 4, 4 0, 0 0))', 'POINT (2 2)')",
                   run_function("ST_CONTAINS", geo.polygon({0, 0, 2, 4, 4, 0, 0, 0}), geo.point(2, 2)))

        it_asserts("ST_CONVEXHULL('POLYGON ((0 0, 2 4, 4 0, 0 0))')",
                   run_function("ST_CONVEXHULL", geo.polygon({0, 0, 2, 4, 4, 0, 0, 0})))

        it_asserts("ST_CROSSES('LINESTRING (0 0, 4 4)', 'LINESTRING (0 4, 4 0)')",
                   run_function("ST_CROSSES", geo.linestring(0, 0, 4, 4), geo.linestring(0, 4, 4, 0)))

        it_asserts("ST_DIFFERENCE('LINESTRING (0 0, 2 0)', 'LINESTRING (1 0, 2 0)')",
                   run_function("ST_DIFFERENCE", geo.linestring(0, 0, 2, 0), geo.linestring(1, 0, 2, 0)))

        it_asserts("ST_DIMENSION('POINT (0 0)')", run_function("ST_DIMENSION", geo.point(0, 0)))

        it_asserts("ST_DISJOINT('POINT (0 0)', 'POINT (1 1)')",
                   run_function("ST_DISJOINT", geo.point(0, 0), geo.point(1, 1)))

        it_asserts("ST_DISTANCE('LINESTRING (0 0, 1 0)', 'LINESTRING (0 1, 1 2)')",
                   run_function("ST_DISTANCE", geo.linestring(0, 0, 1, 0), geo.linestring(0, 1, 1, 2)))

        it_asserts("ST_ENVELOPE('POINT (6 6)')", run_function("ST_ENVELOPE", geo.point(6, 6)))

        it_asserts("ST_EQUALS('POINT (0 0)', 'POINT (1 1)')",
                   run_function("ST_EQUALS", geo.point(0, 0), geo.point(1, 1)))

        it_asserts("ST_FORCE2D('POINT (0 0 0)')", run_function("ST_FORCE2D", 'POINT (0 0 0)'))

        it_asserts("ST_GEOMETRYTYPE('POINT (7 7)')", run_function("ST_GEOMETRYTYPE", geo.point(7, 7)))

        it_asserts("ST_INTERSECTION('POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))', 'POLYGON ((2 0, 6 0, 6 4, 2 4, 2 0))')",
                   run_function("ST_INTERSECTION", geo.polygon({0, 0, 4, 0, 4, 4, 0, 4, 0, 0}),
                                geo.polygon({2, 0, 6, 0, 6, 4, 2, 4, 2, 0})))

        it_asserts("ST_INTERSECTS('POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))', 'LINESTRING (2 -1, 2 5)')", run_function(
                "ST_INTERSECTS", geo.polygon({0, 0, 4, 0, 4, 4, 0, 4, 0, 0}), geo.linestring(2, -1, 2, 5)))

        it_asserts("ST_ISEMPTY('GEOMETRYCOLLECTION EMPTY')", run_function("ST_ISEMPTY", 'GEOMETRYCOLLECTION EMPTY'))

        it_asserts("ST_ISSIMPLE('LINESTRING (1 1, 2 2)')", run_function("ST_ISSIMPLE", geo.linestring(1, 1, 2, 2)))

        it_asserts("ST_OVERLAPS('POLYGON ((0 0, 2 2, 4 0, 0 0))', 'POLYGON ((2 0, 4 2, 6 0, 2 0))')", run_function(
                "ST_OVERLAPS", geo.polygon({0, 0, 2, 2, 4, 0, 0, 0}), geo.polygon({2, 0, 4, 2, 6, 0, 2, 0})))

        it_asserts("ST_SETSRID('POINT (1 2)', 4513)", run_function("ST_SETSRID", geo.point(1, 2), 4513))

        it_asserts("ST_SYMDIFFERENCE('LINESTRING (3 0, 1 0)', 'LINESTRING (2 0, 0 0)')",
                   run_function("ST_SYMDIFFERENCE", geo.linestring(3, 0, 1, 0), geo.linestring(2, 0, 0, 0)))

        it_asserts("ST_TOUCHES('POLYGON ((0 0, 1 1, 2 0, 0 0))', 'LINESTRING (-1 -1, 2 2)')",
                   run_function("ST_TOUCHES", geo.polygon({0, 0, 1, 1, 2, 0, 0, 0}), geo.linestring(-1, -1, 2, 2)))

        it_asserts("ST_TRANSFORM('POINT (4000 5000)', 4513)", run_function("ST_TRANSFORM", geo.point(4000, 5000), 4513))

        it_asserts("ST_UNION('POLYGON ((0 0, 3 0, 3 1, 1 0, 0 0))', 'POLYGON ((1 0, 1 2, 2 2, 2 0, 1 0))')",
                   run_function("ST_UNION", geo.polygon({0, 0, 3, 0, 3, 1, 1, 0, 0, 0}),
                                geo.polygon({1, 0, 1, 2, 2, 2, 2, 0, 1, 0})))

        it_asserts("ST_WITHIN('POINT (1 1)', 'POLYGON ((0 0, 2 0, 2 2, 0 2, 0 0))')",
                   run_function("ST_WITHIN", geo.point(1, 1), geo.polygon({0, 0, 2, 0, 2, 2, 0, 2, 0, 0})))
    end)

    describe("supports bitwise functions", function()
        describe("with a single argument", function()
            it_asserts("BIT_NOT(1)", run_function("BIT_NOT", 1))
        end)

        describe("with two arguments", function()
            for _, name in pairs({
                "BIT_AND", "BIT_CHECK", "BIT_LROTATE", "BIT_LSHIFT", "BIT_OR", "BIT_RROTATE", "BIT_RSHIFT", "BIT_SET",
                "BIT_XOR"
            }) do
                it_asserts(name .. "(256, 3)", run_function(name, 256, 3))
            end
        end)

        describe("with variable number of arguments", function()
            it_asserts("BIT_TO_NUM(1, 5, 13)", run_function("BIT_TO_NUM", 1, 5, 13))
        end)
    end)

    describe("supports conversion function", function()
        it_asserts("CAST(347 AS VARCHAR(3))",
                   run_complex_function("CAST", {dataType = {type = "VARCHAR", size = 3}}, 347), "number to VARCHAR")

        it_asserts("CAST(347 AS TIMESTAMP(0))",
                   run_complex_function("CAST", {dataType = {type = "TIMESTAMP", precision = 0}}, 347),
                   "number to TIMESTAMP with precision")

        it_asserts("CAST(347 AS TIMESTAMP(9) WITH LOCAL TIME ZONE)",
                   run_complex_function("CAST", {dataType = {
                       type = "TIMESTAMP", precision = 9, withLocalTimeZone = true
                   }}, 347),
                   "number to TIMESTAMP with precision and local time zone")

        it_asserts("CAST(347 AS TIMESTAMP)", run_complex_function("CAST", {dataType = {type = "TIMESTAMP"}}, 347),
                   "number to TIMESTAMP without precision")

        it_asserts("CAST(347 AS TIMESTAMP WITH LOCAL TIME ZONE)",
                   run_complex_function("CAST", {dataType = {type = "TIMESTAMP", withLocalTimeZone = true}}, 347),
                   "number to TIMESTAMP with local time zone without precision")

        it_asserts("CAST(INTERVAL '+1-02' YEAR TO MONTH AS VARCHAR(7))",
                   run_complex_function("CAST", {dataType = {type = "VARCHAR", size = 7}}, {
            value = "+1-02",
            type = "literal_interval",
            dataType = {type = "INTERVAL", fromTo = "YEAR TO MONTH"}
        }), "interval to VARCHAR")
    end)

    describe("supports other functions", function()
        describe("parameterless function", function()
            for _, name in pairs({"CURRENT_SCHEMA", "CURRENT_SESSION", "CURRENT_STATEMENT", "CURRENT_USER"}) do
                assert.are.equals(name, run_function(name))
            end
        end)

        describe("with empty parameter list", function()
            for _, name in pairs({"SYS_GUID"}) do
                assert.are.equals(name .. "()", run_function(name))
            end
        end)

        describe("hashes", function()
            for _, name in pairs({
                "HASH_MD5", "HASHTYPE_MD5", "HASH_SHA1", "HASHTYPE_SHA1", "HASH_SHA256", "HASHTYPE_SHA256",
                "HASH_SHA512", "HASHTYPE_SHA512", "HASH_TIGER", "HASHTYPE_TIGER"
            }) do
                it_asserts(name .. "('hash me if you can')", run_function(name, "hash me if you can"))
            end
        end)

        describe("type identification", function()
            for _, name in pairs({
                "IS_NUMBER", "IS_BOOLEAN", "IS_DATE", "IS_DSINTERVAL", "IS_YMINTERVAL", "IS_TIMESTAMP"
            }) do
                it_asserts(name .. "('some text')", run_function(name, "some text"))
            end
        end)

        describe("with variable number of arguments", function()
            it_asserts("GREATEST(10, 9)", run_function("GREATEST", 10, 9))
            it_asserts("LEAST(10, 9)", run_function("LEAST", 10, 9))
        end)

        it_asserts([[CASE "t"."grade" WHEN 1 THEN 'GOOD' WHEN 2 THEN 'FAIR' WHEN 3 THEN 'POOR' ELSE 'INVALID' END]],
                   run_complex_function("CASE", {
            basis = {columnNr = 0, name = "grade", tableName = "t", type = "column"},
            results = {
                literal.string("GOOD"), literal.string("FAIR"), literal.string("POOR"), literal.string("INVALID")
            }
        }, 1, 2, 3))

        it_asserts([[CASE WHEN ("t"."percentage" >= 80) THEN 'good enough' ELSE 'not enough' END]],
                   run_complex_function("CASE", {
            arguments = {
                            {
                                left =
                                {
                                    columnNr = 0,
                                    name = "percentage",
                                    tableName = "t",
                                    type = "column"
                                },
                                right =
                                {
                                    type = "literal_exactnumeric",
                                    value = "80"
                                },
                                type = "predicate_greaterequal"
                            }
            },
            results = {
                literal.string("good enough"), literal.string("not enough")
            }
        }, 1, 2, 3))

        describe("JSON_VALUE", function()
            local parameters = {
                {
                    argument_1 = '{"a": 1}',
                    argument_2 = '$.a',
                    empty_behavior = {type = "DEFAULT", expression = literal.string('*** empty ***')},
                    error_behavior = {type = "DEFAULT", expression = literal.string('*** error ***')},
                    data_type = {size = 1000, type = "VARCHAR", characterSet = "UTF8"},
                    expected = [[JSON_VALUE('{"a": 1}', '$.a' RETURNING VARCHAR(1000) UTF8 ]]
                            .. "DEFAULT '*** empty ***' ON EMPTY DEFAULT '*** error ***' ON ERROR)"
                }, {
                    argument_1 = '{"a": 1}',
                    argument_2 = '$.a',
                    empty_behavior = {type = "NULL"},
                    error_behavior = {type = "ERROR"},
                    data_type = {size = 100, type = "VARCHAR"},
                    expected = [[JSON_VALUE('{"a": 1}', '$.a' RETURNING VARCHAR(100) NULL ON EMPTY ERROR ON ERROR)]]
                }, {
                    argument_1 = '{"a": 1}',
                    argument_2 = '$.a',
                    empty_behavior = {type = "NULL"},
                    error_behavior = {type = "ERROR"},
                    data_type = {type = "TIMESTAMP", precision = 9},
                    expected = [[JSON_VALUE('{"a": 1}', '$.a' RETURNING TIMESTAMP(9) NULL ON EMPTY ERROR ON ERROR)]]
                }, {
                    argument_1 = '{"a": 1}',
                    argument_2 = '$.a',
                    empty_behavior = {type = "NULL"},
                    error_behavior = {type = "ERROR"},
                    data_type = {type = "TIMESTAMP", precision = 0, withLocalTimeZone = true},
                    expected = [[JSON_VALUE('{"a": 1}', '$.a' RETURNING TIMESTAMP(0) WITH LOCAL TIME ZONE ]]
                            .. "NULL ON EMPTY ERROR ON ERROR)"
                }, {
                    argument_1 = '{"a": 1}',
                    argument_2 = '$.a',
                    empty_behavior = {type = "NULL"},
                    error_behavior = {type = "ERROR"},
                    data_type = {type = "TIMESTAMP", withLocalTimeZone = true},
                    expected = [[JSON_VALUE('{"a": 1}', '$.a' RETURNING TIMESTAMP WITH LOCAL TIME ZONE ]]
                            .. "NULL ON EMPTY ERROR ON ERROR)"
                }
            }
            for _, parameter in ipairs(parameters) do
                it("extracting from '" .. parameter.argument_1 .. "' with expression :" .. parameter.argument_2,
                   function()
                    local original_query = {
                        dataType = parameter.data_type,
                        returningDataType = parameter.data_type,
                        emptyBehavior = parameter.empty_behavior,
                        errorBehavior = parameter.error_behavior
                    }
                    assert.are.equals(parameter.expected, run_complex_function("JSON_VALUE", original_query,
                                                                               parameter.argument_1,
                                                                               parameter.argument_2))
                end)
            end
        end)

        it_asserts("NULLIFZERO(0)", run_function("NULLIFZERO", 0))

        it_asserts("TYPEOF(TO_CHAR(3.1415))", run_function("TYPEOF", {
            type = "function_scalar",
            name = "TO_CHAR",
            arguments = {literal.double(3.1415)}
        }))

        it_asserts("ZEROIFNULL(null)", run_function("ZEROIFNULL", literal.null()))

        it_asserts("SESSION_PARAMETER(CURRENT_SESSION, 'NLS_TIMESTAMP_FORMAT')", run_function("SESSION_PARAMETER", {
            type = "function_scalar",
            name = "CURRENT_SESSION"
        }, 'NLS_TIMESTAMP_FORMAT'))
    end)

    it("raises an error if you try to append a non-existent scalar function", function()
        local renderer = ScalarFunctionAppender:new(Query:new(), AbstractQueryAppender.DEFAULT_APPENDER_CONFIG)
        local non_existent_scalar_function = {name = "NON_EXISTENT"}
        assert.error_matches(function()
            renderer:append(non_existent_scalar_function)
        end, "Unable to render unsupported scalar function type 'non_existent'")
    end)
end)
