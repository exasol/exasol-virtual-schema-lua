package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()

local validator = require("exasol.validator")
describe("validator", function()
    describe("allow compliant user (in place of all database object IDs)", function()
        for _, id in ipairs({"a", "a1", "a1A", "a_1", "a__", "A", "Aa", "A·", "B·b", "C·_·c_·"}) do
            it(id, function()
                assert.has_no_errors(function()
                    validator.validate_user(id)
                end)
            end)
        end
    end)

    describe("raises an error if a value is not a valid Exasol user (in place of all database object IDs): ", function()
        for _, test in ipairs({
            {"foo\"bar", 4},
            {"Do_not_allow_'single_quotes'", 14},
            {"No spaces", 3},
            {"1_starts_with_a_number", 1},
            {"_starts_with_an_underscore", 1},
            {"·_starts_with_a_middle_dot_utf8_character", 1}
        }) do
            local id = test[1]
            local first_illegal_character = test[2]
            it(id, function()
                assert.error_matches(function() validator.validate_user(id) end,
                        ".*Invalid character in user name at position " .. first_illegal_character .. ": '" .. id
                                .. "'.*")
            end)
        end
    end)

    it("raises an error if a user (ID) is longer than 128 unicode characters", function()
        local id = "id_" .. string.rep(utf8.char(0xB7), "126")
        assert.error_matches(function() validator.validate_user(id) end,
                "Identifier too long: user name with 129 characters")
    end)

    it("raises an error if a user (ID) is nil", function()
        assert.error_matches(function() validator.validate_user(nil) end,
                ".*Identifier cannot be null %(or Lua nil%): user name.*"
        )
    end)
end)
