package.path = "src/main/lua/?.lua;" .. package.path
require("busted.runner")()
local assert = require("luassert")
local mockagne = require("mockagne")

local ConnectionReader = require("exasolvs.ConnectionReader")

-- [[utest -> dsn~defining-the-remote-connection~0]]
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

    it("reads a connection definition with missing port (falls back to default port)", function()
        mock_get_connection("the_connection", "example.org", "joe", "test_password")
        local connection_definition = reader:read("the_connection")
        assert.are_same({host = "example.org", port = 8563, user = "joe", password = "test_password"},
                connection_definition)
    end)

    it("raises an error if the port is not numeric", function()
        mock_get_connection("non_numeric_port_connection", "example.org:non-numeric", nil)
        assert.error_matches(function() reader:read("non_numeric_port_connection") end,
                ".*Illegal source database port %(no a number%): 'non%-numeric'.*")
    end)

    describe("raises an error if the port is out of range:", function()
        for _, port_number in ipairs({-100, 0, 65536, 1000000}) do
            it(port_number, function()
                local connection_id = "port_" .. port_number .. "__connection"
                mock_get_connection(connection_id, "example.org:" .. port_number, "jane", "another_pwd")
                assert.error_matches(function() reader:read(connection_id) end,
                        ".*Source database port is out of range: [-]?" .. port_number .. ".*")
            end)
        end
    end)

    it("raises an error if the user is not a valid Exasol database object ID", function()
        local connection_id = "illegal_user_connection"
        mock_get_connection(connection_id, "192.168.1.1:4321", "foo\"bar", "super secret")
        assert.error_matches(function() reader:read(connection_id) end,
                ".*Invalid character in user name at position 4: 'foo\"bar'.*")
    end)
end)