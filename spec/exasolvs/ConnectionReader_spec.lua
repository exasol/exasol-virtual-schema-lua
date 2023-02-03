package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local assert = require("luassert")
local mockagne = require("mockagne")

local ConnectionReader = require("exasolvs.ConnectionReader")

describe("ConnectionReader", function()
    local exa_mock
    local reader

    before_each(function()
        exa_mock = mockagne.getMock()
        reader = ConnectionReader:new(exa_mock)
    end)

    local function mock_get_connection(connection_id, address, user, password)
        mockagne.when(exa_mock.get_connection(connection_id))
                .thenAnswer({address = address, user = user, password = password})
    end

    it("reads a connection definition with host, port, user and password", function()
        mock_get_connection("the_connection", "example.org:1234", "joe", "test_password")
        local connection_definition = reader:read("the_connection")
        assert.are_same({host = "example.org", port = 1234, user = "joe", password = "test_password"},
                connection_definition)
    end)
end)