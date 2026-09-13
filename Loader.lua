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
    [79268393072444] = "SellLemons.lua",
    [9192423027] = "Industrialist.lua",
}

local gameId = game.GameId

local MarketplaceService = game:GetService("MarketplaceService")

local okInfo, info = pcall(function()
    return MarketplaceService:GetProductInfo(gameId, Enum.InfoType.Game)
end)

local gameName = (okInfo and info and info.Name) or "Unknown Game"
local target = GAME_MAP[gameId]

if not target then
    warn("[Flashy Loader] Game not supported!")
    warn("Game: " .. gameName)
    warn("GameId: " .. tostring(gameId))
    return
end

print(string.format(
    "[Flashy Loader] Detected: %s (GameId %d)",
    gameName,
    gameId
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
    warn("GameId: " .. tostring(gameId))
    warn("Script: " .. target)
    warn("URL: " .. url)
    warn("Error: " .. tostring(result))
    warn("================================")
else
    print("[Flashy Loader] Successfully loaded " .. target)
end
