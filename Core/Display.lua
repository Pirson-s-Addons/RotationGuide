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
    -- Barra de posturas: auras de paladin, posturas, formas de druida, sigilo
    for i = 1, 10 do
        local button = _G["StanceButton" .. i]
        local id = button and Clean((select(4, GetShapeshiftFormInfo(button:GetID()))))
        local name = id and C_Spell.GetSpellName(id)
        if name then
            buttonsByName[name] = buttonsByName[name] or {}
            table.insert(buttonsByName[name], button)
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

-- Tecla del primer boton de la barra con ese hechizo; Blizzard ya la abrevia
-- en button.HotKey y pone RANGE_INDICATOR cuando no hay tecla
local function KeyFor(name)
    for _, button in ipairs(buttonsByName[name] or {}) do
        local text = button.HotKey and Clean(button.HotKey:GetText())
        if text and text ~= "" and text ~= RANGE_INDICATOR then return text end
    end
    return ""
end

local function AddKeybind(frame)
    frame.keybind = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    frame.keybind:SetPoint("TOPRIGHT", -3, -3)
end

local function ShowKey(frame, name)
    frame.keybind:SetText(ns.db.keybind and name and KeyFor(name) or "")
end

-- ------------------------------------------
-- Icono: desbloqueado (/rg unlock) se ve siempre y se arrastra, como DR Tracker
-- ------------------------------------------
local icon
local unlocked = false -- solo esta sesion: al entrar al juego siempre bloqueado
local SAMPLE = "Interface\\Icons\\INV_Misc_QuestionMark"

local function CreateIcon()
    icon = CreateFrame("Frame", "RotationGuideIcon", UIParent)
    icon:SetSize(48, 48)
    icon:SetFrameStrata("HIGH")
    icon:SetMovable(true)
    icon:SetClampedToScreen(true)
    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnDragStart", icon.StartMoving)
    icon:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relative, x, y = self:GetPoint()
        ns.db.point = { point, relative, x, y }
    end)
    icon.background = icon:CreateTexture(nil, "BACKGROUND")
    icon.background:SetPoint("TOPLEFT", -4, 4)
    icon.background:SetPoint("BOTTOMRIGHT", 4, -4)
    icon.background:SetColorTexture(0.77, 0.5, 0.95, 0.35)
    icon.label = icon:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    icon.label:SetPoint("BOTTOM", icon, "TOP", 0, 6)
    icon.label:SetText(ns.L.DRAG_HINT)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    AddKeybind(icon)
    Display.PlaceIcon()
end

function Display.PlaceIcon()
    if not icon then return end
    local p = ns.db.point
    icon:ClearAllPoints()
    icon:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    icon:EnableMouse(unlocked)
    icon.background:SetShown(unlocked)
    icon.label:SetShown(unlocked)
end

function Display.IsUnlocked() return unlocked end

function Display.SetUnlocked(on)
    unlocked = on
    if not icon then CreateIcon() end
    Display.PlaceIcon()
    Display.Show(ns.nextSpell)
end

-- spellID nil = nada que recomendar
function Display.Show(spellID)
    local name = spellID and C_Spell.GetSpellName(spellID)
    if name ~= glowing then
        if glowing then Glow(glowing, false) end
        if name and ns.db.glow then Glow(name, true) end
        glowing = name
    end
    if not ns.db.icon and not unlocked then
        if icon then icon:Hide() end
        return
    end
    if not icon then CreateIcon() end
    if not spellID and not unlocked then
        icon:Hide()
        return
    end
    icon.texture:SetTexture(spellID and C_Spell.GetSpellTexture(spellID) or SAMPLE)
    ShowKey(icon, name)
    icon:Show()
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
    AddKeybind(healIcon)
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
    ShowKey(healIcon, name)
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
