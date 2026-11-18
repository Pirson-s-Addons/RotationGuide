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
    healAt = 40,
    point = { "CENTER", "CENTER", 0, -180 },
}

local INTERVAL = 0.1
local Clean = ns.Clean
local rules, heals

local function Print(text)
    print("|cffd597ffRotation Guide|r: " .. text)
end

-- Puntos en una rama sumando el rango de cada talento: GetTalentInfo devuelve
-- el rango en 5ª posicion en todos los clientes clasicos, mientras que la
-- posicion de los puntos en GetTalentTabInfo / GetSpecializationInfo cambia
-- segun la version (y alguna los da como texto o no los da): eso hacia que
-- Sombras se detectara como Disciplina.
local function TabPoints(tab)
    local total = 0
    local okCount, count = pcall(GetNumTalents, tab)
    count = okCount and tonumber(Clean(count)) or 0
    for index = 1, count do
        local ok, _, _, _, _, rank = pcall(GetTalentInfo, tab, index)
        total = total + (ok and tonumber(Clean(rank)) or 0)
    end
    if total > 0 then return total end
    -- Plan B: la API de especializaciones (puntos en 7ª posicion)
    local ok, _, _, _, _, _, _, points = pcall(C_SpecializationInfo.GetSpecializationInfo, tab)
    return ok and tonumber(Clean(points)) or 0
end
ns.TabPoints = TabPoints

-- La rama de talentos con mas puntos; sin puntos (nivel bajo), la primera
local function DetectSpec()
    local best, bestPoints = 1, 0
    for index = 1, 3 do
        local points = TabPoints(index)
        if points > bestPoints then
            best, bestPoints = index, points
        end
    end
    return best
end

-- El perfil propio en uso para esa rama (nil = la recomendada o perfil vacio)
local function CustomProfile(index)
    local custom = ns.db.custom[index]
    local profile = custom and custom.active and custom.profiles[custom.active]
    return profile and #profile.rules > 0 and profile or nil
end

-- Una rama de tanque en solitario usa la de dano que indique (spec.solo)
local function LoadRotation()
    local specs = ns.Rotations[ns.class]
    ns.spec = DetectSpec()
    local spec = specs and specs[ns.spec]
    ns.specName = spec and spec.name
    local profile = CustomProfile(ns.spec)
    rules = profile and profile.rules
    if profile then
        ns.specName = (ns.specName or "?") .. " (" .. format(L.PROFILE_IN_USE, profile.name) .. ")"
    else
        if spec and spec.solo and not IsInGroup() then
            spec = specs[spec.solo]
            ns.specName = ns.specName .. " -> " .. spec.name .. " (solo)"
        end
        rules = spec and spec.rules
    end
    heals = ns.Heals[ns.class] or {}
    ns.State.CacheSpellbook()
    ns.State.SetTracking(ns.Engine.TrackIndex(ns.Engine.Join(rules or {}, heals)))
    ns.Display.Refresh()
end
ns.LoadRotation = LoadRotation

local elapsed = 0
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed < INTERVAL then return end
    elapsed = 0
    local spellID, healID
    if rules and ns.db.enabled then
        spellID = ns.Engine.Next(rules, ns.State)
        healID = ns.db.healAt > 0 and ns.Engine.Next(heals, ns.State, true) or nil
    end
    ns.nextSpell, ns.nextHeal = spellID, healID
    ns.Display.Show(spellID)
    ns.Display.ShowHeal(healID)
end)

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("CHARACTER_POINTS_CHANGED")
events:RegisterEvent("PLAYER_TALENT_UPDATE")
events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
events:RegisterEvent("UPDATE_MACROS")
events:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

events:SetScript("OnEvent", function(_, event, arg1, _, arg3)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        RotationGuideDB = RotationGuideDB or {}
        for key, value in pairs(DEFAULTS) do
            if RotationGuideDB[key] == nil then RotationGuideDB[key] = value end
        end
        -- Tabla propia: DEFAULTS no puede repartir la misma tabla entre personajes
        RotationGuideDB.custom = RotationGuideDB.custom or {}
        ns.db = RotationGuideDB
        ns.class = select(2, UnitClass("player"))
    elseif event == "PLAYER_LOGIN" or event == "SPELLS_CHANGED"
        or event == "CHARACTER_POINTS_CHANGED" or event == "PLAYER_TALENT_UPDATE"
        or event == "GROUP_ROSTER_UPDATE" then
        if ns.db then LoadRotation() end
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_MACROS"
        or event == "UPDATE_SHAPESHIFT_FORMS" then
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
    local command, value = strlower(strtrim(message or "")):match("^(%S*)%s*(.-)$")
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
    elseif command == "heal" then
        local percent = tonumber(value)
        if percent and percent >= 0 and percent <= 100 then
            ns.db.healAt = math.floor(percent)
        end
        Print(ns.db.healAt > 0 and format(L.HEAL_AT, ns.db.healAt) or L.HEAL_OFF)
    elseif command == "editor" or command == "config" then
        ns.Editor.Open()
    elseif command == "status" then
        local points = ns.TabPoints(1) .. "/" .. ns.TabPoints(2) .. "/" .. ns.TabPoints(3)
        Print(format(L.STATUS, ns.class or "?", ns.specName or L.NO_ROTATION, points, ns.State.Targets()))
    else
        Print(L.HELP)
    end
end
