local Entity = require("src/entities/entity.lua")
local constants = require("src/constants.lua")

local EntityChest = {}
EntityChest.__index = EntityChest

setmetatable(EntityChest, {
    __index = Entity,
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

function EntityChest:_init(id, x, y, locked)
    Entity._init(self, x, y)

    self.id = id
    self.locked = locked
end

function EntityChest:getType()
    return "Chest"
end

function EntityChest:inspect(token)
    http.request(constants.server .. "game/entity/" .. textutils.urlEncode(self.id) .. "/inspect", "token=" .. textutils.urlEncode(token))
end

function EntityChest:interact(token)
    http.request(constants.server .. "game/entity/" .. textutils.urlEncode(self.id) .. "/interact", "token=" .. textutils.urlEncode(token))
end

function EntityChest:getSymbol()
    return "\1"
end

function EntityChest:getColour()
    return self.locked and colours.orange or colours.brown
end

return EntityChest