local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- OPCIONES: Opciones > AddOns > Rotation Guide > General
-- ==========================================
-- Las mismas casillas que /rg; el desbloqueo no se guarda (dura la sesion).

local Options = {}
ns.Options = Options

local panel = CreateFrame("Frame")
panel:Hide() -- nace oculto: si no, el Show() al abrir la categoria no dispara OnShow
local checks = {}

local function Check(y, label, tooltip, get, set)
    local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 16, y)
    local text = check.Text or check.text
    text:SetFontObject("GameFontHighlight")
    text:SetText(label)
    check:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    check:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    check:SetScript("OnLeave", GameTooltip_Hide)
    check.Refresh = function(self) self:SetChecked(get()) end
    checks[#checks + 1] = check
end

-- Ajuste de RotationGuideDB; after() aplica el cambio en pantalla
local function Setting(key, after)
    return function() return ns.db[key] end, function(on)
        ns.db[key] = on
        if after then after() end
    end
end

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("|cffd597ffRotation Guide|r  ·  " .. L.OPTIONS_TITLE)

Check(-50, L.OPT_ENABLED, L.OPT_ENABLED_TIP, Setting("enabled"))
Check(-80, L.OPT_GLOW, L.OPT_GLOW_TIP, Setting("glow", function() ns.Display.Refresh() end))
Check(-110, L.OPT_ICON, L.OPT_ICON_TIP, Setting("icon"))
Check(-140, L.OPT_KEYBIND, L.OPT_KEYBIND_TIP, Setting("keybind"))
Check(-170, L.OPT_SINGLE, L.OPT_SINGLE_TIP, Setting("forceSingle"))
Check(-200, L.OPT_UNLOCK, L.OPT_UNLOCK_TIP, ns.Display.IsUnlocked, ns.Display.SetUnlocked)

local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
reset:SetSize(180, 24)
reset:SetPoint("TOPLEFT", 20, -240)
reset:SetText(L.OPT_RESET)
reset:SetScript("OnClick", function() SlashCmdList.ROTATIONGUIDE("reset") end)

panel:SetScript("OnShow", function()
    for _, check in ipairs(checks) do check:Refresh() end
end)

-- shortcut: sin la API Settings (cliente antiguo) no hay panel, solo /rg; el editor ya cubre ese caso
local category
if ns.Editor.category then
    category = Settings.RegisterCanvasLayoutSubcategory(ns.Editor.category, panel, L.OPTIONS_TITLE)
end

function Options.Open()
    if category then Settings.OpenToCategory(category:GetID()) end
end
