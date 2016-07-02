local Entity = require("src/entities/entity.lua")
local constants = require("src/constants.lua")

local EntityDroppedItem = {}
EntityDroppedItem.__index = EntityDroppedItem

setmetatable(EntityDroppedItem, {
    __index = Entity,
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

function EntityDroppedItem:_init(id, x, y, item)
    Entity._init(self, x, y)

    self.id = id
    self.item = item
end

function EntityDroppedItem:getType()
    return "DroppedItem"
end

function EntityDroppedItem:inspect(token)
    http.request(constants.server .. "game/entity/" .. textutils.urlEncode(self.id) .. "/inspect", "token=" .. textutils.urlEncode(token))
end

function EntityDroppedItem:interact(token)
    http.request(constants.server .. "game/entity/" .. textutils.urlEncode(self.id) .. "/interact", "token=" .. textutils.urlEncode(token))
end

function EntityDroppedItem:getSymbol()
    if self.item and self.item.name then
        if self.item.name == "Rock" then
            return "\4"
        elseif self.item.name == "Pebble" then
            return "\7"
        elseif self.item.name == "Apple" then
            return "\211"
        end
    end

    return "\42"
end

function EntityDroppedItem:getColour()
    if self.item and self.item.name then
        if self.item.name == "Rock" then
            return colours.grey
        elseif self.item.name == "Pebble" then
            return colours.lightGrey
        elseif self.item.name == "Apple" then
            return colours.red
        end
    end

    return colours.white
end

return EntityDroppedItem