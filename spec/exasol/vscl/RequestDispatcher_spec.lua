require("busted.runner")()
local log_mock = mock(require("remotelog"), true)
package.preload["remotelog"] = function()
    return log_mock
end
require("assertions.assertions")
local RequestDispatcher = require("exasol.vscl.RequestDispatcher")
local AdapterProperties = require("exasol.vscl.AdapterProperties")
local adapater_stub = require("exasol.vscl.adapter_stub")

local function stub_adapter()
    return adapater_stub.create({
        get_name = function()
            return "Adapter Stub"
        end,
        get_version = function()
            return "0.0.0"
        end,
        _define_capabilities = function()
            return {}
        end
    })
end

local dispatcher = RequestDispatcher:new(stub_adapter(), AdapterProperties)

describe("RequestDispatcher", function()
    it("asserts that a virtual schema adapter is present", function()
        assert.error_contains(function()
            RequestDispatcher:new()
        end, "Request Dispatcher requires an adapter to dispatch too")
    end)

    it("converts a request from JSON format to a lua table [utest -> dsn~translating-json-request-to-lua-tables~0]",
       function()
        local adapter_mock = stub_adapter()
        local recorded_request
        adapter_mock.drop_virtual_schema = function(_, request, _)
            recorded_request = request
        end
        local dispatcher_with_adapter_mock = RequestDispatcher:new(adapter_mock, AdapterProperties)
        dispatcher_with_adapter_mock:adapter_call('{"type" : "dropVirtualSchema"}')
        assert.are.same({type = "dropVirtualSchema"}, recorded_request)
    end)

    it("converts a response from a Lua table to JSON format [utest -> dsn~translating-lua-tables-to-json-responses~0]",
       function()
        local adapter_mock = stub_adapter()
        adapter_mock.refresh = function(_, _, _)
            return {type = "refresh"}
        end
        local dispatcher_with_adapter_mock = RequestDispatcher:new(adapter_mock, AdapterProperties)
        local response = dispatcher_with_adapter_mock:adapter_call('{"type" : "refresh"}')
        assert.are.same('{"type":"refresh"}', response)
    end)

    it("reads user-defined properties [utest -> dsn~reading-user-defined-properties~0]", function()
        local adapter_mock = stub_adapter()
        local recorded_properties
        adapter_mock.create_virtual_schema = function(_, _, properties)
            recorded_properties = properties
        end
        local dispatcher_with_adapter_mock = RequestDispatcher:new(adapter_mock, AdapterProperties)
        local raw_request = '{"type" : "createVirtualSchema", "schemaMetadataInfo" : {"properties" : {"FOO" : "bar"}}}'
        dispatcher_with_adapter_mock:adapter_call(raw_request)
        assert.is.equal("bar", recorded_properties:get("FOO"))
    end)

    it("dispatches property setting [utest -> dsn~dispatching-set-properties-requests~0]", function()
        local adapter_mock = stub_adapter()
        local recorded_old_properties, recorded_new_properties
        adapter_mock.set_properties = function(_, _, old_properties, new_properties)
            recorded_old_properties = old_properties
            recorded_new_properties = new_properties
        end
        local dispatcher_with_adapter_mock = RequestDispatcher:new(adapter_mock, AdapterProperties)
        local raw_request = [[{
            "type" : "setProperties",
            "properties" : {"new1" : "nv1", "new2" : "nv2"},
            "schemaMetadataInfo" : {
                "properties" : {"old1" : "ov1", "old2" : "ov2"}
             }
        }]]
        dispatcher_with_adapter_mock:adapter_call(raw_request)
        assert.are.same(AdapterProperties:new({old1 = "ov1", old2 = "ov2"}), recorded_old_properties)
        assert.are.same(AdapterProperties:new({new1 = "nv1", new2 = "nv2"}), recorded_new_properties)
    end)

    it("dispatches get-capabilities request [utest -> dsn~dispatching-get-capabilities-requests~0]", function()
        local response = dispatcher:adapter_call('{"type" : "getCapabilities"}')
        local expected = {type = "getCapabilities", capabilities = {}}
        assert.is.same_json(expected, response)
    end)

    it("dispatches create-virtual-schema request [utest -> dsn~dispatching-create-virtual-schema-requests~0]",
       function()
        assert.error_contains(function()
            dispatcher:adapter_call('{"type" : "createVirtualSchema"}')
        end, "Attempted to call the abstract method AbstractVirtualSchemaAdapter:create_virtual_schema.")
    end)

    it("dispatches drop-virtual-schema request [utest -> dsn~dispatching-drop-virtual-schema-requests~0]", function()
        local response = dispatcher:adapter_call('{"type" : "dropVirtualSchema"}')
        local expected = {type = "dropVirtualSchema"}
        assert.is.same_json(expected, response)
    end)

    it("dispatches refresh request [utest -> dsn~dispatching-refresh-requests~0]", function()
        assert.error_contains(function()
            dispatcher:adapter_call('{"type" : "refresh"}')
        end, "Attempted to call the abstract method AbstractVirtualSchemaAdapter:refresh")
    end)

    it("dispatches set-properties request [utest -> dsn~dispatching-set-properties-requests~0]", function()
        assert.error_contains(function()
            dispatcher:adapter_call('{"type" : "setProperties"}')
        end, "Attempted to call the abstract method AbstractVirtualSchemaAdapter:set_properties")
    end)

    it("dispatches set-properties request [utest -> dsn~dispatching-push-down-requests~0]", function()
        assert.error_contains(function()
            dispatcher:adapter_call('{"type" : "pushdown"}')
        end, "Attempted to call the abstract method AbstractVirtualSchemaAdapter:push_down")
    end)

    it("sets up remote logging", function()
        dispatcher:adapter_call('{"type" : "getCapabilities", "schemaMetadataInfo" : '
                                        .. '{"properties" : {"DEBUG_ADDRESS" : "10.0.0.1:4000", '
                                        .. '"LOG_LEVEL" : "TRACE"}}}')
        assert.spy(log_mock.set_level).was.called_with("TRACE")
        assert.spy(log_mock.connect).was.called_with("10.0.0.1", 4000)
    end)

    local function call_with_illegal_request_type()
        dispatcher:adapter_call('{"type" : "illegal"}')
    end

    it("raises an error if it detects an illegal Virtual Schema request type", function()
        assert.error_contains(call_with_illegal_request_type, "Unknown Virtual Schema request type 'illegal' received.")
    end)

    it("wraps caught errors to log them", function()
        assert.has_error(call_with_illegal_request_type)
        assert.spy(log_mock.fatal).was.called_with([[F-RQD-1: Unknown Virtual Schema request type 'illegal' received.

Mitigations:

* This is an internal software error. Please report it via the project's ticket tracker.]])
    end)
end)
