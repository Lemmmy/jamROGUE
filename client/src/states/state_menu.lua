local ease = require("src/utils/ease.lua")
local buffer = require("src/buffer.lua")

local w, h = term.getSize()

local menu = {}

function menu.init(main)
    menu.main = main
    menu.logo = blittle.load(resolveFile("assets/logo_little"))
    menu.logoX = 1
    menu.loginX = 1
    menu.registerX = 1
    menu.quitX = 1
    menu.selectedItem = 0
end

function menu.draw()
    local function menuItem(n, text, x, y)
         if menu.selectedItem == n and menu.main.stateTime > 1 then
            buffer.setBackgroundColour(colours.blue)
            buffer.setCursorPos(w / 2 - 5, y)
            buffer.write((" "):rep(12))
            buffer.setBackgroundColour(colours.black)
            buffer.setCursorPos(w / 2 - 7, y)
            buffer.setTextColour(colours.blue)
            buffer.write("\127")
            buffer.setBackgroundColour(colours.blue)
            buffer.setTextColour(colours.black)
            buffer.write("\127")
            buffer.setCursorPos(w / 2 + 7, y)
            buffer.setBackgroundColour(colours.blue)
            buffer.setTextColour(colours.black)
            buffer.write("\127")
            buffer.setTextColour(colours.blue)
            buffer.setBackgroundColour(colours.black)
            buffer.write("\127")
            buffer.setTextColour(colours.white)
            buffer.setBackgroundColour(colours.blue)
        else
            buffer.setTextColour(colours.lightGrey)
            buffer.setBackgroundColour(colours.black)
        end

        buffer.setCursorPos(w - x - 1, y)
        buffer.write(text)
    end

    if menu.main.stateTime <= 2 then
        menu.logoX = ease.outQuint(math.min(menu.main.stateTime, 1.2), 1, math.floor((w - menu.logo.width) / 2), 1.2)
        menu.loginX = ease.outQuint(math.min(menu.main.stateTime, 1.4), 1, math.floor(w / 2) + 1, 1.4)
        menu.registerX = ease.outQuint(math.min(menu.main.stateTime, 1.6), 1, math.floor(w / 2) + 1, 1.6)
        menu.quitX = ease.outQuint(math.min(menu.main.stateTime, 1.8), 1, math.floor(w / 2) + 1, 1.8)
    end

    blittle.draw(menu.logo, math.floor(menu.logoX), 3, buffer)

    menuItem(0, "Log in", math.floor(menu.loginX), 8)
    menuItem(1, "Register", math.floor(menu.registerX) + 1, 10)
    menuItem(2, "Controls", math.floor(menu.registerX) + 1, 12)
    menuItem(3, "Quit", math.floor(menu.quitX) - 1, 14)

    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.grey)
    buffer.setCursorPos((w - #"Made by Lemmmy") / 2 + 1, h - 1)
    buffer.write("Made by Lemmmy")
end

function menu.keyUp(key, keycode)
    if key == "down" then
        menu.selectedItem = (menu.selectedItem + 1) % 4
    elseif key == "up" then
        menu.selectedItem = (menu.selectedItem - 1) % 4
    elseif key == "enter" then
        if menu.selectedItem == 0 then
            menu.main.changeState("login")
        elseif menu.selectedItem == 1 then
            menu.main.changeState("register")
        elseif menu.selectedItem == 2 then
            menu.main.changeState("controls")
        elseif menu.selectedItem == 3 then
            menu.main.exiting = true
        end
    end
end

function menu.mouseClick(button, x, y)
    if button == 1 then
        if x >= w / 2 - 6 and x <= w / 2 + 8 and y == 8 then
            menu.main.changeState("login")
        elseif x >= w / 2 - 6 and x <= w / 2 + 8 and y == 10 then
            menu.main.changeState("register")
        elseif x >= w / 2 - 6 and x <= w / 2 + 8 and y == 12 then
            menu.main.changeState("controls")
        elseif x >= w / 2 - 6 and x <= w / 2 + 8 and y == 14 then
            menu.main.exiting = true
        end
    end
end

return menu