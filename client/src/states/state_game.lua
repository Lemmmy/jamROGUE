local buffer = require("src/buffer.lua")
local constants = require("src/constants.lua")

local w, h = term.getSize()

local game = {}

function game.init(main)
    game.main = main

    game.sidebarScreen = 0
    game.onlineUsers = 0

    http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
end

function game.httpSuccess(url, response)
    if url == constants.server .. "game/poll" then
        local resp = json.decode(response.readAll())

        if resp.ok and resp.events then
            for _, event in ipairs(resp.events) do
                if game.events and game.events[event.type] then
                    game.events[event.type](event.data)
                end
            end
        end

        http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    end
end

function game.httpFailure(url)
    if url == constants.server .. "game/poll" then
        http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    end
end

function game.drawSidebar()
    buffer.setBackgroundColour(colours.grey)
    buffer.setTextColour(colours.black)

    for i = 1, h do
        buffer.setCursorPos(w - 19, i)
        buffer.write("\149")
        buffer.write((" "):rep(19))
    end

    buffer.setTextColour(colours.white)

    buffer.setCursorPos(w - 18, 1)
    buffer.write("\16")
    buffer.setCursorPos(w, 1)
    buffer.write("\17")

    buffer.setCursorPos(w - 17 + ((17 - #game.main.connection.name) / 2) + 1, 1)
    buffer.write(game.main.connection.name)

    local online = "Online: " .. game.onlineUsers
    buffer.setCursorPos(w - 17 + ((17 - #online) / 2) + 1, 2)
    buffer.write(online)

    buffer.setBackgroundColour(colours.black)
end

function game.drawHUD()
    game.drawSidebar()
end

function game.draw()
    game.drawHUD()
end

function game.updateOnlineUsers(data)
    game.onlineUsers = data
end

game.events = {
    online_users = game.updateOnlineUsers
}

return game