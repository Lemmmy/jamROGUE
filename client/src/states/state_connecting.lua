local buffer = require("src/buffer.lua")

local w, h = term.getSize()

local connecting = {}

function connecting.init(main)
    connecting.main = main
    connecting.text = "  Connecting...  "
end

function connecting.draw()
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.grey)

    for i = 1, h do
        buffer.setCursorPos(1, i)
        buffer.write(("\127"):rep(w))
    end
    
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.white)
    buffer.setCursorPos((w - #connecting.text) / 2 + 1, h / 2)
    buffer.write((" "):rep(#connecting.text))
    buffer.setCursorPos((w - #connecting.text) / 2 + 1, h / 2 + 1)
    buffer.write(connecting.text)
    buffer.setCursorPos((w - #connecting.text) / 2 + 1, h / 2 + 2)
    buffer.write((" "):rep(#connecting.text))
end

return connecting