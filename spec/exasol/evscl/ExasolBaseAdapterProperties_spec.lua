require("busted.runner")()
local ExasolAdapterProperties = require("exasol.evscl.ExasolBaseAdapterProperties")

describe("adapter_properties", function()
    describe("validates property rule:", function()
            local tests = {
                {
                    properties = {},
                    expected = "Missing mandatory property 'SCHEMA_NAME'.",
                },
                {
                    properties = {SCHEMA_NAME = ""},
                    expected = "Missing mandatory property 'SCHEMA_NAME'.",
                }
            }
            for _, test in ipairs(tests) do
                it(test.expected, function()
                    local properties = ExasolAdapterProperties:new(test.properties)
                    assert.error_matches(function () properties:validate() end,  test.expected, 1, true)
                end)
            end
    end)

    -- [utest -> dsn~schema-name-property~0]
    it("gets the SCHEMA_NAME property", function()
        assert.is("a_schema", ExasolAdapterProperties:new({SCHEMA_NAME = "a_schema"}):get_schema_name())
    end)

    -- [utest -> dsn~table-filter-property~0]
    describe("get the TABLE_FILTER property:", function()
        local tests = {
            {
                filter = "TA, TB, TC",
                expected = {"TA", "TB", "TC"}
            },
            {
                filter = " T1 ,T2,  T3 \t,T4 ",
                expected = {"T1", "T2", "T3", "T4"}
            },
            {
                filter = "T1 T2, T3",
                expected = {"T1 T2", "T3"}
            },
            {
                filter = "",
                expected = {}
            },
            {
                filter = nil,
                expected = nil
            }
        }
        for _, test in ipairs(tests) do
            it("filter: " .. (test.filter or '<nil>'), function()
                assert.are.same(test.expected,
                        ExasolAdapterProperties:new({TABLE_FILTER = test.filter}):get_table_filter())
            end)
        end
    end)

    it("can produce a string representation", function()
        local properties = ExasolAdapterProperties:new({a = 1, b = 2, c = 3})
        assert.are.equals("(a = 1, b = 2, c = 3)", tostring(properties))
    end)
end)