local log = require("remotelog")

--- This class implements a factory that constructs different query rewriters.
-- @classmod QueryRewriterFactory
local QueryRewriterFactory = {}
QueryRewriterFactory.__index = QueryRewriterFactory

--- Create a new instance of a `QueryRewriterFactory`.
-- @return new query rewriter factory
function QueryRewriterFactory:new()
    local instance = setmetatable({}, self)
    return instance
end

--- Create a query rewriter that produces local or remote queries.
-- Depending on whether a remote connection is supplied or not creates either a rewriter that produces an `IMPORT`
-- statement (remote) or a `SELECT` statement (local).
-- @param connection_id optional connection object name
-- @return local query rewriter
function QueryRewriterFactory:create_rewriter(connection_id)
    if connection_id then
        log.debug("Creating remote query rewriter (IMPORT) for connection '%s'.", connection_id)
        return require("exasol.evsl.RemoteQueryRewriter"):new(connection_id)
    else
        log.debug("No connection specified by user. Creating local query rewriter (SELECT).")
        return require("exasol.evscl.LocalQueryRewriter"):new()
    end
end

return QueryRewriterFactory