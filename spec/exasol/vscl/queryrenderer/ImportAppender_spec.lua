package.path = "src/?.lua;" .. package.path
require("busted.runner")()
require("assertions.appender_assertions")
local ImportAppender = require("exasol.vscl.queryrenderer.ImportAppender")

local function assert_yields(expected, original_query)
    assert.append_yields(ImportAppender, expected, original_query)
end

describe("ImportAppender", function()
    it("renders minimal IMPORT", function()
        local original_query = {
            type = "import",
            connection = "CON1",
            statement = {type = "select", from = {type = "table", name = "T1"}}
        }
        assert_yields([[IMPORT FROM EXA AT "CON1" STATEMENT 'SELECT * FROM "T1"']], original_query)
    end)

    it("renders IMPORT with source type JDBC", function()
        local original_query = {
            type = "import",
            source_type = "JDBC",
            connection = "CON1",
            statement = {type = "select", from = {type = "table", name = "T1"}}
        }
        assert_yields([[IMPORT FROM JDBC AT "CON1" STATEMENT 'SELECT * FROM "T1"']], original_query)
    end)

    it("renders an IMPORT with select list data types", function()
        local original_query = {
            type = "import",
            connection = "CON1",
            statement = {type = "select", from = {type = "table", name = "T2"}},
            into = {{size = 10, type = "VARCHAR"}, {type = "BOOLEAN"}}
        }
        assert_yields([[IMPORT INTO (c1 VARCHAR(10), c2 BOOLEAN) FROM EXA AT "CON1" STATEMENT 'SELECT * FROM "T2"']],
                      original_query)
    end)

    it("renders an IMPORT with escaped quotes", function()
        local original_query = {
            type = "import",
            connection = "CON1",
            statement = {
                type = "select",
                selectList = {{type = "literal_string", value = "a_text"}},
                from = {type = "table", name = "T1"}
            }
        }
        assert_yields([[IMPORT FROM EXA AT "CON1" STATEMENT 'SELECT ''a_text'' FROM "T1"']], original_query)
    end)
end)
