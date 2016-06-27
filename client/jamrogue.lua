if not term.isColour() then
    error("Use an advanced computer")
end

local workingDir = fs.getDir(shell.getRunningProgram())

function resolveFile(file)
    return fs.combine(workingDir, file)
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

        local chunk, err = loadfile(file, env)

        if chunk == nil then
            return error(err or "N/A", 0)
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

local a = blittle.shrink(paintutils.loadImage(resolveFile("assets/logo")))
blittle.save(a, "assets/logo_little")

local main = require("src/main.lua")