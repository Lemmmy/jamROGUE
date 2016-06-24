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

return {
    inOutCubic = inOutCubic
}