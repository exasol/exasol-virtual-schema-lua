package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
require("entry")

describe("Entry script", function()
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
        local result = _G.adapter_call([[{"type" : "dropVirtualSchema"}]], exasol_context_stub)
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
                }]], exasol_context_stub)
        assert.are.matches('"type" *: *"createVirtualSchema"', result)
    end)
end)