package.path = "target/?.lua;" .. package.path
require("busted.runner")()
local Reader = require("PomReader")

local pom = Reader:new()

local VERSION <const> = pom:get_artifact_version()
local DISTRIBUTION_NAME <const> = "exasol-virtual-schema" -- note that we don't add the `-lua` suffix here.
local DISTRIBUTION_MODULE <const> = DISTRIBUTION_NAME .. "-dist"
local DISTRIBUTION_PATH = "target"

local function load_distribution()
    local filename = DISTRIBUTION_MODULE .. "-" .. VERSION .. ".lua"
    local path = DISTRIBUTION_PATH .. "/" .. filename
    print("Loading distribution module from " .. path)
    local file <close> = io.open(path, "rb")
    if file then
        local content = assert(file:read("*a"))
        load(content, DISTRIBUTION_MODULE)()
        return true
    else
        return false
    end
end


if load_distribution() then
    describe("Distribution (smoke test)", function()
        local exasol_context_stub = {
            pquery_no_preprocessing = function(query)
                if string.find(query, "EXA_ALL_TABLES", 1, true) then
                    return true, {{TABLE_NAME = "T"}}
                else
                    return true, {{COLUMN_NAME = "C", COLUMN_TYPE = "BOOLEAN"}}
                end
            end
        }

        it("handles an adapter call to drop the virtual schema", function()
            _G.exa = exasol_context_stub
            finally(function() _G.exa = nil end)
            local result = _G.adapter_call([[{"type" : "dropVirtualSchema"}]])
            assert.are.equal([[{"type":"dropVirtualSchema"}]], result)
        end)

        it("handles an adapter call to create the virtual schema", function()
            _G.exa = exasol_context_stub
            finally(function() _G.exa = nil end)
            local result = _G.adapter_call(
                    [[{"type" : "createVirtualSchema",
                         "schemaMetadataInfo" : {
                            "properties" : {"SCHEMA_NAME" : "S"}
                         }
                    }]])
            assert.are.matches('"type" *: *"createVirtualSchema"', result)
        end)
    end)
else
    print("Skipped smoke test because distribution file does not exist (yet). Please build first.")
end
