--[[
    ________           __             _____ __            ___           
   / ____/ /___ ______/ /_  __  __   / ___// /___  ______/ (_)___  _____
  / /_  / / __ `/ ___/ __ \/ / / /   \__ \/ __/ / / / __  / / __ \/ ___/
 / __/ / / /_/ (__  ) / / / /_/ /   ___/ / /_/ /_/ / /_/ / / /_/ (__  )  
/_/   /_/\__,_/____/_/ /_/\__, /   /____/\__/\__,_/\__,_/_/\____/____/  
                         /____/                                         
]]

local BASE_URL = "https://raw.githubusercontent.com/flashyshadowstrike/Flashy-Hub/main/Scripts/"

local GAME_MAP = {
    [9312740628] = "Industrialist.lua",
}

local placeId = game.PlaceId

local MarketplaceService = game:GetService("MarketplaceService")

local okInfo, info = pcall(function()
    return MarketplaceService:GetProductInfo(placeId)
end)

local gameName = (okInfo and info and info.Name) or "Unknown Game"
local target = GAME_MAP[placeId]

if not target then
    warn("[Flashy Loader] Game not supported!")
    warn("Game: " .. gameName)
    warn("PlaceId: " .. tostring(placeId))
    return
end

print(string.format(
    "[Flashy Loader] Detected: %s (PlaceId %d)",
    gameName,
    placeId
))

print("[Flashy Loader] Loading: " .. target)

local url = BASE_URL .. target

local success, result = pcall(function()
    local source = game:HttpGet(url, true)
    local scriptFunction, compileError = loadstring(source)

    if not scriptFunction then
        error("Compilation failed: " .. tostring(compileError))
    end

    return scriptFunction()
end)

if not success then
    warn("================================")
    warn("[Flashy Loader] LOAD FAILED")
    warn("Game: " .. gameName)
    warn("PlaceId: " .. tostring(placeId))
    warn("Script: " .. target)
    warn("URL: " .. url)
    warn("Error: " .. tostring(result))
    warn("================================")
else
    print("[Flashy Loader] Successfully loaded " .. target)
end
