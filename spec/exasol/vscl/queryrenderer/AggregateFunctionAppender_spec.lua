require("busted.runner")()
local literal = require("exasol.vscl.queryrenderer.literal_constructors")
local reference = require("exasol.vscl.queryrenderer.reference_constructors")
local Query = require("exasol.vscl.Query")
local AggregateFunctionAppender = require("exasol.vscl.queryrenderer.AggregateFunctionAppender")
local AbstractQueryAppender = require("exasol.vscl.queryrenderer.AbstractQueryAppender")

local function it_asserts(expected, actual, explanation)
    it(explanation or expected, function()
        assert.are.equals(expected, actual)
    end)
end

---@param out_query Query?
---@return AggregateFunctionAppender
local function testee(out_query)
    return AggregateFunctionAppender:new(out_query or Query:new(), AbstractQueryAppender.DEFAULT_APPENDER_CONFIG)
end

local function run_complex_function(name, extra_attributes, ...)
    local out_query = Query:new()
    local renderer = testee(out_query)
    local scalar_function = renderer["_" .. string.lower(name)]
    assert(scalar_function ~= nil, "Aggregate function " .. name .. " must be present in renderer")
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
---@param ... Expression arguments passed to the function
---@return string rendered_function function rendered as string
local function run_function(name, ...)
    return run_complex_function(name, {}, ...)
end

describe("AggregateFunctionRenderer", function()
    it_asserts('APPROXIMATE_COUNT_DISTINCT("customers"."customer_id")', run_function("APPROXIMATE_COUNT_DISTINCT", {
        type = "column",
        name = "customer_id",
        tableName = "customers"
    }), "APPROXIMATE_COUNT_DISTINCT")

    it_asserts("COUNT(*)", run_function("COUNT"), "COUNT(*)")

    for _, grouping_alias in ipairs({"GROUPING", "GROUPING_ID"}) do
        it_asserts(grouping_alias .. '("sales"."yr", "sales"."mon")',
                   run_function(grouping_alias, reference.column("sales", "yr"), reference.column("sales", "mon")),
                   grouping_alias)
    end

    for _, single_parameter_functions_without_distinct in ipairs({"FIRST_VALUE", "LAST_VALUE", "MEDIAN"}) do
        local expression = {
            type = "predicate_less",
            left = reference.column("visitors", "age"),
            right = literal.exactnumeric(30)
        }
        it_asserts(single_parameter_functions_without_distinct .. '(("visitors"."age" < 30))',
                   run_function(single_parameter_functions_without_distinct, expression),
                   single_parameter_functions_without_distinct)
    end

    -- ANY is just a alias for SOME. So not tested here.
    for _, function_supporting_distinct in ipairs({
        "AVG", "COUNT", "EVERY", "MAX", "SOME", "MIN", "MUL", "STDDEV", "STDDEV_POP", "STDDEV_SAMP", "SUM", "VAR_POP",
        "VAR_SAMP", "VARIANCE"
    }) do
        local expression = {
            type = "predicate_less",
            left = {type = "column", name = "age", tableName = "visitors"},
            right = literal.exactnumeric(30)
        }
        it_asserts(function_supporting_distinct .. '(("visitors"."age" < 30))',
                   run_function(function_supporting_distinct, expression), function_supporting_distinct)
        it_asserts(function_supporting_distinct .. '(DISTINCT ("visitors"."age" < 30))',
                   run_complex_function(function_supporting_distinct, {distinct = true}, expression),
                   function_supporting_distinct)
    end

    for _, double_parameter_function in ipairs({
        "CORR", "COVAR_POP", "COVAR_SAMP", "REGR_AVGX", "REGR_AVGY", "REGR_COUNT", "REGR_INTERCEPT", "REGR_R2",
        "REGR_SLOPE", "REGR_SXX", "REGR_SXY", "REGR_SYY"
    }) do
        it_asserts(double_parameter_function .. '("employees"."age", "employees"."current_salary")',
                   run_function(double_parameter_function, reference.column("employees", "age"),
                                reference.column("employees", "current_salary")), "ANY")
    end

    it("asserts functions that are not allowed to have a DISTINCT modifier", function()
        local renderer = testee()
        assert.has_error(function()
            renderer:append({name = "MEDIAN", distinct = "true"})
        end, "Aggregate function 'MEDIAN' must not have a DISTINCT modifier.")
    end)

    -- Counting tuples is special in that it requires the tuple to be enclosed in an extra set of parenthesis to work.
    describe("add extra parenthesis when counting tuples:", function()
        it_asserts('COUNT(("employees"."age", "employees"."department"))',
                   run_function("COUNT", {type = "column", name = "age", tableName = "employees"},
                                {type = "column", name = "department", tableName = "employees"}), "COUNT tuple")
    end)

    describe("puts the extra parenthesis after the DISTINCT:", function()
        it_asserts('COUNT(DISTINCT ("employees"."age", "employees"."department"))',
                   run_complex_function("COUNT", {distinct = true},
                                        {type = "column", name = "age", tableName = "employees"},
                                        {type = "column", name = "department", tableName = "employees"}),
                   "COUNT DISTINCT tuple")
    end)

    -- ST_UNION doubles as both an aggregate and scalar function. This depends on the number of parameters. A single
    -- parameter leads to aggregation, two parameters turn it into a scalar function.
    describe("accepts ST_UNION as aggregate function with a single argument:", function()
        it_asserts('ST_UNION("map"."shape")',
                   run_function("ST_UNION", {type = "column", name = "shape", tableName = "map"}),
                   "ST_UNION (single column aggregate)")
    end)

    describe("accepts ST_INTERSECTION as aggregate function with a single argument:", function()
        it_asserts('ST_INTERSECTION("map"."shape")',
                   run_function("ST_INTERSECTION", {type = "column", name = "shape", tableName = "map"}),
                   "ST_UNION (single column aggregate)")
    end)
    it_asserts('GROUP_CONCAT("DEPARTMENTS"."NAME")',
               run_function("GROUP_CONCAT", reference.column("DEPARTMENTS", "NAME")),
               "GROUP_CONCAT with default separator")

    it_asserts([[GROUP_CONCAT(DISTINCT "PATHS"."PATH" SEPARATOR ':')]], run_complex_function("GROUP_CONCAT", {
        distinct = true,
        separator = ":"
    }, reference.column("PATHS", "PATH")), "GROUP_CONCAT with DISTINCT and a custom separator")

    it_asserts(
            [[GROUP_CONCAT("PATHS"."PATH" ORDER BY "PATHS"."PRIORITY" DESC, "PATHS"."PATH" NULLS LAST SEPARATOR ';')]],
            run_complex_function("GROUP_CONCAT", {
                separator = ";",
                orderBy = {
                    {expression = reference.column("PATHS", "PRIORITY"), isAscending = false},
                    {expression = reference.column("PATHS", "PATH"), nullsLast = true}
                }
            }, reference.column("PATHS", "PATH")), "GROUP_CONCAT with DISTINCT and a custom separator")

    it_asserts([[LISTAGG("fruits"."fruit")]], run_complex_function("LISTAGG",
                                                                   {arguments = {reference.column("fruits", "fruit")}},
                                                                   "LISTAGG with arguments only"))

    it_asserts([[LISTAGG("fruits"."fruit", ', ')]],
               run_complex_function("LISTAGG", {
        arguments = {reference.column("fruits", "fruit")},
        separator = literal.string(", ")
    }, "LISTAGG with a separator"))

    it_asserts([[LISTAGG(DISTINCT "addresses"."zip_code")]], run_complex_function("LISTAGG", {
        arguments = {reference.column("addresses", "zip_code")},
        distinct = true
    }), "LISTAGG over distinct values")

    it_asserts([[LISTAGG("capabilities"."name" ON OVERFLOW ERROR)]], run_complex_function("LISTAGG", {
        arguments = {reference.column("capabilities", "name")},
        overflowBehavior = {type = "ERROR"}
    }), "LISTAGG producing error in case of overflow")

    it_asserts([[LISTAGG("capabilities"."name" ON OVERFLOW TRUNCATE WITHOUT COUNT)]], run_complex_function("LISTAGG", {
        arguments = {reference.column("capabilities", "name")},
        overflowBehavior = {type = "TRUNCATE"}
    }), "LISTAGG truncating in case of overflow")

    it_asserts([[LISTAGG("capabilities"."name" ON OVERFLOW TRUNCATE ', etc.' WITHOUT COUNT)]],
               run_complex_function("LISTAGG", {
        arguments = {reference.column("capabilities", "name")},
        overflowBehavior = {type = "TRUNCATE", truncationFiller = literal.string(", etc.")}
    }), "LISTAGG truncating with filler in case of overflow")

    it_asserts([[LISTAGG("capabilities"."name" ON OVERFLOW TRUNCATE WITH COUNT)]], run_complex_function("LISTAGG", {
        arguments = {reference.column("capabilities", "name")},
        overflowBehavior = {type = "TRUNCATE", truncationType = "WITH COUNT"}
    }), "LISTAGG truncating with count in case of overflow")

    it_asserts([[LISTAGG(CONCAT("users"."firstname", ' ', "users"."lastname"))]]
                       .. [[ WITHIN GROUP (ORDER BY "users"."age" DESC)]], run_complex_function("LISTAGG", {
        arguments = {
            {
                type = "function_scalar",
                name = "CONCAT",
                arguments = {
                    reference.column("users", "firstname"), literal.string(" "), reference.column("users", "lastname")
                }
            }
        },
        orderBy = {{type = "order_by_element", expression = reference.column("users", "age"), isAscending = false}}
    }), "LISTAGG using a given order")
end)
