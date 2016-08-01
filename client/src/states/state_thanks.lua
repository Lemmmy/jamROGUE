local buffer = require("src/buffer.lua")

local w, h = term.getSize()

local thanks = {}

function thanks.init(main)
    thanks.main = main
    thanks.logo = blittle.load(resolveFile("assets/logo_little"))
end

function thanks.draw()
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.blue)

    blittle.draw(thanks.logo, math.floor((w - thanks.logo.width) / 2), 2, buffer)

    buffer.setTextColour(colours.blue)
    buffer.setCursorPos(1, 7)
    buffer.write(("\127"):rep(w))
    buffer.setCursorPos(1, 9)
    buffer.write(("\127"):rep(w))
    buffer.setBackgroundColour(colours.blue)
    buffer.setTextColour(colours.white)
    buffer.setCursorPos(1, 8)
    buffer.write((" "):rep(w))
    buffer.setCursorPos((w - #("Thanks for playing jamROGUE!")) / 2 + 1, 8)
    buffer.write("Thanks for playing jamROGUE!")
    buffer.setBackgroundColour(colours.black)

    local lines = {
        "Thanks for your support towards jamROGUE!",
        "For now, the server has been shut down so that",
        "I can continue development towards this game.",
        "Hopefully soon I can release it (if I get ",
        "unbanned from the forums) as a fully complete,",
        "enjoyable roguelike for ComputerCraft.",
        "",
        "Thanks!"
    }

    for i, v in ipairs(lines) do
        buffer.setCursorPos((w - #v) / 2 + 1,10 + i)
        buffer.write(v)
    end
end

return thanks