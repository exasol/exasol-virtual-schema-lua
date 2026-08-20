require("busted.runner")()
local text = require("exasol.vscl.text")

describe("text manipulation", function()
    it("starts with prefix", function()
        assert.is_true(text.starts_with("Hello world", "Hello"))
    end)

    describe("trim", function()
        it("trims away spaces in front", function()
            assert.are.same("front", text.trim(" front"))
        end)

        it("trims away spaces in the back", function()
            assert.are.same("back", text.trim(" back"))
        end)

        it("leaves spaces in the middle untouched", function()
            assert.are.same("middle space", text.trim("middle space"))
        end)
    end)

    describe("split", function()
        it("splits text at default delimiter (comma)", function()
            assert.are.same({"foo", "bar", "baz"}, text.split("foo,bar,baz"))
        end)

        it("ignores empty segments", function()
            assert.are.same({"foo", "bar", "baz"}, text.split("foo,,bar,baz"))
        end)

        it("ignores empty start", function()
            assert.are.same({"1", "2", "3"}, text.split(",1,2,3"))
        end)

        it("ignores padding with spaces", function()
            assert.are.same({"Hello", "world", "!"}, text.split(" Hello , world    , ! "))
        end)

        it("returns empty array given empty string", function()
            assert.are.same({}, text.split(""))
        end)

        it("returns nil given nil", function()
            assert.are.same(nil, text.split(nil))
        end)
    end)
end)
