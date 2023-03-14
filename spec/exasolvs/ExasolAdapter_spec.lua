package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local assert = require("luassert")
local mockagne = require("mockagne")
local adapter_capabilities = require("exasolvs.adapter_capabilities")
local RlsAdapter = require("exasolvs.ExasolAdapter")
require("exasolvs.ExasolAdapterProperties")
local PomReader = require("spec.PomReader")
local pom = PomReader:new()

describe("ExasolAdapter", function()
    local adapter
    local local_metadata_reader_mock
    local remote_metadata_reader_mock
    local properties_stub

    before_each(function()
        local_metadata_reader_mock = mockagne.getMock("local metadata reader mock")
        remote_metadata_reader_mock = mockagne.getMock("remote metadata reader mock")
        local metadata_reader_factory_mock = {
            create_local_reader = function() return local_metadata_reader_mock end,
            create_remote_reader = function() return remote_metadata_reader_mock end
        }
        adapter = RlsAdapter:new(metadata_reader_factory_mock)
        properties_stub = {
            get_table_filter = function() return {} end,
            has_excluded_capabilities = function() return false end
        }
    end)

    it("has the same version number as the project in the Maven POM file", function()
        assert.are.equal(pom:get_artifact_version(), adapter:get_version())
    end)

    it("reports the name of the adapter", function()
        assert.are.equal("Exasol Virtual Schema adapter (Lua)", adapter:get_name())
    end)

    it("answers a request to create a local Virtual Schema with the metadata of the source schema"
            .. " [utest -> dsn~creating-a-local-virtual-schema~0]", function()
        local schema_metadata = {
            tables = {
                {type = "table", name = "T1", columns = {{name = "C1", dataType = {type = "BOOLEAN"}}}}
            }
        }
        mockagne.when(local_metadata_reader_mock:read("S", {})).thenAnswer(schema_metadata)
        local expected = {type = "createVirtualSchema", schemaMetadata = schema_metadata}
        local request = {schemaMetadataInfo = {name = "V"}}
        properties_stub.validate = function()  end
        properties_stub.get_schema_name = function() return "S" end
        properties_stub.get_connection_name = function() return nil end
        local actual = adapter:create_virtual_schema(request, properties_stub)
        assert.are.same(expected, actual)
    end)

    it("confirms a request to drop the Virtual Schema with an empty response"
            .. "[utest -> dsn~dropping-a-virtual-schema~0]", function()
        assert.are.same({type = "dropVirtualSchema"}, adapter:drop_virtual_schema())
    end)

    it("reports the supported capabilities [utest -> dsn~getting-the-supported-capabilities~0]", function()
        local request = {}
        local expected = {type = "getCapabilities", capabilities = adapter_capabilities}
        local actual = adapter:get_capabilities(request, properties_stub)
        assert.are.same(expected, actual)
    end)

    it("raises an error if the SCHEMA parameter is missing when trying to create a Virtual Schema", function()
        properties_stub.validate = function() error("validation failed") end
        local request = {schemaMetadataInfo = {name = "V"}}
        assert.error_matches(function() adapter:create_virtual_schema(request, properties_stub) end,
                "validation failed")
    end)

    it("Uses a remote metadata reader when a connection parameter is specified"
            .. " [utest -> dsn~creating-a-remote-virtual-schema~0]", function()
        local schema_metadata = {
            tables = {
                {type = "table", name = "T2", columns = {{name = "C2", dataType = {type = "BOOLEAN"}}}}
            }
        }
        mockagne.when(remote_metadata_reader_mock:read("S", {})).thenAnswer(schema_metadata)
        local expected = {type = "createVirtualSchema", schemaMetadata = schema_metadata}
        local request = {schemaMetadataInfo = {name = "V"}}
        properties_stub.validate = function()  end
        properties_stub.get_schema_name = function() return "S" end
        properties_stub.get_connection_name = function () return "C" end
        local actual = adapter:create_virtual_schema(request, properties_stub)
        assert.are.same(expected, actual)
    end)
end)