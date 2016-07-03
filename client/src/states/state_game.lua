local buffer = require("src/buffer.lua")
local constants = require("src/constants.lua")
local Player = require("src/entities/entity_player.lua")
local EntityDroppedItem = require("src/entities/entity_dropped_item.lua")
local EntityChest = require("src/entities/entity_chest.lua")
local EntityMob = require("src/entities/entity_mob.lua")

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

    game.entities = {}

    game.log = {}
    game.logWindow = framebuffer.new(w - 20, 4, true, 0, h - 4)
    game.logScrollPos = 1
    game.logShowing = false

    game.failedPolls = 0
    game.lastPollTime = os.clock()
    http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    http.request(constants.server .. "map.json", "token=" .. textutils.urlEncode(game.main.connection.token))

    game.main.connection.players = {}

    game.viewportWidth = w - 22
    game.viewportHeight = h - 6
    game.viewportWindow = framebuffer.new(game.viewportWidth, game.viewportHeight, true, 1, 1)

    game.movingLeft = false
    game.movingRight = false
    game.movingUp = false
    game.movingDown = false

    game.typingMessage = false
    game.typing = ""
end

function game.print(text, colour)
    game.log[#game.log + 1] = {
        text = text,
        time = os.clock(),
        colour = colour
    }

    if #game.log > 20 then
        table.remove(game.log, 1)
    end
end

function game.printFancy(text)
    game.log[#game.log + 1] = {
        text = text,
        time = os.clock(),
        fancy = true
    }

    if #game.log > 20 then
        table.remove(game.log, 1)
    end
end

function game.httpSuccess(url, response)
    if url == constants.server .. "game/poll" then
        local resp = json.decode(response.readAll())

        if resp.ok then
            game.failedPolls = 0

            if resp.events then
                for _, event in ipairs(resp.events) do
                    if game.events and game.events[event.type] then
                        game.events[event.type](event.data)
                    end
                end
            end

            game.lastPollTime = os.clock()
            http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
        else
            if resp.error == "invalid_token" then
                game.main.error = "Invalid token (server restarted?)"
                game.main.changeState("error")

                return
            end

            game.failedPolls = game.failedPolls + 1

            if game.failedPolls >= 5 then
                game.main.error = "Lost connection to server."
                game.main.changeState("error")
            end
        end
    elseif url == constants.server .. "map.json" then
        game.loadMap(json.decode(response.readAll()).rooms)
    elseif url == constants.server .. "game/chat" then
        local resp = json.decode(response.readAll())

        if resp.ok and resp.heard <= 0 then
            local resps = {"Nobody heard you...", "Your voice echoes...", "You were unheard..."}

            game.print(resps[math.random(#resps)], colours.red)
        end
    end
end

function game.httpFailure(url)
    if url == constants.server .. "game/poll" then
        if os.clock() - game.lastPollTime < 2.0 then
            game.failedPolls = game.failedPolls + 1
            game.print("Server connection seems to be unstable (" .. game.failedPolls .. " attempts)", colours.yellow)

            if game.failedPolls >= 5 then
                game.main.error = "Lost connection to server."
                game.main.changeState("error")

                return
            end
        end

        game.lastPollTime = os.clock()
        http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    end
end

function game.draw()
    game.drawGame()
    game.drawHUD()
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
    buffer.write(game.sidebarScreen == 0 and "Info" or "Menu")
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
    if game.main.connection.player and not game.main.connection.player.alive then
        buffer.setBackgroundColour(colours.blue)
        buffer.setTextColour(colours.white)
        buffer.setCursorPos(w - 18, h - 1)
        buffer.write((" "):rep(18))
        buffer.setCursorPos(w - 17 + ((17 - #"Respawn") / 2), h - 1)
        buffer.write("Respawn")
        buffer.setBackgroundColour(colours.grey)
        buffer.setTextColour(colours.blue)
        buffer.setCursorPos(w, h - 1)
        buffer.write("\149")
        buffer.setTextColour(colours.white)

        return
    end

    local level = game.main.connection.player and game.main.connection.player.level or 1

    local maxHealth = game.main.connection.player and level + 4 or 1
    local health = game.main.connection.player and game.main.connection.player.health or 1

    local healthBarWidth = 17
    local healthWidth = ath.min(math.max(math.floor(health / maxHealth * healthBarWidth), 0), healthBarWidth)

    buffer.setCursorPos(w - 18, 5)
    buffer.blit(
        ("\140"):rep(healthBarWidth) .. " \3",
        ("e"):rep(healthWidth) .. ("f"):rep(math.max(healthBarWidth - healthWidth, 0)) .. "00",
        ("7"):rep(healthBarWidth + 2)
    )

    local maxXP = game.main.connection.player and 10 * 1.25 ^ level or 1
    local xp = game.main.connection.player and game.main.connection.player.xp or 1

    local xpText = " Lv " .. level

    local xpBarWidth = 19 - #xpText
    local xpWidth = math.min(math.max(math.floor(xp / maxXP * xpBarWidth), 0), xpBarWidth)

    buffer.setCursorPos(w - 18, 6)
    buffer.blit(
        ("\140"):rep(xpBarWidth) .. xpText,
        ("4"):rep(xpWidth) .. ("f"):rep(math.max(xpBarWidth - xpWidth, 0)) .. ("0"):rep(#xpText),
        ("7"):rep(xpBarWidth + #xpText)
    )

    buffer.setBackgroundColour(colours.grey)

    if game.main.connection.player and game.main.connection.player.inventory then
        for i, v in ipairs(game.main.connection.player.inventory) do
            if v.equipped then
                buffer.setBackgroundColour(colours.black)

                buffer.setCursorPos(w - 18, 7 + i)
                buffer.write((" "):rep(17))
            end

            buffer.setCursorPos(w - 18, 7 + i)

            if v.count > 1 then
                buffer.setTextColour(colours.white)
                buffer.write(v.count .. "x ")
            end

            buffer.setTextColour(v.item.colour)
            buffer.write(v.item.name)

            buffer.setBackgroundColour(colours.grey)

            buffer.setCursorPos(w, 7 + i)
            buffer.setTextColour(colours.white)
            buffer.write((game.itemMenuShowing and game.itemMenuItem == i) and "\30" or "\31")
        end

        for i = 1, 9 - #game.main.connection.player.inventory do
            buffer.setCursorPos(w - 18, 7 + i + #game.main.connection.player.inventory)
            buffer.setTextColour(colours.lightGrey)
            buffer.write(("-"):rep(19))
        end

        buffer.setTextColour(colours.white)
    end

    if game.itemMenuShowing then
        buffer.setBackgroundColour(colours.white)
        buffer.setTextColour(colours.black)
        buffer.setCursorPos(w - 19, 8 + game.itemMenuItem)
        buffer.write("\149" .. "Inspect" .. (" "):rep(19 - #"Inspect"))
        buffer.setCursorPos(w - 19, 9 + game.itemMenuItem)
        buffer.write("\149" .. "Equip" .. (" "):rep(19 - #"Equip"))
        buffer.setCursorPos(w - 19, 10 + game.itemMenuItem)
        buffer.write("\149" .. "Drop" .. (" "):rep(19 - #"Drop"))
    end

    buffer.setBackgroundColour(colours.grey)
    buffer.setTextColour(colours.white)
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
        if not v.fancy then
            term.setTextColour(v.colour or colours.white)
            print(v.text)
        else
            local t = "&0" .. v.text .. "&0"
            local fields = {}
            local lastColour, lastPos = "0", 0

            for pos, clr in t:gmatch("()&(%x)") do
                table.insert(fields, { t:sub(lastPos + 2, pos - 1), lastColour })
                lastColour, lastPos = clr, pos
            end

            for i = 2, #fields do
                term.setTextColour(2 ^ (tonumber(fields[i][2], 16)))
                write(fields[i][1])
            end

            write("\n")
        end
    end

    term.redirect(buffer)
    framebuffer.draw(game.logWindow.buffer)
    term.redirect(current)

    buffer.setTextColour(colours.white)

    buffer.setCursorPos(w - 20, h)
    buffer.write(game.logShowing and "\31" or "\30")

    if not game.typingMessage then
        buffer.setTextColour(colours.grey)
    end

    buffer.setCursorPos(1, h)
    buffer.write(#game.typing > 0 and game.typing:sub(-(w - 21)) or (game.typingMessage and "" or "Click to chat"))

    buffer.setTextColour(colours.white)

    if game.typingMessage then
        if floor(game.main.stateTime * 2) % 2 == 0 then
            buffer.write("\22")
        end
    end
end

local function worldToViewportPos(x, y)
    return (x or 0) - game.viewportCenterX + game.viewportWidth / 2 + 1, (y or 0) - game.viewportCenterY + game.viewportHeight / 2 + 1
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
    buffer.setTextColour(colours.white)

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

    if game.main.connection.player and not game.main.connection.player.alive then
        local a = "[ " .. (" "):rep(#"DEAD") .. " ]"
        buffer.setCursorPos(((w - 17) - #a) / 2, 1)
        buffer.write(a)

        buffer.setTextColour(colours.red)
        buffer.setCursorPos(((w - 17) - #a) / 2 + 2, 1)
        buffer.write("DEAD")
    else
        if game.main.connection.room and game.main.connection.room.name then
            local a = "[ " .. (" "):rep(#game.main.connection.room.name) .. " ]"
            buffer.setCursorPos(((w - 17) - #a) / 2, 1)
            buffer.write(a)

            buffer.setTextColour(colours.lightBlue)
            buffer.setCursorPos(((w - 17) - #a) / 2 + 2, 1)
            buffer.write(game.main.connection.room.name)
        end
    end

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

    if game.main.connection.player and not game.main.connection.player.alive then
        viewportSetTextColour(colours.red)
        for y = 1, viewportHeight do
            viewportSetCursorPos(1, y)
            viewportWrite(rep("\127", viewportWidth))
        end
        viewportSetTextColour(colours.white)

        return
    end

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

                    local colour = room.type == "hub" and (room.visited and (room.subType == "spawn" and colours.green or colours.red) or colours.grey) or ((room.type == "regular" and not room.visited) and colours.grey or colours.lightGrey) or colours.lightGrey
                    local colourHex = room.type == "hub" and (room.visited and (room.subType == "spawn" and "d" or "e") or "7") or ((room.type == "regular" and not room.visited) and "7" or "8") or "8"

                    viewportSetBackgroundColour(colours.black)
                    viewportSetTextColour(colour)

                    for y = 1, min(roomHeight - 1, viewportHeight - roomStartY + 1) do
                        local amt = min(roomWidth, viewportWidth - roomStartX + 2)

                        viewportSetCursorPos(roomStartX, roomStartY + y)
                        viewportBlit(rep(room.type ~= "hall" and (room.visited and "\183" or "\127") or "\183", amt), rep(colourHex, amt), rep("f", amt))
                    end

                    viewportSetBackgroundColour(colour)

                    for x = 0, roomWidth do
                        viewportSetBackgroundColour(colour)
                        if roomStartX + x >= 1 and roomStartY >= 1 and roomStartX + x <= viewportWidth + 1 and roomStartY <= viewportHeight + 1 then
                            local stop = false

                            if room.touchingHalls and #room.touchingHalls > 0 then
                                for _, hid in ipairs(room.touchingHalls) do
                                    local hall = game.rooms[hid + 1]

                                    if hid ~= room.id and room.x + x >= hall.x + 1 and room.x + x <= hall.x + hall.width - 1 and room.y >= hall.y and room.y ~= hall.y then
                                        stop = true
                                    end
                                end
                            end

                            if not stop then
                                viewportSetCursorPos(roomStartX + x, roomStartY)
                                viewportWrite(" ")
                            end
                        end

                        if roomStartX + x >= 1 and roomStartY + roomHeight >= 1 and roomStartX + x <= viewportWidth + 1 and roomStartY + roomHeight - 1 <= viewportHeight + 1 then
                            local stop = false

                            if room.touchingHalls and #room.touchingHalls > 0 then
                                for _, hid in ipairs(room.touchingHalls) do
                                    local hall = game.rooms[hid + 1]

                                    if hid ~= room.id and room.x + x >= hall.x + 1 and room.x + x <= hall.x + hall.width - 1 and room.y + roomHeight <= hall.y + hall.height and room.y ~= hall.y then
                                        stop = true
                                    end
                                end
                            end

                            if not stop then
                                viewportSetCursorPos(roomStartX + x, roomStartY + roomHeight)
                                viewportWrite(" ")
                            end
                        end
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

                                    if hid ~= room.id and room.y + y >= hall.y + 1 and room.y + y <= hall.y + hall.height - 1 and room.x + roomWidth < hall.x + hall.width then
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
    if game.main.connection.player and not game.main.connection.player.alive then return end

    game.viewportWindow.setTextColour(colours.white)
    if game.entities then
        for _, v in ipairs(game.entities) do
            local eX, eY = worldToViewportPos(v.x, v.y)

            if eX >= 1 and eY >= 1 and eX <= game.viewportWidth + 1 and eY <= game.viewportHeight + 1 then
                game.viewportWindow.setCursorPos(eX, eY)
                game.viewportWindow.setTextColour(v.getColour and v:getColour() or colours.white)
                game.viewportWindow.write(v.getSymbol and v:getSymbol() or "?")
            end
        end
    end

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
        if x == w - 20 and y == h then
            game.logShowing = not game.logShowing
            local th = game.logShowing and h or 4

            game.logWindow = framebuffer.new(w - 20, th, true, 0, h - th)

            return
        end

        if x >= 1 and x <= w - 20 and y > h - 3 then
            game.typingMessage = true
        else
            game.typingMessage = false
        end

        if x >= w - 19 and x <= w then
            if y == 3 and not game.itemMenuShowing then
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

            if game.sidebarScreen == 0 then
                if game.main.connection.player and not game.main.connection.player.alive then
                    if y == h - 1 then
                        http.request(constants.server .. "game/respawn", "token=" .. textutils.urlEncode(game.main.connection.token))
                    end

                    return
                end

                if game.itemMenuShowing then
                    if x == w then
                        game.itemMenuShowing = false
                        return
                    end

                    if y == game.itemMenuItem + 8 then
                        if game.main.connection.player and game.main.connection.player.inventory and game.main.connection.player.inventory[game.itemMenuItem] then
                            game.printFancy(game.main.connection.player.inventory[game.itemMenuItem].item.description)
                        end
                    elseif y == game.itemMenuItem + 9 then
                        http.request(constants.server .. "game/equip", "token=" .. textutils.urlEncode(game.main.connection.token) .. "&item=" .. (game.itemMenuItem - 1))
                    elseif y == game.itemMenuItem + 10 then
                        http.request(constants.server .. "game/drop", "token=" .. textutils.urlEncode(game.main.connection.token) .. "&item=" .. (game.itemMenuItem - 1))
                    end

                    game.itemMenuShowing = false
                    return
                end

                if y == 5 then
                    local maxHealth = floor(game.main.connection.player and game.main.connection.player.level + 4 or 1)
                    local health = floor(game.main.connection.player and game.main.connection.player.health or 1)

                    local colour = health > maxHealth * 0.6 and "5" or health > maxHealth * 0.4 and "4" or health > maxHealth * 0.25 and "1" or "e"

                    game.printFancy("You have &" .. colour .. health .. "&0 HP out of " .. "&5" .. maxHealth .. "&0 HP")
                elseif y == 6 then
                    local maxXP = floor(game.main.connection.player and 10 * 1.25 ^ game.main.connection.player.level or 1)
                    local xp = floor(game.main.connection.player and game.main.connection.player.xp or 1)

                    game.printFancy("You have &4" .. xp .. "&0 XP out of " .. "&4" .. maxXP .. "&0 XP")
                elseif y >= 8 then
                    if game.main.connection.player and game.main.connection.player.inventory and game.main.connection.player.inventory[y - 7] then
                        if x == w then
                            game.itemMenuShowing = true
                            game.itemMenuItem = y - 7
                        else
                            game.printFancy(game.main.connection.player.inventory[y - 7].item.description)
                        end
                    end
                end
            elseif game.sidebarScreen == 1 then
                if y == h - 1 then
                    http.request(constants.server .. "game/quit", "token=" .. textutils.urlEncode(game.main.connection.token))
                    game.main.changeState("menu")
                end
            end
        end

        if x > 1 and y > 1 and x < game.viewportWidth + 2 and y < game.viewportHeight + 2 then
            if game.main.connection.player and not game.main.connection.player.alive then return end

            local wx, wy = viewportToWorldPos(x - 1, y - 1)

            for _, player in ipairs(game.main.connection.players) do
                if player.x == wx and player.y == wy then
                    game.print("That's " .. player.name .. (random(1, 2) == 1 and "." or "!"))
                end

                return
            end

            if game.entities then
                for _, entity in ipairs(game.entities) do
                    if entity.x == wx and entity.y == wy then
                        if entity.inspect then
                            entity:inspect(game.main.connection.token)
                        end

                        return
                    end
                end
            end
        end
    elseif button == 2 then
        if game.main.connection.player and not game.main.connection.player.alive then return end

        if x >= w - 19 and x <= w then
            if game.sidebarScreen == 0 then
                if y >= 8 and game.main.connection.player and game.main.connection.player.inventory and game.main.connection.player.inventory[y - 7] then
                    http.request(constants.server .. "game/equip", "token=" .. textutils.urlEncode(game.main.connection.token) .. "&item=" .. (y - 8))
                end
            end
        end

        if x > 1 and y > 1 and x < game.viewportWidth + 2 and y < game.viewportHeight + 2 then
            local wx, wy = viewportToWorldPos(x - 1, y - 1)

            if game.entities then
                for _, entity in ipairs(game.entities) do
                    if entity.x == wx and entity.y == wy then
                        if entity.interact then
                            entity:interact(game.main.connection.token)
                        end

                        return
                    end
                end
            end
        end
    end
end

function game.key(key)
    if game.main.connection.player and not game.typingMessage then
        if key == "left" or key == "a" then
            game.movingLeft = true
        elseif key == "right" or key == "d" then
            game.movingRight = true
        elseif key == "up" or key == "w" then
            game.movingUp = true
        elseif key == "down" or key == "s" then
            game.movingDown = true
        end
    end

    if game.typingMessage then
        if key == "backspace" then
            if #game.typing > 0 then
                game.typing = game.typing:sub(1, #game.typing - 1)
            end
        elseif key == "enter" then
            http.request(constants.server .. "game/chat",  "token=" .. textutils.urlEncode(game.main.connection.token) ..
                                                            "&message=" .. game.typing)

            game.typingMessage = false
            game.typing = ""
        end
    else
        if key == "enter" then
            game.typingMessage = true
        end
    end
end

function game.keyUp(key)
    if game.main.connection.player then
        if key == "left" or key == "a" then
            game.movingLeft = false
        elseif key == "right" or key == "d" then
            game.movingRight = false
        elseif key == "up" or key == "w" then
            game.movingUp = false
        elseif key == "down" or key == "s" then
            game.movingDown = false
        end
    end
end

function game.char(char)
    if game.typingMessage then
        if #game.typing < 100 then
            game.typing = game.typing .. char
        end
    end
end

function game.paste(paste)
    if game.typingMessage then
        for char in paste:gmatch(".") do
            if #game.typing < 100 then
                game.typing = game.typing .. char
            end
        end
    end
end

function game.update()
    if os.clock() - game.lastPollTime > 25 then
        game.lastPollTime = os.clock()
        http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    end
end

function game.updateCent()
    if not game.rooms then return end
    if game.typingMessage then return end
    if game.main.connection.player and not game.main.connection.player.alive then return end

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
                                                            "&y=" .. game.main.connection.player.y ..
                                                            "&time=" .. textutils.urlEncode(os.clock()))
        end
    end
end

function game.updateOnlineUsers(data)
    game.onlineUsers = data
end

function game.spawn(data)
    game.main.connection.player = Player(data.player.roomID, data.player.x, data.player.y, data.player.name)
    game.main.connection.player.health = data.player.health
    game.main.connection.player.level = data.player.level
    game.main.connection.player.xp = data.player.xp
    game.main.connection.player.inventory = data.player.inventory
    game.main.connection.player.alive = data.player.alive

    for _, player in ipairs(data.players) do
        if player.name:lower() ~= data.player.name:lower() then
            local poop = Player(player.roomID, player.x, player.y, player.name)
            poop.health = player.health
            poop.level = player.level
            poop.xp = player.xp

            table.insert(game.main.connection.players, poop)
        end
    end
end

function game.join(data)
    local poop = Player(data.roomID, data.x, data.y, data.name)
    poop.health = data.health
    poop.level = data.level
    poop.xp = data.xp

    table.insert(game.main.connection.players, poop)
end

function game.quit(data)
    for i, player in ipairs(game.main.connection.players) do
        if player.name == data.name then
            table.remove(game.main.connection.players, i)
            return
        end
    end
end

function game.room(data)
    if game.rooms and data.id and game.rooms[data.id + 1] and (game.rooms[data.id + 1].visited == nil or (game.rooms[data.id + 1].visited ~= nil and not game.rooms[data.id + 1].visited)) then
        game.rooms[data.id + 1].visited = true

        game.print("You discovered " .. data.name .. (math.random(1, 2) == 1 and "!" or "."), colours.lime)
    end

    game.main.connection.room = data

    game.entities = {}

    if data.entities then
        game.loadEntities(data.entities)
    end
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

function game.serverMessage(data)
    if data.fancy then
        game.printFancy(data.text)
    else
        game.print(data.text, data.colour or colours.white)
    end
end

function game.chat(data)
    game.print("<" .. data.from .. "> " .. data.message, data.from:lower() == game.main.connection.player.name:lower() and colours.white or colours.lightGrey)
end

function game.damage(data)
    game.main.connection.player.health = data.health
end

function game.dead(data)
    game.print("You died.", colours.red)
    game.main.connection.player.alive = false
end

function game.playerDied(data)
    for _, player in ipairs(game.main.connection.players) do
        if player.name:lower() == data.name:lower() then
            player.alive = false
        end
    end
end

function game.xp(data)
    if game.main.connection.player then
        game.main.connection.player.xp = data.xp
        game.main.connection.player.level = data.level

        if data.oldLevel ~= data.level then
            game.printFancy("&1You levelled up! You are now level &5" .. data.level .. "&1.")
        end
    end
end

function game.updateInventory(data)
    game.main.connection.player.inventory = data
end

function game.spawnEntity(data)
    game.loadEntity(data)
end

function game.removeEntity(data)
    for i, v in ipairs(game.entities) do
        if v.id == data.id then
            table.remove(game.entities, i)
            return
        end
    end
end

function game.moveEntity(data)
    for i, v in ipairs(game.entities) do
        if v.id == data.id then
            v.x = data.x;
            v.y = data.y;
            v.room = data.room;
            return
        end
    end
end

function game.loadEntity(entity)
    if entity.type == "DroppedItem" then
        table.insert(game.entities, EntityDroppedItem(entity.id, entity.x, entity.y, entity.item))
    elseif entity.type == "Chest" then
        table.insert(game.entities, EntityChest(entity.id, entity.x, entity.y, entity.locked))
    elseif entity.type == "BaseMob" then
        table.insert(game.entities, EntityMob(entity.id, entity.x, entity.y, entity.mob_type))
    end
end

function game.loadEntities(entities)
    for _, v in ipairs(entities) do
        game.loadEntity(v)
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
    quit = game.quit,
    move = game.move,
    server_message = game.serverMessage,
    chat = game.chat,
    inventory = game.updateInventory,
    entity_spawn = game.spawnEntity,
    entity_remove = game.removeEntity,
    entity_move = game.moveEntity,
    damage = game.damage,
    dead = game.dead,
    player_died = game.playerDied,
    xp = game.xp
}

return game