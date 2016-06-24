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
    menu.selectedItem = 0
end

function menu.draw()
    local function menuItem(n, text, x, y) 
         if menu.selectedItem == n and menu.main.stateTime > 1.8 then
            buffer.setBackgroundColour(colours.grey)
            buffer.setCursorPos(w / 2 - 4, y)
            buffer.write((" "):rep(12))
            buffer.setBackgroundColour(colours.black)
            buffer.setCursorPos(w / 2 - 7, y)
            buffer.setTextColour(colours.grey)
            buffer.write(("\127"):rep(3))
            buffer.setCursorPos(w / 2 + 8, y)
            buffer.setTextColour(colours.grey)
            buffer.write(("\127"):rep(3))
            buffer.setTextColour(colours.white)
            buffer.setBackgroundColour(colours.grey)
        else
            buffer.setTextColour(colours.lightGrey)
            buffer.setBackgroundColour(colours.black)
        end

        buffer.setCursorPos(w - x, y)
        buffer.write(text)
    end

    if menu.main.stateTime <= 2.2 then
        menu.logoX = ease.inOutCubic(math.min(menu.main.stateTime, 1.8), 1, math.floor((w - menu.logo.width) / 2) + 1, 1.8)
        menu.loginX = ease.inOutCubic(math.min(menu.main.stateTime, 2), 1, math.floor(w / 2) + 1, 2)
        menu.registerX = ease.inOutCubic(math.min(menu.main.stateTime, 2.2), 1, math.floor(w / 2) + 2, 2.2)
    end

    blittle.draw(menu.logo, math.floor(menu.logoX), 4, buffer)

    menuItem(0, "Log in", math.floor(menu.loginX), 10)
    menuItem(1, "Register", math.floor(menu.registerX) + 1, 12)

    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.grey)
    buffer.setCursorPos((w - #"Made by Lemmmy") / 2 + 1, h - 1)
    buffer.write("Made by Lemmmy")
end

function menu.keyUp(key, keycode)
    if key == "down" then
        menu.selectedItem = (menu.selectedItem + 1) % 2
    elseif key == "up" then
        menu.selectedItem = (menu.selectedItem - 1) % 2
    elseif key == "enter" then
        if menu.selectedItem == 0 then
            menu.main.changeState("login")
        elseif menu.selectedItem == 1 then
            menu.main.changeState("register")
        end
    end
end

function menu.mouseClick(button, x, y)
    if button == 1 then
        if x >= w / 2 - 4 and x <= w / 2 + 8 and y == 10 then
            menu.main.changeState("login")
        elseif x >= w / 2 - 4 and x <= w / 2 + 8 and y == 12 then
            menu.main.changeState("register")
        end
    end
end

return menu