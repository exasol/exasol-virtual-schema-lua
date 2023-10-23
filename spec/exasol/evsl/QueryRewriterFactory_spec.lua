package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local QueryRewriterFactory = require("exasol.evsl.QueryRewriterFactory")

describe("QueryRewriterFactory", function()
    it("creates a local query rewriter", function()
        local factory = QueryRewriterFactory:new()
        local reader = factory:create_rewriter()
        assert.are_same("LocalQueryRewriter", reader.class()._NAME)
    end)

    it("creates a remote query rewriter", function()
        local factory = QueryRewriterFactory:new()
        local reader = factory:create_rewriter("THE CONNECTION")
        assert.are_same("RemoteQueryRewriter", reader.class()._NAME)
    end)
end)