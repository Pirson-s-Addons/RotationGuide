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

-- Tras cambiar barras hay que volver a pintar el brillo sobre los botones nuevos
function Display.Refresh()
    if glowing then Glow(glowing, false) end
    glowing = nil
    Display.ScanBars()
end
