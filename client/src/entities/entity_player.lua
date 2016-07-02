local Entity = require("src/entities/entity.lua")

local EntityPlayer = {}
EntityPlayer.__index = EntityPlayer

setmetatable(EntityPlayer, {
    __index = Entity,
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

function EntityPlayer:_init(roomID, x, y, name)
    Entity._init(self, x, y)

    self.roomID = roomID
    self.name = name

    self.health = 5
    self.level = 1
    self.xp = 0
end

function EntityPlayer:getType()
    return "Player"
end

return EntityPlayer