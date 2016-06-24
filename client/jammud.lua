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

local function urlEncode(str)
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w %-%_%.%~]])",
        function(c) return string.format("%%%02X", string.byte(c)) end)
    str = string.gsub(str, " ", "+")
end

local function reqGet(route, data)
    local query = ""

    for k, v in pairs(data) do
        query = query .. "&" .. urlEncode(k) .. "=" .. urlEncode(v)
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

    login = {}
}

local state = "login"
local stateTime = 1

local function changeState(dest)
    state = dest
    stateTime = 1
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
    writeCentred("Made by Lemmmy", h)
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
    buffer.write("\187 Log in to jamMUD")
    buffer.setBackgroundColour(colours.black)
end

buffer.setVisible(true)

local timerp = os.startTimer(0.05)

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
    elseif event == "mouse_click" then
        if states[state] then
            if states[state].mouseClick then
                states[state].mouseClick(p1, p2, p3)
            end
        end
    end
end