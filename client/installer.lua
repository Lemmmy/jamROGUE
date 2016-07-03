if not term.isColour() then
    error("Use an advanced computer")
end

local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function decode(data)
	data = string.gsub(data, "[^" .. b .. "=]", "")

    return (data:gsub(".", function(x)
        if x == "=" then
			return ""
		end

        local r, f = "", (b:find(x) - 1)

        for i = 6, 1, -1 do
			r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
		end

        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then
			return ""
		end

        local c = 0

        for i = 1, 8 do
			c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
		end

        return string.char(c)
    end))
end

local function printFancy(str)
    local t = "&0" .. str .. "&0"
    local fields = {}
    local lastColour, lastPos = "0", 0

    for pos, clr in t:gmatch("()&(%x)") do
        table.insert(fields, { t:sub(lastPos + 2, pos - 1), lastColour })
        lastColour, lastPos = clr, pos
    end

    for i = 2, #fields do
        term.setTextColour(2 ^ (tonumber(fields[i][2], 16)))
        write(fields[i][1])
    end

    write("\n")
end

local files = {
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/jamrogue.lua"] = "jamrogue.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/assets/arrows.b64"] = "assets/arrows",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/assets/lmb.b64"] = "assets/lmb",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/assets/logo_little.b64"] = "assets/logo_little",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/assets/rmb.b64"] = "assets/rmb",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/assets/wasd.b64"] = "assets/wasd",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/lib/blittle"] = "lib/blittle",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/lib/framebuffer"] = "lib/framebuffer",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/lib/json"] = "lib/json",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/main.lua"] = "src/main.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/loop.lua"] = "src/loop.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/constants.lua"] = "src/constants.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/buffer.lua"] = "src/buffer.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/utils/ease.lua"] = "src/utils/ease.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/states/state_controls.lua"] = "src/states/state_controls.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/states/state_error.lua"] = "src/states/state_error.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/states/state_game.lua"] = "src/states/state_game.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/states/state_login.lua"] = "src/states/state_login.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/states/state_menu.lua"] = "src/states/state_menu.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/states/state_register.lua"] = "src/states/state_register.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/entities/entity.lua"] = "src/entities/entity.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/entities/entity_chest.lua"] = "src/entities/entity_chest.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/entities/entity_dropped_item.lua"] = "src/entities/entity_dropped_item.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/entities/entity_mob.lua"] = "src/entities/entity_mob.lua",
    ["https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/src/entities/entity_player.lua"] = "src/entities/entity_player.lua"
}

printFancy("jamROGUE will install its files to the &3.jamrogue&0 directory and create a launcher file called &3jamrogue&0.\nIs this ok? &8y/n")

local _, char = os.pullEvent("char")
if char ~= "y" then error("Exited by user.") end

if fs.exists(".jamrogue/") then
    printFancy("\njamROGUE directory already exists. \nClear it? &8y/n")

    local _, char = os.pullEvent("char")
    if char ~= "y" then error("Exited by user.") end

    fs.delete(".jamrogue/")
end

fs.makeDir(".jamrogue")
fs.makeDir(".jamrogue/src")
fs.makeDir(".jamrogue/src/utils")
fs.makeDir(".jamrogue/src/states")
fs.makeDir(".jamrogue/src/entities")
fs.makeDir(".jamrogue/lib")
fs.makeDir(".jamrogue/assets")

for k, v in pairs(files) do
    printFancy("Fetching file &5" .. v .. "&0...")

    local f = fs.open(fs.combine(".jamrogue", v), k:sub(-#".b64") == ".b64" and "wb" or "w")
    local h = http.get(k .. "?" .. textutils.urlEncode(os.clock()))

    if k:sub(-#".b64") == ".b64" then
        local x = decode(h.readAll())

        for c in x:gmatch(".") do
            f.write(string.byte(c))
        end
    else
        f.write(h.readAll())
    end

    f.close()
end

local f = fs.open("jamrogue", "w")
f.writeLine([[shell.run("/.jamrogue/jamrogue.lua")]])
f.close()

printFancy("Done! Run &5jamrogue")
