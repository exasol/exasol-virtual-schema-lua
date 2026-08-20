require("busted.runner")()

local Query = require("exasol.vscl.Query")

describe("Query", function()
    it("appends token", function()
        local query = Query:new({"foo", "bar"})
        query:append("baz")
        assert.are.same({"foo", "bar", "baz"}, query._tokens)
    end)

    it("appends a series of tokens", function()
        local query = Query:new({"before"})
        query:append_all("foo", "bar", "baz")
        assert.are.same({"before", "foo", "bar", "baz"}, query._tokens)
    end)

    it("produces a string", function()
        local query = Query:new({"this", " & ", "that"})
        assert.are.equals("this & that", query:to_string())
    end)

    it("provides list of tokens", function()
        local query = Query:new({"veni", "vidi", "vici"})
        assert.are.same({"veni", "vidi", "vici"}, query:get_tokens())
    end)
end)
