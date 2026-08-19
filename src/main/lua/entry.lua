-- The Lua package searcher below is required to add a missing Lua loader feature to Exasol.
-- This allows running the amalgamated Lua package (i.e., a stand-alone single-file package)
table.insert(package.searchers,
    function (module_name)
        local loader = package.preload[module_name]
        if(loader == nil) then
            error("Module " .. module_name .. " not found in package.preload. "
                .. " The module is either not present in the installation package or the name is misspelled."
                .. "\nThis is a bug. Please file a GitHub issue with the full error message and package version.")
        else
            return loader
        end
    end
)

--- Main entry point of the Lua Virtual Schema adapter.
-- It is responsible for creating and wiring up the main adapter objects.
-- @script entry.lua

local ExasolAdapter = require("exasol.evsl.ExasolAdapter")
local ExasolAdapterProperties = require("exasol.evsl.ExasolAdapterProperties")
local MetadataReaderFactory = require("exasol.evsl.MetadataReaderFactory")
local QueryRewriterFactory = require("exasol.evsl.QueryRewriterFactory")
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
