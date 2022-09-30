--- This class implements a basic reader for information about the project, like reading the POM file.
-- Note that this module is not portable and only runs on machines with unix-style paths.
-- @classmod ProjectInspector
local ProjectInspector = {
    _artifact_version = nil,
    _artifact_id = nil
}

ProjectInspector.__index = ProjectInspector

local DEFAULT_POM_FILENAME <const> = "pom.xml"

--- Create a new instance of a `PomReader`.
-- @string path path to the POM file, or `nil` if POM file is in the default location
-- @return new instance
function ProjectInspector:new(path)
    path = path or self:get_default_pom_path()
    local instance = setmetatable({}, self)
    instance:_init(path)
    return instance
end

function ProjectInspector:_init(path)
    local pom = assert(io.open(path, "r"), "Failed to open POM: " .. path)
    repeat
        local line = pom:read("*l")
        self._artifact_version = string.match(line,"<version>%s*([0-9.]+)") or self._artifact_version
        self._artifact_id = string.match(line,"<artifactId>%s*([-.%w]+)") or self._artifact_id
    until (self._artifact_id and self._artifact_version) or (line == nil)
    pom:close()
    assert(self._artifact_id, "No artifact ID found in project's POM file")
    assert(self._artifact_version, "No artifact version found in project's POM file")
end

--- Get the base path of the project.
-- @path base path of the project
function ProjectInspector:get_project_base_path()
    return debug.getinfo(1,"S").source:sub(2):gsub("[^/]*$", "") .. ".."
end

--- Get the default path to the POM file.
-- @return path to default POM file
function ProjectInspector:get_default_pom_path()
    return self:get_project_base_path() .. "/" .. DEFAULT_POM_FILENAME
end

--- Get the artifact version.
-- @return version of the Maven artifact
function ProjectInspector:get_artifact_version()
    return self._artifact_version
end

--- Get the artifact ID.
-- ID of the Maven artifact
function ProjectInspector:get_artifact_id()
    return self._artifact_id
end

--- Check if a file exists in the given path relative to the project root
-- @return `true` if the file exists
function ProjectInspector:does_file_exist_in_path_relative_to_project_root(relative_path)
    local file =io.open(self.get_project_base_path() .. "/" .. relative_path, "r")
    if file == nil then
        return false
    else
        io.close(file) return true
    end
end

return ProjectInspector
