require("busted.runner")()
require("assertions.assertions")
local AbstractVirtualSchemaAdapter = require("exasol.vscl.AbstractVirtualSchemaAdapter")
local AdapterProperties = require("exasol.vscl.AdapterProperties")
local adapter_stub = require("exasol.vscl.adapter_stub")

describe("Stubbed AbstractVirtualSchemaAdapter", function()
    it("reports all supported capabilities", function()
        local properties = AdapterProperties:new({})
        local stub = adapter_stub.create({
            _define_capabilities = function()
                return {"cap1", "cap2"}
            end
        })
        assert.are.same(stub:get_capabilities(nil, properties),
                        {type = "getCapabilities", capabilities = {"cap1", "cap2"}})
    end)

    it("reports all capabilities except the ones the user excluded [utest -> dsn~excluding-capabilities~0]", function()
        local properties = AdapterProperties:new({EXCLUDED_CAPABILITIES = "cap1, cap3"})
        local stub = adapter_stub.create({
            _define_capabilities = function()
                return {"cap1", "cap2", "cap3", "cap4"}
            end
        })
        assert.are.same(stub:get_capabilities(nil, properties),
                        {type = "getCapabilities", capabilities = {"cap2", "cap4"}})
    end)

    it("has a basic DROP SCHEMA handler (which does nothing)", function()
        local stub = adapter_stub.create()
        assert.are.same(stub:drop_virtual_schema(), {type = "dropVirtualSchema"})
    end)

    describe("is an abstract class with abstract method:", function()
        local names = {
            "_define_capabilities", "create_virtual_schema", "get_name", "get_version", "refresh", "set_properties",
            "push_down"
        }
        for _, name in ipairs(names) do
            it(name, function()
                assert.is_not_nil(AbstractVirtualSchemaAdapter[name])
                assert.is.abstract_method(AbstractVirtualSchemaAdapter[name])
            end)
        end
    end)
end)
