local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function decodeBase64(data)
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
    str = str .. "\n&0"
    local startPos = 1

    local i = 1
    while i <= #str do
        local c = str:sub(i, i)
        if c == "&" then
            write(str:sub(startPos, i - 1))
            i = i + 1
            term.setTextColour(2 ^ tonumber(str:sub(i, i), 16))
            startPos = i + 1
        end
        i = i + 1
    end
end

local function readFile(path)
    local handle = fs.open(path, "r")
    if handle then
        local str = handle.readAll()
        handle.close()
        return str
    end
end

local function writeFile(path, str)
    local handle = fs.open(path, "w")
    if handle then
        handle.write(str)
        handle.close()
    end
end

local function writeFileBinary(path, str)
    local handle = fs.open(path, "wb")
    if handle then
        for i = 1, #str do
            handle.write(str:sub(i, i):byte())
        end
        handle.close()
    end
end



local installPath = ".jamrogue"
local launchPath = "jamrogue"
local repoPath = "jamrogue-repo"..tostring(math.random(1e6))
local gitgetPath = "gitget"..tostring(math.random(1e6))
local gitgetPaste = "W5ZkVYSi"
local repo = "Lemmmy jamROGUE master"


if not term.isColour() then
    error("Use an advanced computer.")
end

printFancy("jamROGUE will install its files to the &3"..installPath.."&0 directory and create a launcher file called &3"..launchPath.."&0.\nIs this ok? &8y/n")
if ({os.pullEvent("char")})[2] ~= "y" then
    printFancy("&eCanceled.")
    return
end

if fs.exists(installPath) then
    printFancy("jamROGUE directory already exists. \nClear it? &8y/n")
    if ({os.pullEvent("char")})[2] ~= "y" then
        printFancy("&eCanceled.")
        return
    end
    fs.delete(installPath)
end
fs.delete(launchPath)

printFancy("Installing jamROGUE...")

local shellDir = shell.dir()
shell.setDir("/")
shell.run("pastebin get "..gitgetPaste.." "..gitgetPath)
shell.run(gitgetPath.." "..repo.." "..repoPath)
shell.run("mv "..repoPath.."/client".." "..installPath)
shell.setDir(shellDir)

printFancy("Decoding asset files...")
local assetsPath = installPath.."/assets"
for _, file in pairs(fs.list(assetsPath)) do
    if file:sub(-4) == ".b64" then
        local data = readFile(assetsPath.."/"..file)
        if data then
            writeFileBinary(assetsPath.."/"..file:sub(1, -5), decodeBase64(data))
        else
            printFancy("&eFailed to decode "..file..", try reinstalling.")
        end
        fs.delete(assetsPath.."/"..file)
    end
end

writeFile(launchPath, "shell.run(\"/.jamrogue/jamrogue.lua\")")

printFancy("Cleaning up installation files...")
fs.delete(repoPath)
fs.delete(gitgetPath)

if fs.exists(installPath) and fs.exists(launchPath) then
    printFancy("Done! Run &5"..launchPath)
else
    printFancy("&eFailed to install jamROGUE.")
end
