---@meta exasol_virtual_schema_requests
local M = {}

---Response for a createVirtualSchema request
---@class CreateVirtualSchemaResponse
---@field type "createVirtualSchema"
---@field schemaMetadata ExasolSchemaMetadata
M.CreateVirtualSchemaResponse = {}

---Response for a refresh request
---@class RefreshVirtualSchemaResponse
---@field type "refresh"
---@field schemaMetadata ExasolSchemaMetadata
M.RefreshVirtualSchemaResponse = {}

---Response for a set properties request
---@class SetPropertiesResponse
---@field type "setProperties"
---@field schemaMetadata ExasolSchemaMetadata
M.SetPropertiesResponse = {}

---Response for a createVirtualSchema request
---@class ExasolSchemaMetadata
---@field tables ExasolTableMetadata[] The tables in the virtual schema.
---@field adapterNotes? string Notes for the virtual schema adapter.
M.ExasolSchemaMetadata = {}

---@class ExasolColumnMetadata
---@field name string Name of the column
---@field adapterNotes string? Notes for the table adapter
---@field dataType ExasolTypeDefinition Data type of the column
---@field isNullable boolean?  Whether the column is nullable (default: true)
---@field isIdentity boolean?  Whether the column is an identity column (default: false)
---@field default string? Default value for the column
---@field comment string? Comment for the column
M.ExasolColumnMetadata = {}

---@class ExasolTableMetadata
---@field type ExasolObjectType Object type, e.g. `table`
---@field name string Name of the table
---@field adapterNotes string? Notes for the table adapter
---@field comment string? Comment for the table
---@field columns ExasolColumnMetadata[] Columns in the table
M.ExasolTableMetadata = {}

---Response for a pushdown request
---@class PushdownResponse
---@field type "pushdown"
---@field sql string The SQL statement to be executed in the remote system.
M.PushdownResponse = {}

return M
