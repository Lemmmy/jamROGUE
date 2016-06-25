local pow, sin, cos, pi, sqrt, abs, asin = math.pow, math.sin, math.cos, math.pi, math.sqrt, math.abs, math.asin

local function outQuint(t, b, c, d)
    return c * (pow(t / d - 1, 5) + 1) + b
end

return {
    outQuint = outQuint
}