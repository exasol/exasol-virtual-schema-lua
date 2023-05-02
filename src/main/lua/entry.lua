--- Main entry point of the Lua Virtual Schema adapter.
-- It is responsible for creating and wiring up the main adapter objects.
-- @script entry.lua

local ExasolAdapter = require("exasolvs.ExasolAdapter")
local ExasolAdapterProperties = require("exasolvs.ExasolAdapterProperties")
local MetadataReaderFactory = require("exasolvs.MetadataReaderFactory")
local QueryRewriterFactory = require("exasolvs.QueryRewriterFactory")
local RequestDispatcher = require("exasol.vscl.RequestDispatcher")

--- Handle a Virtual Schema request.
-- @param request_as_json JSON-encoded adapter request
-- @return JSON-encoded adapter response
function adapter_call(request_as_json)
    local exasol_context = _G.exa
    local metadata_reader_factory = MetadataReaderFactory:new(exasol_context)
    local query_rewriter_factory = QueryRewriterFactory:new()
    local adapter = ExasolAdapter:new(metadata_reader_factory, query_rewriter_factory)
    local dispatcher = RequestDispatcher:new(adapter, ExasolAdapterProperties)
    return dispatcher:adapter_call(request_as_json)
end
