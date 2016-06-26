local buffer = require("src/buffer.lua")
local constants = require("src/constants.lua")
local Player = require("src/entities/entity_player.lua")

local w, h = term.getSize()

local game = {}

function game.init(main)
    game.main = main

    game.sidebarScreen = 0
    game.sidebarMenuShowing = false

    game.onlineUsers = 0
    game.log = {}

    game.logWindow = window.create(buffer, 1, h - 3, w - 20, 4, true)

    game.lastPollTime = os.clock()
    http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    http.request(constants.server .. "map.json")
end

function game.print(text)
    game.log[#game.log + 1] = text

    if #game.log > 4 then
        table.remove(game.log, 1)
    end
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

        game.lastPollTime = os.clock()
        http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    elseif url == constants.server .. "map.json" then
        game.rooms = json.decode(response.readAll()).rooms
    end
end

function game.httpFailure(url)
    if url == constants.server .. "game/poll" then
        game.lastPollTime = os.clock()
        http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    end
end

function game.draw()
    game.drawHUD()
    game.drawGame()
end

function game.drawHUD()
    game.drawSidebar()
    game.drawLog()
end

function game.drawSidebar()
    buffer.setBackgroundColour(colours.blue)
    buffer.setTextColour(colours.black)

    for i = 1, h do
        if i == 3 then buffer.setBackgroundColour(colours.lightGrey) end
        if i == 4 then buffer.setBackgroundColour(colours.grey) end

        buffer.setCursorPos(w - 19, i)
        buffer.write("\149")
        buffer.write((" "):rep(19))
    end

    buffer.setTextColour(colours.white)
    buffer.setBackgroundColour(colours.blue)

    buffer.setCursorPos(w - 18, 1)
    buffer.write("\187")
    buffer.setCursorPos(w, 1)
    buffer.write("\171")

    buffer.setCursorPos(w - 17 + ((17 - #game.main.connection.name) / 2) + 1, 1)
    buffer.write(game.main.connection.name)

    local online = "Online: " .. game.onlineUsers
    buffer.setCursorPos(w - 17 + ((17 - #online) / 2), 2)
    buffer.write(online)

    if game.sidebarScreen == 0 then
        game.drawSidebarInfo()
    elseif game.sidebarScreen == 1 then
        game.drawSidebarMenu()
    end

    buffer.setBackgroundColour(colours.lightGrey)
    buffer.setCursorPos(w - 18, 3)
    buffer.write("Info")
    buffer.setCursorPos(w, 3)
    buffer.write(game.sidebarMenuShowing and "\30" or "\31")

    if game.sidebarMenuShowing then
        buffer.setBackgroundColour(colours.white)
        buffer.setTextColour(colours.black)
        buffer.setCursorPos(w - 19, 4)
        buffer.write("\149")
        buffer.write((" "):rep(19))
        buffer.setCursorPos(w - 18, 4)
        buffer.write("Info")

        buffer.setCursorPos(w - 19, 5)
        buffer.write("\149")
        buffer.write((" "):rep(19))
        buffer.setCursorPos(w - 18, 5)
        buffer.write("Menu")
    end

    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.white)
end

function game.drawSidebarInfo()
end

function game.drawSidebarMenu()
    buffer.setBackgroundColour(colours.red)
    buffer.setTextColour(colours.white)
    buffer.setCursorPos(w - 18, h - 1)
    buffer.write((" "):rep(18))
    buffer.setCursorPos(w - 17 + ((17 - #"Quit") / 2) + 1, h - 1)
    buffer.write("Quit")
    buffer.setBackgroundColour(colours.grey)
    buffer.setTextColour(colours.red)
    buffer.setCursorPos(w, h - 1)
    buffer.write("\149")
    buffer.setTextColour(colours.white)
end

local function worldToViewportPos(x, y)
    return x - game.viewportCenterX + 2 + game.viewportWidth / 2, y - game.viewportCenterY + 2 + game.viewportHeight / 2
end

function game.drawGame()
    game.drawWindowBorder()
    game.drawRooms()
    game.drawEntities()
end

function game.drawWindowBorder()
    buffer.setCursorPos(1, 1)
    buffer.write("\7")
    buffer.write(("\45"):rep(w - 22))
    buffer.write("\7")
    buffer.setCursorPos(1, h - 4)
    buffer.write("\7")
    buffer.write(("\45"):rep(w - 22))
    buffer.write("\7")

    for i = 2, h - 5 do
        buffer.setCursorPos(1, i)
        buffer.write("\124")
        buffer.setCursorPos(w - 20, i)
        buffer.write("\124")
    end

    local room = (game.main.connection.room and game.main.connection.room.name or "Loading")
    local a = "[ " .. (" "):rep(#room) .. " ]"
    buffer.setCursorPos(((w - 17) - #a) / 2, 1)
    buffer.write(a)

    buffer.setTextColour(colours.lightBlue)
    buffer.setCursorPos(((w - 17) - #a) / 2 + 2, 1)
    buffer.write(room)

    buffer.setTextColour(colours.white)
end

function game.drawRooms()
    game.viewportWidth = w - 23
    game.viewportHeight = h - 6

    if game.main.connection.player then
        game.viewportCenterX = game.main.connection.player.x
        game.viewportCenterY = game.main.connection.player.y
        game.worldLeft = game.viewportCenterX - (game.viewportWidth / 2)
        game.worldRight = game.viewportCenterX + (game.viewportWidth / 2)
        game.worldTop = game.viewportCenterY - (game.viewportHeight / 2)
        game.worldBottom = game.viewportCenterY + (game.viewportHeight / 2)
    end

    buffer.setTextColour(colours.grey)
    for y = 2, h - 5 do
        buffer.setCursorPos(2, y)
        buffer.write(("\183"):rep(w - 22))
    end
    buffer.setTextColour(colours.white)

    if not game.rooms then
        buffer.setCursorPos(((game.viewportWidth - #"Downloading map") / 2) + 4, game.viewportHeight / 2 + 2)
        buffer.write("Downloading map")
    else
        if game.main.connection.player then
            for _, room in ipairs(game.rooms) do
                game.print(game.worldLeft .. " " .. game.worldRight .. " " .. game.worldTop .. " " .. game.worldBottom)
                if  game.worldLeft    <= room.x + room.width and
                    game.worldRight	  >= room.x and
                    game.worldTop     <= room.y + room.height and
                    game.worldBottom  >= room.y then
                    local roomX, roomY = worldToViewportPos(room.x, room.y)

                    buffer.setBackgroundColour(room.type == "hub" and colours.red or room.type == "hall" and colours.orange or colours.blue)
                    for x = 1, room.width do
                        for y = 1, room.height do
                            buffer.setCursorPos(roomX + x, roomY + y)
                            buffer.write(" ");
                        end
                    end
                    buffer.setCursorPos(roomX, roomY)
                    buffer.write(room.id)
                    buffer.setBackgroundColour(colours.black)
                end
            end
        end
    end

    buffer.setBackgroundColour(colours.black)
end

function game.drawEntities()
    if game.main.connection.player then
        local playerX, playerY = worldToViewportPos(game.main.connection.player.x, game.main.connection.player.y)
        buffer.setCursorPos(playerX, playerY)
        buffer.write("\2")
    end
end

function game.drawLog()
    local current = term.current()
    term.redirect(game.logWindow)
    term.clear()
    term.setCursorPos(1, 1)

    for _, v in ipairs(game.log) do
        print(v)
    end

    term.redirect(current)

    game.logWindow.redraw()
end

function game.mouseClick(button, x, y)
    if button == 1 then
        if x >= w - 19 and x <= w then
            if y == 3 then
                game.sidebarMenuShowing = not game.sidebarMenuShowing

                return
            end

            if game.sidebarMenuShowing then
                if y == 4 then
                    game.sidebarMenuShowing = false
                    game.sidebarScreen = 0
                elseif y == 5 then
                    game.sidebarMenuShowing = false
                    game.sidebarScreen = 1
                elseif y > 5 then
                    game.sidebarMenuShowing = false
                end

                return
            end

            if game.sidebarScreen == 1 then
                if y == h - 1 then
                    http.request(constants.server .. "game/quit", "token=" .. textutils.urlEncode(game.main.connection.token))
                    game.main.changeState("menu")
                end
            end
        end
    end
end

function game.key(key)
    if game.main.connection.player then
        if key == "left" then
            game.main.connection.player.x = game.main.connection.player.x - 1
        elseif key == "right" then
            game.main.connection.player.x = game.main.connection.player.x + 1
        elseif key == "up" then
            game.main.connection.player.y = game.main.connection.player.y - 1
        elseif key == "down" then
            game.main.connection.player.y = game.main.connection.player.y + 1
        end
    end
end

function game.update()
    if os.clock() - game.lastPollTime > 20.25 then
        game.lastPollTime = os.clock()
        http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    end
end

function game.updateOnlineUsers(data)
    game.onlineUsers = data
end

function game.spawn(data)
    game.main.connection.player = Player(data.roomID, data.x, data.y, data.name)
    game.print("Spawned " .. data.name .. " at " .. data.x .. ", " .. data.y)
end

function game.room(data)
    game.main.connection.room = data
    game.print("Got room data")
    game.print(data.name)
end

game.events = {
    online_users = game.updateOnlineUsers,
    spawn = game.spawn,
    room = game.room
}

return game