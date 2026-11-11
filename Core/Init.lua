local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- ARRANQUE, EVENTOS Y COMANDOS
-- ==========================================

local DEFAULTS = {
    enabled = true,
    glow = true,
    icon = true,
    locked = false,
    forceSingle = false,
    point = { "CENTER", "CENTER", 0, -180 },
}

local INTERVAL = 0.1
local Clean = ns.Clean
local rules

local function Print(text)
    print("|cffd597ffRotation Guide|r: " .. text)
end

-- La rama de talentos con mas puntos; sin puntos (nivel bajo), la primera
local function DetectSpec()
    local best, bestPoints = 1, 0
    for index = 1, 3 do
        local ok, _, _, _, _, _, _, points = pcall(C_SpecializationInfo.GetSpecializationInfo, index)
        points = ok and Clean(points)
        if points and points > bestPoints then
            best, bestPoints = index, points
        end
    end
    return best
end

local function LoadRotation()
    local specs = ns.Rotations[ns.class]
    ns.spec = DetectSpec()
    local spec = specs and specs[ns.spec]
    rules = spec and spec.rules
    ns.specName = spec and spec.name
    ns.State.CacheSpellbook()
    ns.State.SetTracking(rules and ns.Engine.TrackIndex(rules) or {})
    ns.Display.Refresh()
end

-- Solo con un enemigo seleccionado: fuera de eso no hay rotacion que seguir
local function HasEnemy()
    return Clean(UnitExists("target")) and Clean(UnitCanAttack("player", "target"))
        and not Clean(UnitIsDead("target"))
end

local elapsed = 0
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed < INTERVAL then return end
    elapsed = 0
    local spellID
    if rules and ns.db.enabled and HasEnemy() then
        spellID = ns.Engine.Next(rules, ns.State)
    end
    ns.Display.Show(spellID)
end)

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("CHARACTER_POINTS_CHANGED")
events:RegisterEvent("PLAYER_TALENT_UPDATE")
events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
events:RegisterEvent("UPDATE_MACROS")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

events:SetScript("OnEvent", function(_, event, arg1, _, arg3)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        RotationGuideDB = RotationGuideDB or {}
        for key, value in pairs(DEFAULTS) do
            if RotationGuideDB[key] == nil then RotationGuideDB[key] = value end
        end
        ns.db = RotationGuideDB
        ns.class = select(2, UnitClass("player"))
    elseif event == "PLAYER_LOGIN" or event == "SPELLS_CHANGED"
        or event == "CHARACTER_POINTS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        if ns.db then LoadRotation() end
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_MACROS" then
        ns.Display.Refresh()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        ns.State.OnCast(arg3)
    elseif event == "PLAYER_TARGET_CHANGED" then
        ns.State.OnTargetChanged()
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.State.ForgetTargets()
    elseif event == "PLAYER_DEAD" then
        ns.State.ForgetAll()
    end
end)

-- ------------------------------------------
-- /rg
-- ------------------------------------------
local function Toggle(key, onText, offText)
    ns.db[key] = not ns.db[key]
    Print(ns.db[key] and onText or offText)
end

SLASH_ROTATIONGUIDE1 = "/rg"
SLASH_ROTATIONGUIDE2 = "/rotationguide"
SlashCmdList.ROTATIONGUIDE = function(message)
    local command = strlower(strtrim(message or ""))
    if command == "" or command == "toggle" then
        Toggle("enabled", L.ON, L.OFF)
    elseif command == "single" then
        Toggle("forceSingle", L.SINGLE_ON, L.SINGLE_OFF)
    elseif command == "icon" then
        Toggle("icon", L.ICON_ON, L.ICON_OFF)
    elseif command == "glow" then
        Toggle("glow", L.GLOW_ON, L.GLOW_OFF)
        ns.Display.Refresh()
    elseif command == "lock" then
        Toggle("locked", L.LOCKED, L.UNLOCKED)
        ns.Display.PlaceIcon()
    elseif command == "reset" then
        ns.db.point = { unpack(DEFAULTS.point) }
        ns.Display.PlaceIcon()
        Print(L.RESET)
    elseif command == "status" then
        Print(format(L.STATUS, ns.class or "?", ns.specName or L.NO_ROTATION, ns.State.Targets()))
    else
        Print(L.HELP)
    end
end
