--- This class implements a factory that constructs different metadata readers.
-- @classmod MetadataReaderFactory
local MetadataReaderFactory = {
    LOCAL = "LOCAL",
    REMOTE = "REMOTE"
}
MetadataReaderFactory.__index = MetadataReaderFactory

--- Create a new instance of a `MetadataReaderFactory`.
-- @param exasol_context script context through which the code of the script can access status information and local
--                       functions
-- @return new metadata reader factory
function MetadataReaderFactory:new(exasol_context)
    assert(exasol_context ~= nil,
            "Metadata reader factory requires an Exasol script context in order to create a reader.")
    local instance = setmetatable({}, self)
    instance:_init(exasol_context)
    return instance
end

function MetadataReaderFactory:_init(exasol_context)
    self._exasol_context = exasol_context
end

--- Create a metadata that reads the metadata from the local database.
-- @return local metadata reader
function MetadataReaderFactory:create_local_reader()
    return require("exasolvs.LocalMetadataReader"):new(self._exasol_context)
end

--- Create a metadata that reads the metadata from the local database.
-- @param connection_id name of the connection object that defines the connection to the remote data source
-- @return local metadata reader
function MetadataReaderFactory:create_remote_reader(connection_id)
    return require("exasolvs.RemoteMetadataReader"):new(self._exasol_context, connection_id)
end

return MetadataReaderFactory