require("busted.runner")()
local ExasolAdapterProperties = require("exasol.evsl.ExasolAdapterProperties")

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
                },
                {
                    properties = {SCHEMA_NAME = "THE_SCHEMA", TABLE_FILTER = ""},
                    expected = "Table filter property 'TABLE_FILTER' must not be empty."
                },
                {
                    properties = {SCHEMA_NAME = "THE_SCHEMA", EXA_CONNECTION = "THE_CONNECTION",
                                  CONNECTION_NAME = "THE_CONNECTION"},
                    expected = "Properties 'CONNECTION_NAME' and 'EXA_CONNECTION' cannot be used in combination."
                }
            }
            for _, test in ipairs(tests) do
                it(test.expected, function()
                    local properties = ExasolAdapterProperties:new(test.properties)
                    assert.error_matches(function () properties:validate() end,  test.expected, 1, true)
                end)
            end
    end)

    it("gets the SCHEMA_NAME property", function()
        assert.is("a_schema", ExasolAdapterProperties:new({SCHEMA_NAME = "a_schema"}):get_schema_name())
    end)

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

    it("gets the name of the connection object", function()
        assert.are.same("the_connection",
                ExasolAdapterProperties:new({CONNECTION_NAME = "the_connection"}):get_connection_name())
    end)


    it("alternatively gets the name of the connection object from the EXA_CONNECTION property (backward-compatibility)",
            function()
                assert.are.same("the_exa_connection",
                        ExasolAdapterProperties:new({EXA_CONNECTION = "the_exa_connection"}):get_connection_name())
            end
    )

    it("can produce a string representation", function()
        local properties = ExasolAdapterProperties:new({a = 1, b = 2, c = 3})
        assert.are.equals("(a = 1, b = 2, c = 3)", tostring(properties))
    end)
end)