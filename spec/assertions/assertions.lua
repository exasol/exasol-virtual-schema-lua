local assert = require("luassert")
local say = require("say")
local cjson = require("cjson")

---
-- @module Custom assertions based on the assertions in the `busted` framework
--
local M = {}

local function same_json(_, arguments)
    local expected<const> = arguments[1]
    local actual<const> = arguments[2]
    return assert.are.same(expected, cjson.decode(actual))
end

local function error_contains(_, arguments)
    local callback<const> = arguments[1]
    local expected<const> = arguments[2]
    return assert.error_matches(callback, expected, 1, true)
end

local function abstract_method(_, arguments)
    local callback<const> = arguments[1]
    return assert.error_matches(callback, "Attempted to call the abstract method .*")
end

say:set("assertion.same_json.positive", "Expected %s\nto be a JSON encoded structure that matches: %s")
say:set("assertion.same_json.negative", "Expected %s\nto be a JSON encoded structure that differs from: %s")
say:set("assertion.error_contains.positive", "Expected %s\nto be error containing: %s")
say:set("assertion.error_contains.negative", "Expected %s\nto be error that does not contain: %s")
say:set("assertion.abstract_method.positive", "Expected %s\to be an abstract method producing the error: %s")
say:set("assertion.abstract_method.negative", "Expected %s\to be a concrete method not producing the error: %s")

assert:register("assertion", "same_json", same_json, "assertion.same_json.positive", "assertion.same_json.negative")
assert:register("assertion", "error_contains", error_contains, "assertion.error_contains.positive",
                "assertion.error_contains.negative")
assert:register("assertion", "abstract_method", abstract_method, "assertion.abstract_method_positive",
                "assertion.abstract_error.negative")

return M
