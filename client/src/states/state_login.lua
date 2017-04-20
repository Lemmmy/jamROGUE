local buffer = require("src/buffer.lua")
local constants = require("src/constants.lua")

local w, h = term.getSize()

local login = {}

function login.init(main)
    login.main = main
    login.username = ""
    login.password = ""
    login.flashUsername = false
    login.flashPassword = false
    login.focusedItem = 0
    login.errorText = ""
    login.latestLoginURL = ""
    login.remember = false
    login.colour = 0

    local handle = fs.open(resolveFile(".login"), "r")
    if handle then
        login.remember = handle.readLine():lower() == "true"
        login.username = handle.readLine()
        login.password = handle.readLine()
        login.colour = tonumber(handle.readLine(), 16) or 0
        handle.close()
    end
end

function login.httpSuccess(url, response)
    if url == login.latestLoginURL then
        local resp = json.decode(response.readAll())

        if resp.ok then
            login.main.connection = {
                name = resp.name,
                token = resp.token
            }

            login.main.changeState("game")
        else
            if resp.error == "invalid_username" then
                login.flashUsername = true
                login.errorText = "Invalid username"
            elseif resp.error == "missing_password" then
                login.flashPassword = true
                login.errorText = "Missing password"
            elseif resp.error == "server_error" then
                login.errorText = "Server error"
            elseif resp.error == "already_logged_in" then
                login.errorText = "Already logged in"
            elseif resp.error == "incorrect_login" then
                login.flashUsername = true
                login.flashPassword = true
                login.errorText = "Incorrect login details"
            else
                login.checkingText = resp.error
            end
        end
    end
end

function login.httpFailure(url)
    if url == login.latestLoginURL then
        login.errorText = "Failed to connect to the server"
    end
end

function login.draw()
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
    buffer.write("\171 Log in to jamROGUE")
    buffer.setBackgroundColour(colours.black)

    buffer.setCursorPos(4, 6)
    buffer.setTextColour(colours.white)
    buffer.write("Username:")

    buffer.setCursorPos(4, 7)
    if login.flashUsername then
        buffer.setBackgroundColour(colours.red)
        login.flashUsername = false
    else
        buffer.setBackgroundColour(login.focusedItem == 0 and colours.lightGrey or colours.grey)
    end
    buffer.write((" "):rep(w - 7))
    buffer.setCursorPos(4, 7)
    buffer.write(login.username)
    buffer.setBackgroundColour(colours.black)

    buffer.setCursorPos(4, 10)
    buffer.setTextColour(colours.white)
    buffer.write("Password:")

    buffer.setCursorPos(4, 11)
    if login.flashPassword then
        buffer.setBackgroundColour(colours.red)
        login.flashPassword = false
    else
        buffer.setBackgroundColour(login.focusedItem == 1 and colours.lightGrey or colours.grey)
    end
    buffer.write((" "):rep(w - 7))
    buffer.setCursorPos(4, 11)
    buffer.write(("*"):rep(math.min(#login.password, w - 7)))
    buffer.setBackgroundColour(colours.black)

    buffer.setCursorPos(4, 13)
    buffer.write("Remember ")
    buffer.setBackgroundColour(login.remember and colours.lightGrey or colours.grey)
    buffer.write(login.remember and "x" or " ")
    buffer.setBackgroundColour(colours.black)

    buffer.write("  Colour ")
    for i = 0, 14 do
        buffer.setBackgroundColour(2 ^ i)
        if i == 0 then
            buffer.setTextColour(colours.grey)
        end
        buffer.write((login.colour == i) and "x" or " ")
        if i == 0 then
            buffer.setTextColour(colours.white)
        end
    end
    buffer.setBackgroundColour(colours.black)


    if login.errorText then
        buffer.setCursorPos(4, 15)
        buffer.setTextColour(colours.red)
        buffer.write(login.errorText)
        buffer.setTextColour(colours.white)
    end

    buffer.setCursorPos(w - (#"Log in" + 7), h - 2)
    buffer.setBackgroundColour(colours.green)
    buffer.write((" "):rep(2) .. "Log in" .. (" "):rep(2))
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.green)
    buffer.setCursorPos(w - (#"Log in" + 7), h - 1)
    buffer.write(("\131"):rep(#"Log in" + 4))
    buffer.setBackgroundColour(colours.green)
    buffer.setTextColour(colours.black)
    buffer.setCursorPos(w - (#"Log in" + 7), h - 3)
    buffer.write(("\143"):rep(#"Log in" + 4))
    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.white)
end

function login.keyUp(key, keycode)
    if key == "down" or key == "tab" then
        login.focusedItem = (login.focusedItem + 1) % 2
    elseif key == "up" then
        login.focusedItem = (login.focusedItem - 1) % 2
    elseif key == "enter" then
        login.login()
    end
end

function login.key(key, keycode)
    if key == "backspace" then
        if login.focusedItem == 0 then
            if #login.username > 0 then
                login.username = login.username:sub(1, #login.username - 1)
            else
                login.flashUsername = true
            end
        elseif login.focusedItem == 1 then
            if #login.password > 0 then
                login.password = login.password:sub(1, #login.password - 1)
            else
                login.flashPassword = true
            end
        end
    end
end

function login.mouseClick(button, x, y)
    if button == 1 then
        if x == 2 and y == 2 then
            login.main.changeState("menu")
        elseif x >= 4 and x <= w - 4 and y == 7 then
            login.focusedItem = 0
        elseif x >= 4 and x <= w - 4 and y == 11 then
            login.focusedItem = 1
        elseif x == 13 and y == 13 then
            login.remember = not login.remember
        elseif x >= 23 and x <= 37 and y == 13 then
            login.colour = x - 23
        elseif x >= w - (#"Log in" + 7) and x <= w - 4 and y >= h - 3 and y <= h - 1 then
            login.login()
        end
    end
end

function login.char(char)
    if login.focusedItem == 0 then
        if #login.username >= 15 then
            login.flashUsername = true
        else
            login.username = login.username .. char
        end
    elseif login.focusedItem == 1 then
        login.password = login.password .. char
    end
end

function login.paste(paste)
    if login.focusedItem == 0 then
        for char in paste:gmatch(".") do
            if #login.username >= 15 then
                login.flashUsername = true

                break
            else
                login.username = login.username .. char
            end
        end
    elseif login.focusedItem == 1 then
        login.password = login.password .. paste
    end
end

function login.login()
    login.errorText = ""

    if #login.username < 3 or #login.username > 15 or not login.username:lower():find("^[a-z0-9_]+$") then
        login.flashUsername = true
        login.errorText = "Invalid username"

        return
    end

    if #login.password <= 0 then
        login.flashPassword = true
        login.errorText = "Missing password"

        return
    end

    local handle = fs.open(resolveFile(".login"), "w")
    if handle then
        handle.writeLine(tostring(login.remember))
        handle.writeLine(login.remember and login.username or "")
        handle.writeLine(login.remember and login.password or "")
        handle.writeLine(string.format("%01x", login.colour))
        handle.close()
    end

    local url = constants.server .. "connect"

    login.latestLoginURL = url

    http.request(url, "name=" .. textutils.urlEncode(login.username):gsub("+", "%%20") .. "&password=" .. textutils.urlEncode(login.password):gsub("+", "%%20") .. "&colour=" .. string.format("%01x", login.colour))
end

return login