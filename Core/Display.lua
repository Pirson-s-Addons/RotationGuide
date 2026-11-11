local ADDON_NAME, ns = ...

-- ==========================================
-- PRESENTACION: brillo en la barra + icono movible
-- ==========================================

local Display = {}
ns.Display = Display

local Clean = ns.Clean

-- Barras de Blizzard; las de otros addons (Bartender, ElvUI...) no se leen.
-- shortcut: solo barras de Blizzard; si un jugador usa otra, el icono sigue sirviendo
local BARS = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button",
    "MultiBar6Button", "MultiBar7Button",
}

local buttonsByName = {}
local glowing

local function SpellNameInSlot(slot)
    if not slot or not Clean(HasAction(slot)) then return nil end
    local kind, id = GetActionInfo(slot)
    kind, id = Clean(kind), Clean(id)
    if kind == "macro" then
        id = Clean(GetMacroSpell(id))
    elseif kind ~= "spell" then
        return nil
    end
    return id and C_Spell.GetSpellName(id)
end

function Display.ScanBars()
    wipe(buttonsByName)
    for _, prefix in ipairs(BARS) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            local name = button and SpellNameInSlot(button.action)
            if name then
                buttonsByName[name] = buttonsByName[name] or {}
                table.insert(buttonsByName[name], button)
            end
        end
    end
end

local function Overlay(button)
    if not button.RotationGuideGlow then
        local glow = button:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        glow:SetBlendMode("ADD")
        glow:SetVertexColor(0.3, 1, 0.3)
        glow:SetPoint("TOPLEFT", -4, 4)
        glow:SetPoint("BOTTOMRIGHT", 4, -4)
        button.RotationGuideGlow = glow
    end
    return button.RotationGuideGlow
end

local function Glow(name, on)
    for _, button in ipairs(buttonsByName[name] or {}) do
        Overlay(button):SetShown(on)
    end
end

-- ------------------------------------------
-- Icono: se arrastra con Mayus pulsada mientras no este bloqueado
-- ------------------------------------------
local icon

local function CreateIcon()
    icon = CreateFrame("Frame", "RotationGuideIcon", UIParent)
    icon:SetSize(48, 48)
    icon:SetFrameStrata("HIGH")
    icon:SetMovable(true)
    icon:EnableMouse(true)
    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnDragStart", function(self)
        if not ns.db.locked and IsShiftKeyDown() then self:StartMoving() end
    end)
    icon:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relative, x, y = self:GetPoint()
        ns.db.point = { point, relative, x, y }
    end)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    Display.PlaceIcon()
end

function Display.PlaceIcon()
    if not icon then return end
    local p = ns.db.point
    icon:ClearAllPoints()
    icon:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    icon:EnableMouse(not ns.db.locked)
end

-- spellID nil = nada que recomendar
function Display.Show(spellID)
    local name = spellID and C_Spell.GetSpellName(spellID)
    if name ~= glowing then
        if glowing then Glow(glowing, false) end
        if name and ns.db.glow then Glow(name, true) end
        glowing = name
    end
    if not ns.db.icon then
        if icon then icon:Hide() end
        return
    end
    if not icon then CreateIcon() end
    if spellID then
        icon.texture:SetTexture(C_Spell.GetSpellTexture(spellID))
        icon:Show()
    else
        icon:Hide()
    end
end

-- ------------------------------------------
-- Cura: la vida es secreta, asi que no se compara en Lua. El juego evalua
-- una curva escalonada (1 por debajo del umbral, 0 por encima) sobre la vida
-- y el resultado secreto va directo a SetAlpha, que si lo acepta.
-- ------------------------------------------
local healCurve, healCurveAt
local healIcon
local healGlowing

local function HealCurve()
    if healCurveAt ~= ns.db.healAt then
        healCurve = C_CurveUtil.CreateCurve()
        healCurve:SetType(Enum.LuaCurveType.Step)
        healCurve:AddPoint(0, 1)
        healCurve:AddPoint(ns.db.healAt / 100, 0)
        healCurveAt = ns.db.healAt
    end
    return healCurve
end

local function HealOverlay(button)
    if not button.RotationGuideHeal then
        local glow = button:CreateTexture(nil, "OVERLAY", nil, 1)
        glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        glow:SetBlendMode("ADD")
        glow:SetVertexColor(1, 0.2, 0.2)
        glow:SetPoint("TOPLEFT", -6, 6)
        glow:SetPoint("BOTTOMRIGHT", 6, -6)
        button.RotationGuideHeal = glow
    end
    return button.RotationGuideHeal
end

local function HealGlow(name, alpha)
    for _, button in ipairs(buttonsByName[name] or {}) do
        local glow = HealOverlay(button)
        if alpha then
            glow:SetAlpha(alpha)
            glow:Show()
        else
            glow:Hide()
        end
    end
end

-- Icono de cura encima del de rotacion: cuando aparece, lo tapa
local function CreateHealIcon()
    healIcon = CreateFrame("Frame", "RotationGuideHealIcon", UIParent)
    healIcon:SetSize(48, 48)
    healIcon:SetFrameStrata("HIGH")
    healIcon:SetFrameLevel(20)
    healIcon:EnableMouse(false)
    healIcon.texture = healIcon:CreateTexture(nil, "ARTWORK")
    healIcon.texture:SetAllPoints()
    local border = healIcon:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    border:SetBlendMode("ADD")
    border:SetVertexColor(1, 0.2, 0.2)
    border:SetPoint("TOPLEFT", -6, 6)
    border:SetPoint("BOTTOMRIGHT", 6, -6)
end

-- spellID nil = sin cura lista (o desactivada con /rg heal 0)
function Display.ShowHeal(spellID)
    local name = spellID and ns.db.healAt > 0 and C_Spell.GetSpellName(spellID) or nil
    if not name then
        if healGlowing then HealGlow(healGlowing, nil) end
        healGlowing = nil
        if healIcon then healIcon:Hide() end
        return
    end
    local alpha = UnitHealthPercent("player", true, HealCurve())
    if healGlowing and healGlowing ~= name then HealGlow(healGlowing, nil) end
    healGlowing = name
    if ns.db.glow then HealGlow(name, alpha) end
    if not ns.db.icon then
        if healIcon then healIcon:Hide() end
        return
    end
    if not icon then
        CreateIcon()
        icon:Hide()
    end
    if not healIcon then
        CreateHealIcon()
        healIcon:SetPoint("CENTER", icon, "CENTER")
    end
    healIcon.texture:SetTexture(C_Spell.GetSpellTexture(spellID))
    healIcon:SetAlpha(alpha)
    healIcon:Show()
end

-- Tras cambiar barras hay que volver a pintar el brillo sobre los botones nuevos
function Display.Refresh()
    if glowing then Glow(glowing, false) end
    glowing = nil
    if healGlowing then HealGlow(healGlowing, nil) end
    healGlowing = nil
    Display.ScanBars()
end
