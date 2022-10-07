
package.path = "spec/?.lua;" .. package.path
require("busted.runner")()
local Reader = require("PomReader")

local pom = Reader:new()
local ROCKSPEC_PATH <const> = pom:get_project_base_path() .. "/"
            .. (string.format("%s-%s-1.rockspec", pom:get_artifact_id(), pom:get_artifact_version()))


describe("Build precondition", function()
    describe("Rockspec file", function()
        -- We load the rockspec as part of a test, so that we get proper test failures if it is not present.
        local rockspec;

        it("exists under the expected path '" .. ROCKSPEC_PATH .. "'", function()
            -- We need an extra function for loading the rockspec as isolation for the environment.
            local function load_rockspec(path)
                local env = {}
                local rockspec_function = assert(loadfile(path, "t", env), "Rockspec is expected under '"
                        .. ROCKSPEC_PATH .. "'")
                rockspec_function()
                return env
            end
            rockspec = load_rockspec(ROCKSPEC_PATH)
        end)

        local function assume_rockspec_present()
            assert(rockspec, "Failing test because precondition not met: rockspec file not present.")
        end

        -- The following tests have no chance of succeeding if the rockspec was not loaded.
        describe("version field", function()
            it("is of type string", function()
                assume_rockspec_present()
                assert.is.same("string", type(rockspec.version))
            end)

            it("starts with the same version number as the main artifact in the Maven POM file", function()
                assume_rockspec_present()
                assert.matches(pom:get_artifact_version() .. "%-%d+", rockspec.version)
            end)
        end)
    end)
end)
