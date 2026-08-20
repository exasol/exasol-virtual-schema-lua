---@meta exasol_virtual_schema_requests
local M = {}

---Pushdown request
---@class PushdownRequest
---@field type "pushdown"
---@field involvedTables PushdownInvolvedTable[]
---@field pushdownRequest SelectSqlStatement
---@field schemaMetadataInfo SchemaMetadataInfo
M.PushdownRequest = {}

---@class PushdownInvolvedTable
---@field name string
---@field adapterNotes string?
---@field columns PushdownInvolvedColumn[]
M.PushdownInvolvedTable = {}

---@class PushdownInvolvedColumn
---@field name string
---@field dataType ExasolTypeDefinition
M.PushdownInvolvedColumn = {}

---Schema metadata info in requests
---@class SchemaMetadataInfo
---@field name string virtual schema name
---@field adapterNotes string?
---@field properties table<string, string>
M.SchemaMetadataInfo = {}

return M
