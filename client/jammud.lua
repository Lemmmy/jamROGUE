if not term.isColour() then
    print("Use an advanced computer")

    exit()
end

os.loadAPI("json")
os.loadAPI("blittle")
os.loadAPI("framebuffer")

local w, h = term.getSize()
local oldTerm = term.current()
local buffer = window.create(term.current(), 1, 1, w, h)

local server = "http://localhost:3000/"

local function reqGet(route, data)
    local query = ""

    for k, v in pairs(data) do
        query = query .. "&" .. textutils.urlEncode(k) .. "=" .. textutils.urlEncode(v)
    end

    query = query.sub(1, 2)

    local req = http.get(server .. "?" .. query)
    return json.decode(req.readAll())
end

local function reqPost(route, data)
    local req = http.post(server .. route, data)
    return json.decode(req.readAll())
end

local pow = math.pow
local sin = math.sin
local cos = math.cos
local pi = math.pi
local sqrt = math.sqrt
local abs = math.abs
local asin  = math.asin

local function inOutCubic(t, b, c, d)
    t = t / d * 2

    if t < 1 then
        return c / 2 * t * t * t + b
    else
    	t = t - 2
        return c / 2 * (t * t * t + 2) + b
    end
end

local function writeCentred(text, y)
    buffer.setCursorPos((w - #text) / 2 + 1, y)
    buffer.write(text)
end

local states = {
    menu = {
        logo = blittle.load("logo_little"),
        logoX = 1,
        loginX = 1,
        registerX = 1,
        selectedItem = 0
    },

    login = {
        username = "",
        password = "",
        flashUsername = false,
        flashPassword = false,
        focusedItem = 0,
        errorText = ""
    },

    register = {
        username = "",
        password = "",
        flashUsername = false,
        flashPassword = false,
        focusedItem = 0,
        errorText = "",
        checkingText = "",
        checkingColour = colours.grey,
        latestCheckURL = ""
    }
}

local state = "menu"
local stateTime = 1

local function changeState(dest)
    state = dest
    stateTime = 1

    if states[state].init then
        states[state].init()
    end
end

----------------------------------------
-- MENU STATE --------------------------
----------------------------------------

function states.menu.draw()
    local function menuItem(n, text, x, y) 
         if states.menu.selectedItem == n and stateTime > 1.8 then
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

    if stateTime <= 2.2 then
        states.menu.logoX = inOutCubic(math.min(stateTime, 1.8), 1, math.floor((w - states.menu.logo.width) / 2) + 1, 1.8)
        states.menu.loginX = inOutCubic(math.min(stateTime, 2), 1, math.floor(w / 2) + 1, 2)
        states.menu.registerX = inOutCubic(math.min(stateTime, 2.2), 1, math.floor(w / 2) + 2, 2.2)
    end

    blittle.draw(states.menu.logo, math.floor(states.menu.logoX), 4, buffer)

    menuItem(0, "Log in", math.floor(states.menu.loginX), 10)
    menuItem(1, "Register", math.floor(states.menu.registerX) + 1, 12)

    buffer.setBackgroundColour(colours.black)
    buffer.setTextColour(colours.grey)
    writeCentred("Made by Lemmmy", h - 1)
end

function states.menu.keyUp(key, keycode)
    if key == "down" then
        states.menu.selectedItem = (states.menu.selectedItem + 1) % 2
    elseif key == "up" then
        states.menu.selectedItem = (states.menu.selectedItem - 1) % 2
    elseif key == "enter" then
        if states.menu.selectedItem == 0 then
            changeState("login")
        elseif states.menu.selectedItem == 1 then
            changeState("register")
        end
    end
end

function states.menu.mouseClick(button, x, y)
    if button == 1 then
        if x >= w / 2 - 4 and x <= w / 2 + 8 and y == 10 then
            changeState("login")
        elseif x >= w / 2 - 4 and x <= w / 2 + 8 and y == 12 then
            changeState("register")
        end
    end
end

----------------------------------------
-- LOGIN STATE -------------------------
----------------------------------------

function states.login.init()
    states.login.username = ""
    states.login.password = ""
    states.login.flashUsername = false
    states.login.flashPassword = false
    states.login.focusedItem = 0
    states.login.errorText = ""
    states.login.checkingText = ""
    states.login.checkingColour = colours.grey
    states.login.latestCheckURL = ""
end

function states.login.draw()
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
    buffer.write("\171 Log in to jamMUD")
    buffer.setBackgroundColour(colours.black)

    buffer.setCursorPos(4, 6)
    buffer.setTextColour(colours.white)
    buffer.write("Username:")

    buffer.setCursorPos(4, 7)
    if states.login.flashUsername then
        buffer.setBackgroundColour(colours.red)
        states.login.flashUsername = false
    else
        buffer.setBackgroundColour(states.login.focusedItem == 0 and colours.lightGrey or colours.grey)
    end
    buffer.write((" "):rep(w - 7))
    buffer.setCursorPos(4, 7)
    buffer.write(states.login.username)
    buffer.setBackgroundColour(colours.black)

    buffer.setCursorPos(4, 10)
    buffer.setTextColour(colours.white)
    buffer.write("Password:")

    buffer.setCursorPos(4, 11)
    if states.login.flashPassword then
        buffer.setBackgroundColour(colours.red)
        states.login.flashPassword = false
    else
        buffer.setBackgroundColour(states.login.focusedItem == 1 and colours.lightGrey or colours.grey)
    end
    buffer.write((" "):rep(w - 7))
    buffer.setCursorPos(4, 11)
    buffer.write(("*"):rep(math.min(#states.login.password, w - 7)))
    buffer.setBackgroundColour(colours.black)

    if states.login.errorText then
        buffer.setCursorPos(4, 14)
        buffer.setTextColour(colours.red)
        buffer.write(states.login.errorText)
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

function states.login.keyUp(key, keycode)
    if key == "down" or key == "tab" then
        states.login.focusedItem = (states.login.focusedItem + 1) % 2
    elseif key == "up" then
        states.login.focusedItem = (states.login.focusedItem - 1) % 2
    elseif key == "enter" then
        states.login.login()
    end
end

function states.login.key(key, keycode)
    if key == "backspace" then
        if states.login.focusedItem == 0 then
            if #states.login.username > 0 then
                states.login.username = states.login.username:sub(1, #states.login.username - 1)
            else
                states.login.flashUsername = true
            end
        elseif states.login.focusedItem == 1 then
            if #states.login.password > 0 then
                states.login.password = states.login.password:sub(1, #states.login.password - 1)
            else
                states.login.flashPassword = true
            end
        end
    end
end

function states.login.mouseClick(button, x, y)
    if button == 1 then
        if x == 2 and y == 2 then
            changeState("menu")
        elseif x >= 4 and x <= w - 4 and y == 7 then
            states.login.focusedItem = 0
        elseif x >= 4 and x <= w - 4 and y == 11 then
            states.login.focusedItem = 1
        elseif x >= w - (#"Log in" + 7) and x <= w - 4 and y >= h - 3 and y <= h - 1 then
            states.login.login()
        end
    end
end

function states.login.char(char)
    if states.login.focusedItem == 0 then
        if #states.login.username >= 15 then
            states.login.flashUsername = true
        else
            states.login.username = states.login.username .. char
        end
    elseif states.login.focusedItem == 1 then
        states.login.password = states.login.password .. char
    end
end

function states.login.paste(paste)
    if states.login.focusedItem == 0 then
        for char in paste:gmatch(".") do
            if #states.login.username >= 15 then
                states.login.flashUsername = true

                break
            else
                states.login.username = states.login.username .. char
            end
        end
    elseif states.login.focusedItem == 1 then
        states.login.password = states.login.password ..paste
    end
end

function states.login.login()
    states.login.errorText = ""

    if #states.login.username < 3 or #states.login.username > 15 or not states.login.username:find("^[a-z0-9_]+$") then
        states.login.flashUsername = true
        states.login.errorText = "Invalid username"
    end

    if #states.login.password <= 0 then
        states.login.flashPassword = true
        states.login.errorText = "Missing password"
    end
end

----------------------------------------
-- REGISTER STATE ----------------------
----------------------------------------

function states.register.init()
    states.register.username = ""
    states.register.password = ""
    states.register.flashUsername = false
    states.register.flashPassword = false
    states.register.focusedItem = 0
    states.register.errorText = ""
    states.register.checkingText = ""
    states.register.checkingColour = colours.grey
    states.register.latestCheckURL = ""
end

function states.register.usernameUpdated()
    states.register.checkingText = "Checking availability..."
    states.register.checkingColour = colours.grey

    local url = server .. "register/check/" .. textutils.urlEncode(states.register.username)

    states.register.latestCheckURL = url

    http.request(url)
end

function states.register.httpSuccess(url, response)
    if url == states.register.latestCheckURL then
        local resp = json.decode(response.readAll())

        states.register.checkingColour = resp.ok and resp.available and colours.green or colours.red or colours.red
        
        if resp.ok then
            states.register.checkingText = resp.available and "Available!" or "Name already taken"
        else 
            if resp.error == "invalid_username" then
                states.register.flashUsername = true
                states.register.checkingText = "Invalid username"
            elseif resp.error == "server_error" then
                states.register.checkingText = "Server error"
            else
                states.register.checkingText = resp.error
            end
        end
    end
end

function states.register.draw()
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
    if states.register.flashUsername then
        buffer.setBackgroundColour(colours.red)
        states.register.flashUsername = false
    else
        buffer.setBackgroundColour(states.register.focusedItem == 0 and colours.lightGrey or colours.grey)
    end
    buffer.write((" "):rep(w - 7))
    buffer.setCursorPos(4, 7)
    buffer.write(states.register.username)
    buffer.setBackgroundColour(colours.black)

    buffer.setCursorPos(4, 8)
    buffer.setTextColour(states.register.checkingColour)
    buffer.write(states.register.checkingText)

    buffer.setCursorPos(4, 10)
    buffer.setTextColour(colours.white)
    buffer.write("Password:")

    buffer.setCursorPos(4, 11)
    if states.register.flashPassword then
        buffer.setBackgroundColour(colours.red)
        states.register.flashPassword = false
    else
        buffer.setBackgroundColour(states.register.focusedItem == 1 and colours.lightGrey or colours.grey)
    end
    buffer.write((" "):rep(w - 7))
    buffer.setCursorPos(4, 11)
    buffer.write(("*"):rep(math.min(#states.register.password, w - 7)))
    buffer.setBackgroundColour(colours.black)

    if states.register.errorText then
        buffer.setCursorPos(4, 14)
        buffer.setTextColour(colours.red)
        buffer.write(states.register.errorText)
        buffer.setTextColour(colours.white)
    end

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

function states.register.keyUp(key, keycode)
    if key == "down" or key == "tab" then
        states.register.focusedItem = (states.register.focusedItem + 1) % 2
    elseif key == "up" then
        states.register.focusedItem = (states.register.focusedItem - 1) % 2
    elseif key == "enter" then
        states.register.register()
    end
end

function states.register.key(key, keycode)
    if key == "backspace" then
        if states.register.focusedItem == 0 then
            if #states.register.username > 0 then
                states.register.username = states.register.username:sub(1, #states.register.username - 1)
                states.register.usernameUpdated()
            else
                states.register.flashUsername = true
            end
        elseif states.register.focusedItem == 1 then
            if #states.register.password > 0 then
                states.register.password = states.register.password:sub(1, #states.register.password - 1)
            else
                states.register.flashPassword = true
            end
        end
    end
end

function states.register.mouseClick(button, x, y)
    if button == 1 then
        if x == 2 and y == 2 then
            changeState("menu")
        elseif x >= 4 and x <= w - 4 and y == 7 then
            states.register.focusedItem = 0
        elseif x >= 4 and x <= w - 4 and y == 11 then
            states.register.focusedItem = 1
        elseif x >= w - (#"Register" + 7) and x <= w - 4 and y >= h - 3 and y <= h - 1 then
            states.register.register()
        end
    end
end

function states.register.char(char)
    if states.register.focusedItem == 0 then
        if #states.register.username >= 15 then
            states.register.flashUsername = true
        else
            states.register.username = states.register.username .. char
            states.register.usernameUpdated()
        end
    elseif states.register.focusedItem == 1 then
        states.register.password = states.register.password .. char
    end
end

function states.register.paste(paste)
    if states.register.focusedItem == 0 then
        for char in paste:gmatch(".") do
            if #states.register.username >= 15 then
                states.register.flashUsername = true

                break
            else
                states.register.username = states.register.username .. char
            end
        end
        states.register.usernameUpdated()
    elseif states.register.focusedItem == 1 then
        states.register.password = states.register.password ..paste
    end
end

function states.register.register()
    states.register.errorText = ""

    if #states.register.username < 3 or #states.register.username > 15 or not states.register.username:find("^[a-z0-9_]+$") then
        states.register.flashUsername = true
        states.register.errorText = "Invalid username"
    end

    if #states.register.password <= 0 then
        states.register.flashPassword = true
        states.register.errorText = "Missing password"
    end
end

changeState("menu")

buffer.setVisible(true)

local timerp = os.startTimer(1)

while true do
    local event, p1, p2, p3 = os.pullEvent()

    if event == "timer" and p1 == timerp then
        stateTime = stateTime + 0.1

        if states[state] then
            if states[state].draw then
                buffer.clear()

                states[state].draw()
            end

            buffer.redraw()
        end

        timerp = os.startTimer(0.1)
    elseif event == "key_up" then
        if states[state] then
            if states[state].keyUp then
                states[state].keyUp(keys.getName(p1), p1)
            end
        end
    elseif event == "key" then
        if states[state] then
            if states[state].key then
                states[state].key(keys.getName(p1), p1, p2)
            end
        end
    elseif event == "mouse_click" then
        if states[state] then
            if states[state].mouseClick then
                states[state].mouseClick(p1, p2, p3)
            end
        end
    elseif event == "paste" then
        if states[state] then
            if states[state].paste then
                states[state].paste(p1)
            end
        end
    elseif event == "char" then
        if states[state] then
            if states[state].char then
                states[state].char(p1)
            end
        end
    elseif event == "http_success" then
        if states[state] then
            if states[state].httpSuccess then
                states[state].httpSuccess(p1, p2)
            end
        end
    elseif event == "http_failure" then
        if states[state] then
            if states[state].httpFailure then
                states[state].httpFailure(p1)
            end
        end
    end
end