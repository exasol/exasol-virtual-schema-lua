
package.path = "spec/?.lua;" .. package.path
require("busted.runner")()
local Reader = require("PomReader")

local pom = Reader:new()

local function get_rockspec_path() --
    return pom:get_project_base_path() .. "/"
            .. (string.format("%s-%s-1.rockspec", pom:get_artifact_id(), pom:get_artifact_version()))
end

local function load_rockspec(path)
    local env = {}
    local rockspec_function = assert(loadfile(path, "t", env))
    rockspec_function()
    return env
end

local rockspec = load_rockspec(get_rockspec_path())

describe("Build precondition", function()
    describe("Rockspec file", function()
        it("has correct filename", function()
            local rockspec_path = get_rockspec_path()
            local file = io.open(rockspec_path, "r")
            finally(function()
                if file then file:close() end
            end)
            assert(file, "Expected rockspec to have filename " .. rockspec_path .. " but file not found.")
        end)

        describe("version field", function()
            it("is of type string", function()
                assert.is.same("string", type(rockspec.version))
            end)

            it("starts with the same version number as the main artifact in the Maven POM file", function()
                assert.matches(pom:get_artifact_version() .. "%-%d+", rockspec.version)
            end)
        end)
    end)
end)