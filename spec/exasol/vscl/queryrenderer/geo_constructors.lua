local geo_constructors = {}

function geo_constructors.point(x, y)
    return string.format("POINT (%d %d)", x, y)
end

local function list_pairs(arguments)
    local pairs = {}
    for i = 1, #arguments, 2 do
        if i > 1 then
            table.insert(pairs, ", ")
        end
        table.insert(pairs, arguments[i])
        table.insert(pairs, " ")
        table.insert(pairs, arguments[i + 1])
    end
    return table.concat(pairs)
end

function geo_constructors.linestring(...)
    return "LINESTRING (" .. list_pairs(table.pack(...)) .. ")"
end

function geo_constructors.polygon(...)
    local polygon = "POLYGON ("
    for i, definition in ipairs(table.pack(...)) do
        if i > 1 then
            polygon = polygon .. ", "
        end
        polygon = polygon .. "(" .. list_pairs(definition) .. ")"
    end
    return polygon .. ")"
end

function geo_constructors.collection(...)
    local geometries = "GEOMETRYCOLLECTION ("
    for i, geometry in ipairs(table.pack(...)) do
        if i > 1 then
            geometries = geometries .. ", "
        end
        geometries = geometries .. geometry
    end
    return geometries .. ")"
end

return geo_constructors
