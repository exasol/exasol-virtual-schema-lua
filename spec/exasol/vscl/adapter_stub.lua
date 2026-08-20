local AbstractVirtualSchemaAdapter = require("exasol.vscl.AbstractVirtualSchemaAdapter")

--- This module creates a stub to test an `AbstractVirtualSchemaAdapter`.
-- Configure the behavior by injecting methods via the prototype.
local adapter_stub = {}

function adapter_stub.create(prototype)
    local AdapterStub = prototype or {}
    setmetatable(AdapterStub, {__index = AbstractVirtualSchemaAdapter})
    AdapterStub.__index = AdapterStub

    function AdapterStub:new()
        local instance = setmetatable({}, self)
        instance:_init()
        return instance
    end

    function AdapterStub:_init()
        AbstractVirtualSchemaAdapter._init(self)
    end

    return AdapterStub
end

return adapter_stub
