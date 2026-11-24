local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- OPCIONES
-- ==========================================
-- Raiz "Acerca de" (UI/About.lua) y, colgando de ella, "General" (este panel)
-- y "Mi rotacion" (UI/Editor.lua). Mismo aspecto que HealthBarTextForever.

local HEADER = "|cffC47FF3"
local LOGO = "Interface\\AddOns\\RotationGuide\\img\\logo_rg"

local function AddTooltip(widget, text)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Atenuado: SetEnabled (si es un control) + alpha 0.5
local function SetActive(region, on)
    if region.SetEnabled then region:SetEnabled(on) end
    region:SetAlpha(on and 1 or 0.5)
end

-- Lo que hay que repintar fuera del panel cuando cambia una opcion
local function Apply()
    ns.Display.PlaceIcon()
    ns.Display.Refresh()
end

local function CreateGeneral()
    local panel = CreateFrame("Frame")
    panel:Hide()
    local x = 16
    local refreshers = {}
    local function Refresh()
        if not ns.db then return end
        for _, refresh in ipairs(refreshers) do refresh() end
    end

    local function Label(dx, y, text, template)
        local fs = panel:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
        fs:SetPoint("TOPLEFT", dx, y)
        fs:SetText(text)
        return fs
    end
    local function Line(y)
        local line = panel:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(1, 1, 1, 0.1)
        line:SetSize(580, 1)
        line:SetPoint("TOPLEFT", x, y)
    end
    -- Casilla ligada a ns.db[key]
    local function Checkbox(key, dx, y)
        local cb = CreateFrame("CheckButton", "RotationGuide_" .. key, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", dx, y)
        _G[cb:GetName() .. "Text"]:SetText(L["OPT_" .. key:upper()])
        cb:SetScript("OnClick", function(self)
            ns.db[key] = self:GetChecked() and true or false
            Refresh()
            Apply()
        end)
        AddTooltip(cb, L["OPT_" .. key:upper() .. "_TIP"])
        refreshers[#refreshers + 1] = function() cb:SetChecked(ns.db[key]) end
        return cb
    end

    -- Deslizador ligado a ns.db[key] (mismo aspecto que el de cura)
    local function Slider(key, min, max, step, y, labelKey)
        local name = "RotationGuide_" .. key
        local s = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", x + 10, y)
        s:SetWidth(400)
        s:SetMinMaxValues(min, max)
        s:SetValueStep(step)
        s:SetObeyStepOnDrag(true)
        _G[name .. "Low"]:SetText(min)
        _G[name .. "High"]:SetText(max)
        local function Text()
            _G[name .. "Text"]:SetText(L[labelKey] .. ": " .. ns.db[key])
        end
        s:SetScript("OnValueChanged", function(_, value)
            value = math.floor(value / step + 0.5) * step
            if not ns.db or value == ns.db[key] then return end
            ns.db[key] = value
            Text()
            Apply()
        end)
        AddTooltip(s, L[labelKey .. "_TIP"])
        refreshers[#refreshers + 1] = function()
            s:SetValue(ns.db[key])
            Text()
        end
        return s
    end

    Label(x, -16, L.OPTIONS_TITLE, "GameFontNormalLarge")

    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(110, 110)
    logo:SetPoint("TOPRIGHT", -38, -5)
    logo:SetTexture(LOGO)

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOP", logo, "BOTTOM", 0, -2)
    version:SetText("v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"))

    -- Guia: interruptor general y lo que depende de el
    Label(x, -56, HEADER .. L.SECTION_GUIDE .. "|r", "GameFontNormal")
    local enabled = Checkbox("enabled", x, -81)
    local glow = Checkbox("glow", x + 20, -105)
    local icon = Checkbox("icon", x + 20, -129)
    local locked = Checkbox("locked", x + 40, -153)
    local keybind = Checkbox("keybind", x + 40, -177)
    local single = Checkbox("forceSingle", x + 20, -201)
    refreshers[#refreshers + 1] = function()
        local on = ns.db.enabled
        SetActive(glow, on)
        SetActive(icon, on)
        SetActive(single, on)
        SetActive(locked, on and ns.db.icon)
        SetActive(keybind, on and ns.db.icon)
    end
    Line(-236)

    -- Aviso de cura
    Label(x, -252, HEADER .. L.SECTION_HEAL .. "|r", "GameFontNormal")
    local slider = CreateFrame("Slider", "RotationGuide_HealAt", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x + 10, -286)
    slider:SetWidth(400)
    slider:SetMinMaxValues(0, 100)
    slider:SetValueStep(5)
    slider:SetObeyStepOnDrag(true)
    _G.RotationGuide_HealAtLow:SetText("0")
    _G.RotationGuide_HealAtHigh:SetText("100")
    local function SliderLabel()
        local value = ns.db.healAt
        _G.RotationGuide_HealAtText:SetText(L.OPT_HEAL .. ": " .. (value > 0 and value .. "%" or L.OPT_HEAL_OFF))
    end
    slider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value / 5 + 0.5) * 5
        if not ns.db or value == ns.db.healAt then return end
        ns.db.healAt = value
        SliderLabel()
    end)
    AddTooltip(slider, L.OPT_HEAL_TIP)
    refreshers[#refreshers + 1] = function()
        slider:SetValue(ns.db.healAt)
        SliderLabel()
    end
    Line(-326)

    -- Icono: tamano, tecla (tamano y posicion)
    Label(x, -346, HEADER .. L.SECTION_ICON .. "|r", "GameFontNormal")
    local iconSize = Slider("iconSize", 24, 100, 4, -378, "OPT_ICONSIZE")
    local keySize = Slider("keybindSize", 8, 32, 2, -416, "OPT_KEYBINDSIZE")
    local dropdown = CreateFrame("Frame", "RotationGuide_KeybindPos", panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", x - 16, -446)
    UIDropDownMenu_SetWidth(dropdown, 180)
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, pos in ipairs(ns.Display.POSITIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = L["POS_" .. pos]
            info.checked = ns.db.keybindPos == pos
            info.func = function()
                ns.db.keybindPos = pos
                UIDropDownMenu_SetText(dropdown, L["POS_" .. pos])
                Apply()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    AddTooltip(dropdown, L.OPT_KEYBINDPOS_TIP)
    refreshers[#refreshers + 1] = function()
        UIDropDownMenu_SetText(dropdown, L["POS_" .. ns.db.keybindPos])
        local on = ns.db.enabled and ns.db.icon and ns.db.keybind
        if on then UIDropDownMenu_EnableDropDown(dropdown) else UIDropDownMenu_DisableDropDown(dropdown) end
        SetActive(iconSize, ns.db.enabled and ns.db.icon)
        SetActive(keySize, on)
    end
    Line(-480)

    panel:SetScript("OnShow", Refresh)

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(180, 26)
    reset:SetPoint("TOPLEFT", x, -496)
    reset:SetText(L.DEFAULTS)
    reset:SetScript("OnClick", function()
        for key, value in pairs(ns.DEFAULTS) do
            ns.db[key] = type(value) == "table" and { unpack(value) } or value
        end
        Refresh()
        Apply()
    end)

    return panel
end

local root = ns.CreateAbout({
    name = "Rotation Guide",
    logo = LOGO,
    github = "https://github.com/Pirson-s-Addons/RotationGuide",
    curseforge = "https://www.curseforge.com/wow/addons/rotation-guide",
    commands = {
        { "/rg", L.CMD_OPEN },
        { "/rg toggle", L.CMD_TOGGLE },
        { "/rg editor", L.CMD_EDITOR },
        { "/rg single", L.CMD_SINGLE },
        { "/rg heal <%>", L.CMD_HEAL },
        { "/rg reset", L.CMD_RESET },
        { "/rg status", L.CMD_STATUS },
    },
})
ns.rootCategory = root
ns.generalCategory = Settings.RegisterCanvasLayoutSubcategory(root, CreateGeneral(), L.GENERAL)

function ns.OpenOptions()
    Settings.OpenToCategory(ns.generalCategory:GetID())
end
