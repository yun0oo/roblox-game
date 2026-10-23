--!strict
-- Numeric look profiles keep biome transitions testable without a renderer.
-- No blur or exposure flashes: enemies, eggs and silhouettes stay readable.
local OceanLook = {}
type Look = { [string]: any }
local function profile(brightness: number, ambient: {number}, outdoor: {number}, fog: {number}, tint: {number}, density: number, haze: number, fogEnd: number): Look
    return { Brightness = brightness, Ambient = ambient, OutdoorAmbient = outdoor, FogColor = fog, TintColor = tint,
        Density = density, Haze = haze, FogEnd = fogEnd, FogStart = 90, Exposure = 0.06, Saturation = 0.045, Contrast = 0.065,
        Diffuse = 0.58, Specular = 1, SunRays = 0.018, Bloom = 0.10 }
end
local biomes: {Look} = {
    profile(2.7, { 76, 116, 131 }, { 160, 204, 213 }, { 29, 120, 156 }, { 237, 251, 255 }, 0.075, 0.35, 430),
    profile(2.55, { 79, 112, 126 }, { 141, 180, 193 }, { 33, 101, 135 }, { 236, 248, 255 }, 0.085, 0.42, 400),
    profile(2.5, { 87, 115, 137 }, { 144, 181, 201 }, { 40, 105, 135 }, { 234, 247, 255 }, 0.09, 0.45, 395),
    profile(2.4, { 91, 113, 142 }, { 133, 161, 195 }, { 43, 76, 116 }, { 235, 242, 255 }, 0.105, 0.55, 365),
    profile(2.35, { 91, 110, 144 }, { 127, 150, 188 }, { 43, 62, 104 }, { 234, 240, 255 }, 0.12, 0.65, 345),
    profile(2.35, { 109, 108, 151 }, { 154, 144, 197 }, { 65, 57, 108 }, { 245, 237, 255 }, 0.125, 0.68, 340),
}
local surface: Look = { Brightness = 3.0, Ambient = { 122, 148, 172 }, OutdoorAmbient = { 185, 204, 219 },
    FogColor = { 173, 220, 240 }, TintColor = { 255, 255, 255 }, Density = 0.15, Haze = 0.5,
    FogEnd = 1900, FogStart = 850, Exposure = 0.02, Saturation = 0.025, Contrast = 0.04,
    Diffuse = 0.78, Specular = 1, SunRays = 0.035, Bloom = 0.08 }
for i, biome in ipairs(biomes) do
    biome.FogStart = 90 - (i - 1) * 4
    biome.Exposure += (i - 1) * 0.014
    biome.SunRays = i == 1 and 0.028 or 0.009
end
local function smooth(value: number): number
    local t = math.clamp(value, 0, 1)
    return t * t * (3 - 2 * t)
end
local function mix(a: Look, b: Look, t: number): Look
    local result: Look = {}
    for key, value in pairs(a) do
        if type(value) == "number" then result[key] = value + (b[key] - value) * t
        else
            result[key] = { value[1] + (b[key][1] - value[1]) * t, value[2] + (b[key][2] - value[2]) * t, value[3] + (b[key][3] - value[3]) * t }
        end
    end
    return result
end
function OceanLook.At(config: any, cameraY: number, lampLevel: number, eventKey: string?): Look
    local depth = math.max(0, config.WaterTop - cameraY)
    local index = 1
    for i, floor in ipairs(config.Floors) do if cameraY <= floor.Top then index = i end end
    local water = mix(biomes[index], biomes[index], 0)
    -- Adjacent floors blend across a 100-stud band, avoiding colour pops at gates.
    for i = 1, #config.Floors - 1 do
        local boundary = config.WaterTop - config.Floors[i].Bottom
        if depth >= boundary - 50 and depth <= boundary + 50 then
            water = mix(biomes[i], biomes[i + 1], smooth((depth - boundary + 50) / 100))
            break
        end
    end
    water.FogEnd += math.clamp(lampLevel - 1, 0, 7) * 8
    local submersion = smooth((config.WaterTop + 3 - cameraY) / 9)
    local result = mix(surface, water, submersion)
    local event = eventKey == "Legendary" and 0.10 or eventKey == "Major" and 0.055 or eventKey == "Minor" and 0.02 or 0
    -- Weather adds a restrained violet accent; it never makes the map black.
    if event > 0 then
        for i, c in ipairs({ 100, 99, 169 }) do result.FogColor[i] += (c - result.FogColor[i]) * event end
        result.Density += event * 0.10 * submersion
        result.FogEnd *= 1 - event * 0.7 * submersion
        result.Brightness -= event * 0.6
        result.Saturation += event * 0.12
    end
    result.Underwater = submersion
    return result
end
return OceanLook
