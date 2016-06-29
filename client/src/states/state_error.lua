local buffer = require("src/buffer.lua")

local w, h = term.getSize()

local error = {}

function error.init(main)
    error.main = main
    error.textWindow = framebuffer.new(w - 7, h - 11, true, 3, 5)
end

function error.draw()
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.red)
    buffer.setCursorPos(1, 1)
    buffer.write(("\127"):rep(w))
    buffer.setCursorPos(1, 3)
    buffer.write(("\127"):rep(w))
    buffer.setBackgroundColour(colours.red)
    buffer.setTextColour(colours.white)
    buffer.setCursorPos(1, 2)
    buffer.write((" "):rep(w))
    buffer.setCursorPos(2, 2)
    buffer.write("\171 Error")
    buffer.setBackgroundColour(colours.black)

    if error.main.error then
        local current = term.current()

        term.redirect(error.textWindow)
        term.clear()
        term.setCursorPos(1, 1)
        term.write(error.main.error)

        term.redirect(buffer)
        framebuffer.draw(error.textWindow.buffer)
        term.redirect(current)

        buffer.setTextColour(colours.white)
    end

    buffer.setCursorPos(w - (#"Back to menu" + 7), h - 2)
    buffer.setBackgroundColour(colours.green)
    buffer.write((" "):rep(2) .. "Back to menu" .. (" "):rep(2))
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.green)
    buffer.setCursorPos(w - (#"Back to menu" + 7), h - 1)
    buffer.write(("\131"):rep(#"Back to menu" + 4))
    buffer.setBackgroundColour(colours.green)
    buffer.setTextColour(colours.black)
    buffer.setCursorPos(w - (#"Back to menu" + 7), h - 3)
    buffer.write(("\143"):rep(#"Back to menu" + 4))
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.white)
end

function error.keyUp(key, keycode)
    if key == "enter" then
        error.main.error = nil
        error.main.changeState("menu")
    end
end

function error.mouseClick(button, x, y)
    if button == 1 then
        if (x >= w - (#"Back to menu" + 7) and x <= w - 4 and y >= h - 3 and y <= h - 1) or (x == 2 and y == 2) then
            error.main.error = nil
            error.main.changeState("menu")
        end
    end
end

return error