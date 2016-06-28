local buffer = require("src/buffer.lua")
local constants = require("src/constants.lua")
local Player = require("src/entities/entity_player.lua")

local w, h = term.getSize()

local game = {}

local min = math.min
local max = math.max
local log = math.log
local floor = math.floor
local ceil = math.ceil
local random = math.random

local rep = string.rep
local sub = string.sub

function game.init(main)
    game.main = main

    game.sidebarScreen = 0
    game.sidebarMenuShowing = false

    game.onlineUsers = 0

    game.log = {}
    game.logWindow = framebuffer.new(w - 19, 4, true, 0, h - 4)

    game.lastPollTime = os.clock()
    http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    http.request(constants.server .. "map.json")

    game.main.connection.players = {}

    game.viewportWidth = w - 22
    game.viewportHeight = h - 6
    game.viewportWindow = framebuffer.new(game.viewportWidth, game.viewportHeight, true, 1, 1)

    game.movingLeft = false
    game.movingRight = false
    game.movingUp = false
    game.movingDown = false

    game.typingMessage = false
end

function game.print(text)
    game.log[#game.log + 1] = {
        text = text,
        time = os.clock()
    }

    if #game.log > 20 then
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
        game.loadMap(json.decode(response.readAll()).rooms)
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
    buffer.setBackgroundColour(colours.grey)
    buffer.setTextColour(colours.white)

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
    buffer.setCursorPos(w - 18, 5)
    buffer.write(os.clock())
    buffer.setCursorPos(w - 18, 6)
    buffer.write(game.lastPollTime)
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

function game.drawLog()
    local current = term.current()
    term.redirect(game.logWindow)
    term.clear()
    term.setCursorPos(1, 1)

    for _, v in ipairs(game.log) do
        print(v.text)
    end

    term.redirect(current)

    term.redirect(buffer)
    framebuffer.draw(game.logWindow.buffer)
    term.redirect(current)
end

local function worldToViewportPos(x, y)
    return x - game.viewportCenterX + game.viewportWidth / 2 + 1, y - game.viewportCenterY + game.viewportHeight / 2 + 1
end

local function viewportToWorldPos(x, y)
    return floor((game.viewportCenterX - (game.viewportWidth / 2)) + x), floor((game.viewportCenterY - (game.viewportHeight / 2)) + y)
end

function game.drawGame()
    if game.main.connection.player then
        game.viewportCenterX = game.main.connection.player.x
        game.viewportCenterY = game.main.connection.player.y
        game.worldLeft = game.viewportCenterX - (game.viewportWidth / 2)
        game.worldRight = game.viewportCenterX + (game.viewportWidth / 2)
        game.worldTop = game.viewportCenterY - (game.viewportHeight / 2)
        game.worldBottom = game.viewportCenterY + (game.viewportHeight / 2)
    end

    game.drawWindowBorder()

    game.viewportWindow.clear()

    game.drawRooms()
    game.drawEntities()

    local poop = term.current()

    term.redirect(buffer)
    framebuffer.draw(game.viewportWindow.buffer)
    term.redirect(poop)
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

local function roomIntersects(a, b)
    return (a.x <= b.x + b.width and
            a.x + b.width >= b.x and
            a.y <= b.y + b.height and
            a.y + a.height >= b.y);
end

function game.drawRooms()
    -- fuck table lookups

    local viewportWindow = game.viewportWindow
    local viewportSetTextColour = viewportWindow.setTextColor
    local viewportSetBackgroundColour = viewportWindow.setBackgroundColor
    local viewportSetCursorPos = viewportWindow.setCursorPos
    local viewportWrite = viewportWindow.write
    local viewportBlit = viewportWindow.blit

    local worldLeft = game.worldLeft
    local worldRight = game.worldRight
    local worldTop = game.worldTop
    local worldBottom = game.worldBottom
    local viewportWidth = game.viewportWidth
    local viewportHeight = game.viewportHeight

    viewportSetTextColour(colours.grey)
    for y = 1, viewportHeight do
        viewportSetCursorPos(1, y)
        viewportWrite(rep("\183", viewportWidth))
    end
    viewportSetTextColour(colours.white)

    if not game.rooms then
        viewportSetCursorPos((viewportWidth - #"Downloading map") / 2 + 1, viewportHeight / 2 + 1)
        viewportWrite("Downloading map")
    else
        if game.main.connection.player then
            for _, room in ipairs(game.rooms) do
                local roomWidth = room.width
                local roomHeight = room.height
                local roomType = room.type

                if  worldLeft    <= room.x + roomWidth and
                    worldRight	  >= room.x and
                    worldTop     <= room.y + roomHeight and
                    worldBottom  >= room.y then
                    local roomStartX, roomStartY = worldToViewportPos(room.x, room.y)

                    local colour = colours.lightGrey
                    local colourHex = "8"

                    viewportSetBackgroundColour(colours.black)
                    viewportSetTextColour(colour)

                    for y = 1, min(roomHeight - 1, viewportHeight - roomStartY + 1) do
                        local amt = min(roomWidth, viewportWidth - roomStartX + 2)

                        viewportSetCursorPos(roomStartX, roomStartY + y)
                        viewportBlit(rep("\183", amt), rep(colourHex, amt), rep("f", amt))
                    end

                    viewportSetBackgroundColour(colour)

                    for x = 0, roomWidth do
                        viewportSetBackgroundColour(colour)
                        if roomStartX + x >= 1 and roomStartY >= 1 and roomStartX + x <= viewportWidth + 1 and roomStartY <= viewportHeight + 1 then
                            local stop = false

                            if room.touchingHalls and #room.touchingHalls > 0 then
                                for _, hid in ipairs(room.touchingHalls) do
                                    local hall = game.rooms[hid + 1]

                                    if hid ~= room.id and room.x + x >= hall.x + 1 and room.x + x <= hall.x + hall.width - 1 and room.y >= hall.y then
                                        stop = true
                                    end
                                end
                            end

                            if not stop then
                                viewportSetCursorPos(roomStartX + x, roomStartY)
                                viewportWrite(" ")
                            end
                        end

                        if roomStartX + x >= 1 and roomStartY + roomHeight >= 1 and roomStartX + x <= viewportWidth + 1 and roomStartY + roomHeight <= viewportHeight + 1 then
                            local stop = false

                            if room.touchingHalls and #room.touchingHalls > 0 then
                                for _, hid in ipairs(room.touchingHalls) do
                                    local hall = game.rooms[hid + 1]

                                    if hid ~= room.id and room.x + x >= hall.x + 1 and room.x + x <= hall.x + hall.width - 1 and room.y + roomHeight <= hall.y + hall.height then
                                        stop = true
                                    end
                                end
                            end

                            if not stop then
                                viewportSetCursorPos(roomStartX + x, roomStartY + roomHeight)
                                viewportWrite(" ")
                            end
                        end
                        viewportSetBackgroundColour(colour)
                    end

                    for y = 0, roomHeight do
                        if roomStartX >= 1 and roomStartY + y >= 1 and roomStartX <= viewportWidth + 1 and roomStartY + y <= viewportHeight + 1 then
                            local stop = false

                            if room.touchingHalls and #room.touchingHalls > 0 then
                                for _, hid in ipairs(room.touchingHalls) do
                                    local hall = game.rooms[hid + 1]

                                    if hid ~= room.id and room.y + y >= hall.y + 1 and room.y + y <= hall.y + hall.height - 1 and room.x >= hall.x + 1 then
                                        stop = true
                                    end
                                end
                            end

                            if not stop then
                                viewportSetCursorPos(roomStartX, roomStartY + y)
                                viewportWrite(" ")
                            end
                        end

                        if roomStartX + roomWidth >= 1 and roomStartY + y >= 1 and roomStartX + roomWidth <= viewportWidth + 1 and roomStartY + y <= viewportHeight + 1 then
                            local stop = false

                            if room.touchingHalls and #room.touchingHalls > 0 then
                                for _, hid in ipairs(room.touchingHalls) do
                                    local hall = game.rooms[hid + 1]

                                    if hid ~= room.id and room.y + y >= hall.y + 1 and room.y + y <= hall.y + hall.height - 1 and room.x + roomWidth <= hall.x + hall.width then
                                        stop = true
                                    end
                                end
                            end

                            if not stop then
                                viewportSetCursorPos(roomStartX + roomWidth, roomStartY + y)
                                viewportWrite(" ")
                            end
                        end
                    end
                end
            end
        end
    end

    viewportSetBackgroundColour(colours.black)
end

function game.drawEntities()
    game.viewportWindow.setTextColour(colours.lightGrey)
    for _, player in ipairs(game.main.connection.players) do
        local playerX, playerY = worldToViewportPos(player.x, player.y)
        if playerX >= 1 and playerY >= 1 and playerX <= game.viewportWidth + 1 and playerY <= game.viewportHeight + 1 then
            game.viewportWindow.setCursorPos(playerX, playerY)
            game.viewportWindow.write("\2")
        end -- my life
    end

    game.viewportWindow.setTextColour(colours.white)
    if game.main.connection.player then
        local playerX, playerY = worldToViewportPos(game.main.connection.player.x, game.main.connection.player.y)
        game.viewportWindow.setCursorPos(playerX, playerY)
        game.viewportWindow.write("\2")
    end
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

        if x > 1 and y > 1 and x < game.viewportWidth + 2 and y < game.viewportHeight + 2 then
            local wx, wy = viewportToWorldPos(x - 1, y - 1)

            for _, player in ipairs(game.main.connection.players) do
                if player.x == wx and player.y == wy then
                    game.print("That's " .. player.name .. (random(1, 2) == 1 and "." or "!"))
                end
            end
        end
    end
end

function game.key(key)
    if game.main.connection.player then
        if key == "left" then
            game.movingLeft = true
        elseif key == "right" then
            game.movingRight = true
        elseif key == "up" then
            game.movingUp = true
        elseif key == "down" then
            game.movingDown = true
        end
    end
end

function game.keyUp(key)
    if game.main.connection.player then
        if key == "left" then
            game.movingLeft = false
        elseif key == "right" then
            game.movingRight = false
        elseif key == "up" then
            game.movingUp = false
        elseif key == "down" then
            game.movingDown = false
        end
    end
end

function game.update()
    if os.clock() - game.lastPollTime > 21.25 then
        game.lastPollTime = os.clock()
        http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    end
end

function game.updateCent()
    local dx = 0
    local dy = 0

    if game.movingLeft then
        dx = dx - 1
    end
    if game.movingRight then
        dx = dx + 1
    end
    if game.movingUp then
        dy = dy - 1
    end
    if game.movingDown then
        dy = dy + 1
    end

    if dx ~= 0 or dy ~= 0 then
        local destX = game.main.connection.player.x + dx
        local destY = game.main.connection.player.y + dy

        local inside = false

        for _, room in ipairs(game.rooms) do
            if room.x + 1 <= destX and room.y + 1 <= destY and room.x + room.width - 1 >= destX and room.y + room.height - 1 >= destY then
                inside = true
                break
            end
        end

        if inside then
            game.main.connection.player.x = destX
            game.main.connection.player.y = destY

            http.request(constants.server .. "game/move",  "token=" .. textutils.urlEncode(game.main.connection.token) ..
                                                            "&x=" .. game.main.connection.player.x ..
                                                            "&y=" .. game.main.connection.player.y)
        end
    end
end

function game.updateOnlineUsers(data)
    game.onlineUsers = data
end

function game.spawn(data)
    game.main.connection.player = Player(data.player.roomID, data.player.x, data.player.y, data.player.name)

    for _, player in ipairs(data.players) do
        if player.name:lower() ~= data.player.name:lower() then
            table.insert(game.main.connection.players, Player(player.roomID, player.x, player.y, player.name))
        end
    end
end

function game.join(data)
    table.insert(game.main.connection.players, Player(data.roomID, data.x, data.y, data.name))
end

function game.quit(data)
    for i, player in ipairs(game.main.connection.players) do
        if player.name == data.name then
            table.remove(game.main.connection.players, i)
        end
    end
end

function game.room(data)
    game.main.connection.room = data
end

function game.move(data)
    for _, player in ipairs(game.main.connection.players) do
        if player.name:lower() == data.player:lower() then
            player.x = data.x
            player.y = data.y
            player.room = data.room
        end
    end
end

function game.loadMap(rooms)
    game.rooms = rooms
end

game.events = {
    online_users = game.updateOnlineUsers,
    spawn = game.spawn,
    room = game.room,
    join = game.join,
    move = game.move
}

return game