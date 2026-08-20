local say = require("say")
local assert = require("luassert")
local Query = require("exasol.vscl.Query")
local AbstractQueryAppender = require("exasol.vscl.queryrenderer.AbstractQueryAppender")

local function append_yields(_, arguments)
    local appender_class = arguments[1]
    local expected = arguments[2]
    local original_query = arguments[3]
    local appender_config = arguments[4] or AbstractQueryAppender.DEFAULT_APPENDER_CONFIG
    local out_query = Query:new()
    local appender = appender_class:new(out_query, appender_config)
    local ok, result = pcall(appender.append, appender, original_query)
    local actual = out_query:to_string()
    arguments[1] = original_query
    arguments[2] = expected
    if ok then
        arguments[3] = actual or "<nil>"
    else
        arguments[3] = "Error: " .. result
    end
    arguments.n = 3
    return expected == actual
end

local function append_error(_, arguments)
    local appender_class = arguments[1]
    local expected = arguments[2]
    local original_query = arguments[3]
    local appender_config = arguments[4] or AbstractQueryAppender.DEFAULT_APPENDER_CONFIG
    local out_query = Query:new()
    local appender = appender_class:new(out_query, appender_config)
    local ok, result = pcall(appender.append, appender, original_query)
    arguments[1] = original_query
    arguments[2] = expected
    if ok then
        arguments[3] = "no error (unexpected success)"
        return false
    else
        arguments[3] = result
        return string.find(result, expected, 1, true) ~= nil
    end
end

say:set("assertion.append_yields.positive", "Appended query part:\n%s\nExpected: %s\nbut got : %s")
say:set("assertion.append_yields.negative",
        "Appender query part \n%s\nExpected a different query than %s\nbut got exactly that")
say:set("assertion.append_error.positive",
        "Appended query  part:\n%s\n" .. "\nExpected error containing: %s\nbut got                  : %s")
say:set("assertion.append_error.negative",
        "Appended query part\n%sExpected error not containing:\n%s\nbut got exactly that")

assert:register("assertion", "append_error", append_error, "assertion.append_error.positive",
                "assertion.append_error.negative")
assert:register("assertion", "append_yields", append_yields, "assertion.append_yields.positive",
                "assertion.append_yields.negative")
