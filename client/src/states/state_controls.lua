local buffer = require("src/buffer.lua")

local w, h = term.getSize()

local controls = {}

function controls.init(main)
    controls.main = main
    controls.arrows = blittle.load(resolveFile("assets/arrows"))
    controls.wasd = blittle.load(resolveFile("assets/wasd"))
    controls.lmb = blittle.load(resolveFile("assets/lmb"))
    controls.rmb = blittle.load(resolveFile("assets/rmb"))
end

function controls.draw()
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.blue)
    buffer.setCursorPos(1, 1)
    buffer.write(("\127"):rep(w))
    buffer.setCursorPos(1, 3)
    buffer.write(("\127"):rep(w))
    buffer.setBackgroundColour(colours.blue)
    buffer.setTextColour(colours.white)
    buffer.setCursorPos(1, 2)
    buffer.write((" "):rep(w))
    buffer.setCursorPos(2, 2)
    buffer.write("\171 Controls")
    buffer.setBackgroundColour(colours.black)

    blittle.draw(controls.arrows, 2, 5, buffer)
    blittle.draw(controls.wasd, 17, 5, buffer)

    buffer.setCursorPos(35, 8)
    buffer.write("Move Player")

    blittle.draw(controls.lmb, 2, 12, buffer)

    buffer.setCursorPos(10, 15)
    buffer.write("Inspect")

    blittle.draw(controls.rmb, 19, 12, buffer)

    buffer.setCursorPos(27, 15)
    buffer.write("Interact")

    buffer.setCursorPos(w - (#"Back" + 7), h - 2)
    buffer.setBackgroundColour(colours.green)
    buffer.write((" "):rep(2) .. "Back" .. (" "):rep(2))
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.green)
    buffer.setCursorPos(w - (#"Back" + 7), h - 1)
    buffer.write(("\131"):rep(#"Back" + 4))
    buffer.setBackgroundColour(colours.green)
    buffer.setTextColour(colours.black)
    buffer.setCursorPos(w - (#"Back" + 7), h - 3)
    buffer.write(("\143"):rep(#"Back" + 4))
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.white)
end

function controls.keyUp(key, keycode)
    if key == "enter" then
        controls.main.changeState("menu")
    end
end

function controls.mouseClick(button, x, y)
    if button == 1 then
        if (x >= w - (#"Back" + 7) and x <= w - 4 and y >= h - 3 and y <= h - 1) or (x == 2 and y == 2) then
            controls.main.changeState("menu")
        end
    end
end

return controls