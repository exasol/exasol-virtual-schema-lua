local reference_constructors = {}

function reference_constructors.column(table_name, column_name)
    return {type = "column", tableName = table_name, name = column_name}
end

return reference_constructors
