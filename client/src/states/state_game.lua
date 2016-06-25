local buffer = require("src/buffer.lua")
local constants = require("src/constants.lua")

local w, h = term.getSize()

local game = {}

local function gamePrint(text)
    game.log[#game.log + 1] = text
end

function game.init(main)
    game.main = main

    game.sidebarScreen = 0
    game.sidebarMenuShowing = false

    game.onlineUsers = 0
    game.log = {}

    game.logWindow = window.create(buffer, 1, h - 3, w - 20, 4, true)

    game.lastPollTime = os.clock()
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

        game.lastPollTime = os.clock()
        http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    end
end

function game.httpFailure(url)
    if url == constants.server .. "game/poll" then
        gamePrint("Cool")
        game.lastPollTime = os.clock()
        http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    end
end

function game.draw()
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
    buffer.setCursorPos(w - 17 + ((17 - #online) / 2) + 1, 2)
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

function game.update()
    if os.clock() - game.lastPollTime > 20.25 then
        gamePrint("Timeout")
        game.lastPollTime = os.clock()
        http.request(constants.server .. "game/poll", "token=" .. textutils.urlEncode(game.main.connection.token))
    end
end

function game.updateOnlineUsers(data)
    gamePrint("Online users: " .. data)
    game.onlineUsers = data
end

game.events = {
    online_users = game.updateOnlineUsers
}

return game