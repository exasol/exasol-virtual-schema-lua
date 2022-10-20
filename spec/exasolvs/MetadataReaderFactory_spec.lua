package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local MetadataReaderFactory = require("exasolvs.MetadataReaderFactory")

describe("MetadataReaderFactory", function()
    it("asserts that the Exasol context is provided during construction", function()
        assert.error_matches(function() MetadataReaderFactory:new() end,
                "Metadata reader factory requires an Exasol script context in order to create a reader." , 1, true)
    end)

    it("creates a local metadata reader", function()
        local exasol_context_mock = {}
        local factory = MetadataReaderFactory:new(exasol_context_mock)
        local reader = factory:create_local_reader()
        assert.are.same(MetadataReaderFactory.LOCAL, reader.get_type())
    end)

end)