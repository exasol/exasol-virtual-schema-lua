package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()

local validator = require("exasol.validator")
describe("validator", function()
    describe("raises an error if an ID is not a valid Exasol database object ID: ", function()
        for _, test in ipairs({
            {"foo\"bar", 4},
            {"1_starts_with_a_number", 1}
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

    it("raises an error if an ID is longer than 128 unicode characters", function()
        local id = "id_" .. string.rep(utf8.char(0xB7), "126")
        assert.error_matches(function() validator.validate_user(id) end,
                "Identifier too long: user name with 129 characters")
    end)

    it("raises an error if an ID is nil", function()
        assert.error_matches(function() validator.validate_user(nil) end,
                ".*Identifier cannot be null %(or Lua nil%): user name.*"
        )
    end)
end)
