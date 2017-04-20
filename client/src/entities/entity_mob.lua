local Entity = require("src/entities/entity.lua")
local constants = require("src/constants.lua")

local EntityMob = {}
EntityMob.__index = EntityMob

setmetatable(EntityMob, {
    __index = Entity,
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

function EntityMob:_init(id, x, y, type)
    Entity._init(self, x, y)

    self.id = id
    self.type = type
end

function EntityMob:getType()
    return "BaseMob"
end

function EntityMob:inspect(token)
    http.request(constants.server .. "game/entity/" .. textutils.urlEncode(self.id) .. "/inspect", "token=" .. textutils.urlEncode(token))
end

function EntityMob:interact(token)
    http.request(constants.server .. "game/entity/" .. textutils.urlEncode(self.id) .. "/interact", "token=" .. textutils.urlEncode(token))
end

function EntityMob:getSymbol()
    local symbol = constants.mobs[self.type] and constants.mobs[self.type].symbol
    if type(symbol) == "string" then
        return symbol
    elseif type(symbol) == "table" then
        return symbol[math.floor(os.clock()) % #symbol + 1]
    else
        return "\164"
    end
end

function EntityMob:getColour()
    return (constants.mobs[self.type] and constants.mobs[self.type].colour) or colours.red
end

return EntityMob