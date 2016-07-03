if not term.isColour() then
    error("Use an advanced computer")
end

sleep(0.1)

local version = "0.0"

local versionCheck = http.get("https://raw.githubusercontent.com/Lemmmy/CCJam-2016/master/client/VERSION")
if versionCheck and version ~= versionCheck.readAll() then
    print("Not the latest version - running the updater")
    term.clear()
    term.setCursorPos(1, 1)
    shell.run("pastebin run t9aev7fA")
    return
end

local workingDir = fs.getDir(shell.getRunningProgram())

function resolveFile(file)
	return ((file:sub(1, 1) == "/" or file:sub(1, 1) == "\\") and file) or fs.combine(workingDir, file)
end

local requireCache = {}

function require(file)
    local path = resolveFile(file)

    if requireCache[path] then
        return requireCache[path]
    else
        local env = {
            shell = shell,
            require = require,
            resolveFile = resolveFile
        }

        setmetatable(env, { __index = _G })

        local chunk, err = loadfile(path, env)

        if chunk == nil then
            return error("Error loading file " .. path .. ":\n" .. (err or "N/A"), 0)
        end

        requireCache[path] = chunk()
        return requireCache[path]
    end
end

if not json then
    os.loadAPI(resolveFile("lib/json"))
end

if not blittle then
    os.loadAPI(resolveFile("lib/blittle"))
end

if not framebuffer then
    os.loadAPI(resolveFile("lib/framebuffer"))
end

local function run()
    local main = require("src/main.lua")
end

print(pcall(run))
