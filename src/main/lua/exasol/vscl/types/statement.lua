---@meta exasol_statements
local M = {}

---@class SelectSqlStatement
---@field type "select"|"sub_select"
---@field selectList SelectList[]?
---@field from FromClause
---@field filter PredicateExpression?
---@field groupBy Expression[]?
---@field aggregationType ("single_group"|string)?
---@field having any?
---@field orderBy OrderByClause[]?
---@field limit any?
---@field selectListDataTypes ExasolTypeDefinition[]
M.SelectSqlStatement = {}

---@alias FromClause TableExpression|JoinExpression

M.FromClause = {}

---@class OrderByClause
---@field expression Expression
---@field isAscending boolean?
---@field nullsLast boolean?
M.OrderByClause = {}

---@class LimitClause
---@field numElements integer
---@field offset integer?
M.LimitClause = {}

---@class TableExpression
---@field type "table"
---@field catalog string? Optional catalog. Not used in Exasol useful for other databases that use catalogs.
---@field schema string?
---@field name string
M.TableExpression = {}

---@class JoinExpression
---@field type "join"
---@field join_type "inner" | "left_outer" | "right_outer" | "full_outer"
---@field left TableExpression
---@field right TableExpression
---@field condition Expression
M.JoinExpression = {}

---@class ScalarFunctionExpression
---@field name string
M.ScalarFunctionExpression = {}

---@class AggregateFunctionExpression
---@field name string
M.AggregateFunctionExpression = {}

---@alias SelectList Expression[]

---The ImportSqlStatement is a record (behavior-less table) that contains the structure of an `IMPORT` SQL statement.
---@class ImportSqlStatement
---@field type "import"
---@field into ExasolTypeDefinition[]
---@field source_type SourceType
---@field connection string
---@field statement SelectSqlStatement
M.ImportSqlStatement = {}

---@alias QueryStatement SelectSqlStatement|ImportSqlStatement

return M
