file = "src/main/lua"
project = "Exasol Virtual Schema Lua Reference"
title = "Exasol Virtual Schema Lua Reference"
dir = "/tmp/ldoc_out"
prettify_files = true
backtick_references = true
custom_tags = {
    {
        "cover",
         title = "Covers Requirements",
         hidden = false,
         format = function (item)
            local covering_artifact_type, covered = item:match(" *%[ *(%w+) *-> *([%-%w~]+)")
            return "<li><code>" .. covered .. "</code> (" .. covering_artifact_type .. ")" .. "</li>"
         end
    }
}