local Entity = {}
Entity.__index = Entity

setmetatable(Entity, {
    __call = function(cls, ...)
        local self = setmetatable({}, Entity)
        self:_init(...)
        return self
    end,
})

function Entity:_init(x, y)
    self.x = x
    self.y = y
end

function Entity:getType()
    return "Base"
end

return Entity