rockspec_format = "3.0"

local tag = "0.5.5"
local project = "exasol-virtual-schema-lua"
local src = "src/main/lua"

package = project
version = tag .. "-1"

source = {
    url = "git://github.com/exasol/" .. project,
    tag = tag
}

description = {
    summary = "Lua-based Virtual Schema for Exasol databases",
    detailed = [[This project adds a Virtual Schema (a concept closely related to a database view) on top of an existing
    Exasol database schema and makes it read-only.]],
    homepage = "https://github.com/exasol/" .. project,
    license = "MIT",
    maintainer = 'Exasol <opensource@exasol.com>'
}

dependencies = {
    "exasol-virtual-schema-common-lua = 1.0.2",
    "luasql-exasol = 0.2.0"
}

build_dependencies = {
    "amalg"
}

test_dependencies = {
    "busted >= 2.0.0",
    "luacheck >= 0.25.0",
    "luacov >= 0.15.0",
    "luacov-coveralls >= 0.2.3"
}

test = {
    type = "busted"
}

local package_items = {
    "exasol.evsl.adapter_capabilities",  "exasol.evsl.ExasolAdapter", "exasol.evsl.ExasolAdapterProperties",
    "exasol.evsl.MetadataReaderFactory", "exasol.evsl.RemoteMetadataReader", "exasol.evsl.ConnectionReader",
    "exasol.evsl.QueryRewriterFactory", "exasol.evsl.RemoteQueryRewriter",
    -- from remotelog
    "remotelog", "ExaError", "MessageExpander",
    -- from exasol-virtual-schema-common-lua
    "exasol.evscl.ExasolBaseAdapterProperties", "exasol.evscl.AbstractMetadataReader", "exasol.evscl.LocalMetadataReader",
    "exasol.evscl.AbstractQueryRewriter", "exasol.evscl.LocalQueryRewriter",
    -- from virtual-schema-common-lua"
    "exasol.vscl.AbstractVirtualSchemaAdapter", "exasol.vscl.AdapterProperties",
    "exasol.vscl.RequestDispatcher", "exasol.vscl.Query", "exasol.vscl.QueryRenderer",
    "exasol.vscl.queryrenderer.AbstractQueryAppender", "exasol.vscl.queryrenderer.ExpressionAppender",
    "exasol.vscl.queryrenderer.ImportAppender",
    "exasol.vscl.queryrenderer.ScalarFunctionAppender", "exasol.vscl.queryrenderer.AggregateFunctionAppender",
    "exasol.vscl.queryrenderer.SelectAppender", "exasol.vscl.ImportQueryBuilder",
    "exasol.vscl.text", "exasol.vscl.validator",
    -- driver dependencies
    "luasql.exasol", "luasql.exasol.Connection", "luasql.exasol.ConnectionProperties", "luasql.exasol.Cursor",
    "luasql.exasol.CursorData", "luasql.exasol.Environment", "luasql.exasol.ExasolWebsocket", "luasql.exasol.Websocket",
    "luasql.exasol.WebsocketDatahandler", "luasql.exasol.base64", "luasql.exasol.constants", "luasql.exasol.luws",
    "luasql.exasol.util"
}

local item_path_list = ""
for i = 1, #package_items do
    item_path_list = item_path_list .. " " .. package_items[i]
end

build = {
    type = "command",
    build_command = "mkdir -p target"
            .. " && cd " .. src
            .. " && amalg.lua "
            .. "--output=../../../target/exasol-virtual-schema-dist-" .. tag .. ".lua "
            .. "--script=entry.lua "
            .. item_path_list
}
