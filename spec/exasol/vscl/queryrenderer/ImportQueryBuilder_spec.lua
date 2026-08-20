require("busted.runner")()
local ImportQueryBuilder = require("exasol.vscl.ImportQueryBuilder")

describe("ImportQueryBuilder", function()
    it("wraps a SELECT query", function()
        local wrapped_query = ImportQueryBuilder:new():connection("CA"):statement({type = "select"}):build()
        assert.are.same({type = "import", source_type = "EXA", connection = "CA", statement = {type = "select"}},
                        wrapped_query)
    end)

    it("wraps a SELECT query with result set column types", function()
        local wrapped_query = ImportQueryBuilder:new():connection("CB"):statement({type = "select"}):column_types({
            {type = "VARCHAR"}
        }):build()
        assert.are.same({
            type = "import",
            source_type = "EXA",
            into = {{type = "VARCHAR"}},
            connection = "CB",
            statement = {type = "select"}
        }, wrapped_query)
    end)

    it("uses EXA source type by default", function()
        local wrapped_query = ImportQueryBuilder:new():connection("CB"):statement({type = "select"}):column_types({
            {type = "VARCHAR"}
        }):build()
        assert.are.same("EXA", wrapped_query.source_type)
    end)

    it("allows using custom source type", function()
        local wrapped_query = ImportQueryBuilder:new():source_type("JDBC"):connection("CB"):statement({type = "select"})
                :column_types({{type = "VARCHAR"}}):build()
        assert.are.same("JDBC", wrapped_query.source_type)
    end)
end)
