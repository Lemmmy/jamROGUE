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

local constants = require("src/constants.lua")

local function checkUpdate()
    local repoURL = "https://raw.githubusercontent.com/Lemmmy/jamROGUE/master/client"

    local versionCheck = http.get(repoURL.."/VERSION?" .. textutils.urlEncode(os.clock()))

    if versionCheck then
        local latest = versionCheck.readAll()
        local version = constants.version

        if version ~= latest then
            term.clear()
            term.setCursorPos(1, 1)
            print("Not the latest version - running the updater\n")
            print("Current: " .. version .. " Latest: " .. latest .. "\n")
            local installer = http.get(repoURL.."/installer.lua")
            if installer then
                local inst = loadstring(installer.readAll(), "installer")
                setfenv(inst, getfenv())
                inst()
                return true
            end
        end
    end
end

if not json then os.loadAPI(resolveFile("lib/json")) end
if not blittle then os.loadAPI(resolveFile("lib/blittle")) end
if not framebuffer then os.loadAPI(resolveFile("lib/framebuffer")) end

local function run()
    if not term.isColour() then
        error("Use an advanced computer")
    end
    if checkUpdate() then return end
    local main = require("src/main.lua")
end



local ok, msg = pcall(run)

if not ok then
    print(msg)
end
