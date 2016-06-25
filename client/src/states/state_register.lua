local buffer = require("src/buffer.lua")
local constants = require("src/constants.lua")

local w, h = term.getSize()

local register = {}

function register.init(main)
    register.main = main
    register.username = ""
    register.password = ""
    register.flashUsername = false
    register.flashPassword = false
    register.focusedItem = 0
    register.errorText = ""
    register.successText = ""
    register.checkingText = ""
    register.checkingColour = colours.grey
    register.latestCheckURL = ""
    register.latestRegisterURL = ""
end

function register.usernameUpdated()
    register.checkingText = "Checking availability..."
    register.checkingColour = colours.grey

    local url = constants.server .. "register/check/" .. textutils.urlEncode(register.username)

    register.latestCheckURL = url

    http.request(url)
end

function register.httpSuccess(url, response)
    if url == register.latestCheckURL then
        local resp = json.decode(response.readAll())

        register.checkingColour = resp.ok and resp.available and colours.green or colours.red or colours.red

        if resp.ok then
            register.checkingText = resp.available and "Available!" or "Name already taken"
        else
            if resp.error == "invalid_username" then
                register.flashUsername = true
                register.checkingText = "Invalid username"
            elseif resp.error == "server_error" then
                register.checkingText = "Server error"
            else
                register.checkingText = resp.error
            end
        end
    elseif url == register.latestRegisterURL then
        local resp = json.decode(response.readAll())

        if resp.ok then
            register.successText = "Account created successfully"
        else
            if resp.error == "invalid_username" then
                register.flashUsername = true
                register.errorText = "Invalid username"
            elseif resp.error == "missing_password" then
                register.flashPassword = true
                register.errorText = "Missing password"
            elseif resp.error == "name_taken" then
                register.flashUsername = true
                register.errorText = "Name already taken"
            elseif resp.error == "server_error" then
                register.errorText = "Server error"
            else
                register.checkingText = resp.error
            end
        end
    end
end

function register.httpFailure(url)
    if url == register.latestCheckURL then
        register.checkingColour = colours.red
        register.checkingText = "Failed to connect to the server"
    elseif url == register.latestRegisterURL then
        register.errorText = "Failed to connect to the server"
    end
end

function register.draw()
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.grey)
    buffer.setCursorPos(1, 1)
    buffer.write(("\127"):rep(w))
    buffer.setCursorPos(1, 3)
    buffer.write(("\127"):rep(w))
    buffer.setBackgroundColour(colours.lightGrey)
    buffer.setTextColour(colours.white)
    buffer.setCursorPos(1, 2)
    buffer.write((" "):rep(w))
    buffer.setCursorPos(2, 2)
    buffer.write("\171 Register for jamMUD")
    buffer.setBackgroundColour(colours.black)

    buffer.setCursorPos(4, 6)
    buffer.setTextColour(colours.white)
    buffer.write("Username:")

    buffer.setCursorPos(4, 7)
    if register.flashUsername then
        buffer.setBackgroundColour(colours.red)
        register.flashUsername = false
    else
        buffer.setBackgroundColour(register.focusedItem == 0 and colours.lightGrey or colours.grey)
    end
    buffer.write((" "):rep(w - 7))
    buffer.setCursorPos(4, 7)
    buffer.write(register.username)
    buffer.setBackgroundColour(colours.black)

    buffer.setCursorPos(4, 8)
    buffer.setTextColour(register.checkingColour)
    buffer.write(register.checkingText)

    buffer.setCursorPos(4, 10)
    buffer.setTextColour(colours.white)
    buffer.write("Password:")

    buffer.setCursorPos(4, 11)
    if register.flashPassword then
        buffer.setBackgroundColour(colours.red)
        register.flashPassword = false
    else
        buffer.setBackgroundColour(register.focusedItem == 1 and colours.lightGrey or colours.grey)
    end
    buffer.write((" "):rep(w - 7))
    buffer.setCursorPos(4, 11)
    buffer.write(("*"):rep(math.min(#register.password, w - 7)))
    buffer.setBackgroundColour(colours.black)

    if register.errorText then
        buffer.setCursorPos(4, 14)
        buffer.setTextColour(colours.red)
        buffer.write(register.errorText)
        buffer.setTextColour(colours.white)
    end

    if #register.successText > 0 then
        buffer.setCursorPos(4, 14)
        buffer.setTextColour(colours.green)
        buffer.write(register.successText)
        buffer.setTextColour(colours.white)

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
    else
        buffer.setCursorPos(w - (#"Register" + 7), h - 2)
        buffer.setBackgroundColour(colours.green)
        buffer.write((" "):rep(2) .. "Register" .. (" "):rep(2))
        buffer.setBackgroundColour(colours.black)
        buffer.setTextColour(colours.green)
        buffer.setCursorPos(w - (#"Register" + 7), h - 1)
        buffer.write(("\131"):rep(#"Register" + 4))
        buffer.setBackgroundColour(colours.green)
        buffer.setTextColour(colours.black)
        buffer.setCursorPos(w - (#"Register" + 7), h - 3)
        buffer.write(("\143"):rep(#"Register" + 4))
        buffer.setBackgroundColour(colours.black)
        buffer.setTextColour(colours.white)
    end
end

function register.keyUp(key, keycode)
    if key == "down" or key == "tab" then
        register.focusedItem = (register.focusedItem + 1) % 2
    elseif key == "up" then
        register.focusedItem = (register.focusedItem - 1) % 2
    elseif key == "enter" then
        if #register.successText <= 0 then
            register.register()
        else
            register.main.changeState("menu")
        end
    end
end

function register.key(key, keycode)
    if key == "backspace" then
        if register.focusedItem == 0 then
            if #register.username > 0 then
                register.username = register.username:sub(1, #register.username - 1)
                register.usernameUpdated()
            else
                register.flashUsername = true
            end
        elseif register.focusedItem == 1 then
            if #register.password > 0 then
                register.password = register.password:sub(1, #register.password - 1)
            else
                register.flashPassword = true
            end
        end
    end
end

function register.mouseClick(button, x, y)
    if button == 1 then
        if x == 2 and y == 2 then
            register.main.changeState("menu")
        elseif x >= 4 and x <= w - 4 and y == 7 then
            register.focusedItem = 0
        elseif x >= 4 and x <= w - 4 and y == 11 then
            register.focusedItem = 1
        elseif #register.successText <= 0 and x >= w - (#"Register" + 7) and x <= w - 4 and y >= h - 3 and y <= h - 1 then
            register.register()
        elseif #register.successText > 0 and x >= w - (#"Back to menu" + 7) and x <= w - 4 and y >= h - 3 and y <= h - 1 then
            register.main.changeState("menu")
        end
    end
end

function register.char(char)
    if register.focusedItem == 0 then
        if #register.username >= 15 then
            register.flashUsername = true
        else
            register.username = register.username .. char
            register.usernameUpdated()
        end
    elseif register.focusedItem == 1 then
        register.password = register.password .. char
    end
end

function register.paste(paste)
    if register.focusedItem == 0 then
        for char in paste:gmatch(".") do
            if #register.username >= 15 then
                register.flashUsername = true

                break
            else
                register.username = register.username .. char
            end
        end
        register.usernameUpdated()
    elseif register.focusedItem == 1 then
        register.password = register.password ..paste
    end
end

function register.register()
    register.errorText = ""
    register.successText = ""

    if #register.username < 3 or #register.username > 15 or not register.username:find("^[a-z0-9_]+$") then
        register.flashUsername = true
        register.errorText = "Invalid username"

        return
    end

    if #register.password <= 0 then
        register.flashPassword = true
        register.errorText = "Missing password"

        return
    end

    local url = constants.server .. "register/" .. textutils.urlEncode(register.username)

    register.latestRegisterURL = url

    http.request(url, "password=" .. textutils.urlEncode(register.password):gsub("+", "%%20"))
end

return register