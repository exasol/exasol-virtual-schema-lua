---@meta exasol_type_definitions
local M = {}

---@class DecimalTypeDefinition
---@field type "DECIMAL"
---@field precision integer
---@field scale integer
M.DecimalTypeDefinition = {}

---@class CharacterTypeDefinition
---@field type "VARCHAR"
---@field size integer
---@field characterSet string?
M.CharacterTypeDefinition = {}

---@class TimestampTypeDefinition
---@field type "TIMESTAMP"
---@field precision integer?
---@field withLocalTimeZone boolean?
M.TimestampTypeDefinition = {}

---@class GeometryTypeDefinition
---@field type "GEOMETRY"
---@field srid integer?
M.GeometryTypeDefinition = {}

---@class IntervalTypeDefinition
---@field type "INTERVAL"
---@field fromTo string
---@field precision integer?
---@field fraction integer?
M.IntervalTypeDefinition = {}

---@class HashtypeTypeDefinition
---@field type "HASHTYPE"
---@field bytesize integer?
M.HashtypeTypeDefinition = {}

---@class DoubleTypeDefinition
---@field type "DOUBLE"
---@field bytesize integer?
M.DoubleTypeDefinition = {}

---@class DateTypeDefinition
---@field type "DATE"
M.DateTypeDefinition = {}

---@class BooleanTypeDefinition
---@field type "BOOLEAN"
M.BooleanTypeDefinition = {}

-- luacheck: max line length 240
---@alias ExasolTypeDefinition DecimalTypeDefinition|CharacterTypeDefinition|TimestampTypeDefinition|GeometryTypeDefinition|IntervalTypeDefinition|HashtypeTypeDefinition|DoubleTypeDefinition|DateTypeDefinition|BooleanTypeDefinition

---@enum ExasolDataType
M.DATA_TYPES = {
    DECIMAL = "DECIMAL",
    DOUBLE = "DOUBLE",
    VARCHAR = "VARCHAR",
    CHAR = "CHAR",
    DATE = "DATE",
    TIMESTAMP = "TIMESTAMP",
    BOOLEAN = "BOOLEAN",
    GEOMETRY = "GEOMETRY",
    INTERVAL = "INTERVAL",
    HASHTYPE = "HASHTYPE"
}

---@enum ExasolObjectType
M.OBJECT_TYPES = {TABLE = "table"}

---@enum ExasolIntervalType
M.INTERVAL_TYPES = {DAY_TO_SECONDS = "DAY TO SECONDS", YEAR_TO_MONTH = "YEAR TO MONTH"}

return M
