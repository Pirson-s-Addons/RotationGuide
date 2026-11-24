local ADDON_NAME, ns = ...
local L = ns.L

-- ==========================================
-- EDITOR DE ROTACIONES (Opciones > AddOns > Rotation Guide, o /rg editor)
-- ==========================================
-- Cada rama tiene perfiles: la Recomendada (la del addon, solo lectura) y
-- los del jugador (propios o importados de un codigo). El perfil elegido es
-- el que se usa. Tres columnas: hechizos del libro -> rotacion por
-- prioridad -> condiciones del hechizo elegido.
-- Se guarda por personaje: RotationGuideDB.custom[rama] =
--   { active = indice o nil (Recomendada), profiles = { { name, rules }, ... } }

local Editor = {}
ns.Editor = Editor

local Custom = ns.Custom
local panel, category, built
local specIndex = 1    -- rama que se esta viendo
local selected         -- indice de la regla elegida en la rotacion
local ui = {}

local BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- Campos que el panel no edita: se conservan y se cuentan como "avanzados"
local ADVANCED = { aura = 1, max = 1, has = 1, hasStacks = 1, stacksBelow = 1, notForm = 1, ifUnknown = 1, noImbue = 1 }

-- ------------------------------------------
-- Datos
-- ------------------------------------------
local function Store()
    local custom = ns.db.custom
    custom[specIndex] = custom[specIndex] or { profiles = {} }
    return custom[specIndex]
end

-- Perfil propio en uso (nil = Recomendada)
local function Profile()
    local store = Store()
    return store.active and store.profiles[store.active]
end

local function DefaultRules()
    local spec = ns.Rotations[ns.class] and ns.Rotations[ns.class][specIndex]
    return spec and spec.rules or {}
end

-- Lo que se ve: el perfil o la Recomendada
local function Rules()
    local profile = Profile()
    return profile and profile.rules or DefaultRules()
end

local function Rule()
    return selected and Rules()[selected]
end

local function ProfileName()
    local profile = Profile()
    return profile and profile.name or L.RECOMMENDED
end

local function Changed()
    ns.LoadRotation()
    Editor.Refresh()
end

local function Message(text, r, g, b)
    ui.message:SetText(text or "")
    ui.message:SetTextColor(r or 0.6, g or 1, b or 0.6)
end

-- La Recomendada no se toca: hay que crear un perfil
local function Editable()
    if Profile() then return true end
    Message(L.NEED_PROFILE, 1, 0.82, 0)
    return false
end

-- "Juan" -> "Juan (2)" si ya existe
local function UniqueName(name)
    name = Custom.CleanName(name)
    if name == "" then name = L.MY_PROFILE end
    local taken = {}
    for _, profile in ipairs(Store().profiles) do taken[profile.name] = true end
    local unique, n = name, 2
    while taken[unique] do
        unique = name .. " (" .. n .. ")"
        n = n + 1
    end
    return unique
end

local function AddProfile(name, rules)
    local store = Store()
    table.insert(store.profiles, { name = UniqueName(name), rules = rules })
    store.active = #store.profiles
    selected = nil
    Changed()
    return store.profiles[store.active]
end

local function Tags(rule)
    local tags = {}
    local function Add(text) table.insert(tags, text) end
    if rule.ooc then Add(L.TAG_OOC) end
    if rule.missing then Add(format(L.TAG_MISSING, rule.dur or 0)) end
    if rule.aoe then Add(format(L.TAG_AOE, rule.aoe)) end
    if rule.single then Add(L.TAG_SINGLE) end
    if rule.melee == true then Add(L.TAG_MELEE) elseif rule.melee == false then Add(L.TAG_RANGED) end
    if rule.cp then Add(format(L.TAG_CP, rule.cp)) end
    if rule.elite then Add(L.TAG_ELITE) end
    if rule.lowMana then Add(L.TAG_LOWMANA) end
    if rule.group == true then Add(L.TAG_GROUP) elseif rule.group == false then Add(L.TAG_SOLO) end
    if rule.noPet then Add(L.TAG_NOPET) end
    if rule.stealth then Add(L.TAG_STEALTH) end
    if rule.form then Add(format(L.TAG_FORM, rule.form)) end
    local extra = 0
    for key in pairs(rule) do if ADVANCED[key] then extra = extra + 1 end end
    if extra > 0 then Add(format(L.TAG_EXTRA, extra)) end
    return #tags > 0 and table.concat(tags, " · ") or L.TAG_ALWAYS
end

-- ------------------------------------------
-- Piezas de interfaz
-- ------------------------------------------
local function Backdrop(frame, alpha)
    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(0.04, 0.04, 0.07, alpha or 0.8)
    frame:SetBackdropBorderColor(0.45, 0.45, 0.5, 1)
end

local function Button(parent, text, width)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 120, 22)
    button:SetText(text)
    return button
end

local function Tooltip(frame, title, text)
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 0.82, 0)
        if text then GameTooltip:AddLine(text, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", GameTooltip_Hide)
end

local function Label(parent, text, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    label:SetText(text)
    label:SetJustifyH("LEFT")
    return label
end

local function Check(parent, text, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    local label = check.Text or check.text
    label:SetFontObject("GameFontHighlightSmall")
    label:SetText(text)
    check:SetScript("OnClick", function(self) onClick(self:GetChecked() and true or false) end)
    return check
end

-- Caja de numeros: vacia o 0 = sin condicion (nil)
local function NumberBox(parent, onCommit)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(40, 20)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(4)
    box:SetJustifyH("CENTER")
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function(self)
        local value = tonumber(self:GetText())
        onCommit(value and value > 0 and value or nil)
    end)
    return box
end

-- Lista con scroll; las filas se reutilizan
local function ScrollList(box, name, top, rowHeight, makeRow)
    local scroll = CreateFrame("ScrollFrame", name, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, top)
    scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    scroll:SetScript("OnSizeChanged", function(_, width) child:SetWidth(width) end)
    local list = { rows = {} }
    function list.Fill(count, fill)
        child:SetWidth(scroll:GetWidth())
        for i = 1, count do
            local row = list.rows[i]
            if not row then
                row = makeRow(child)
                row:SetHeight(rowHeight)
                row:SetPoint("TOPLEFT", 0, -(i - 1) * rowHeight)
                row:SetPoint("RIGHT", child, "RIGHT")
                list.rows[i] = row
            end
            fill(row, i)
            row:Show()
        end
        for i = count + 1, #list.rows do list.rows[i]:Hide() end
        child:SetHeight(math.max(count * rowHeight, 1))
    end
    return list
end

local function Column(title)
    local box = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    Backdrop(box)
    box.title = Label(box, title, "GameFontNormal")
    box.title:SetPoint("BOTTOMLEFT", box, "TOPLEFT", 4, 4)
    return box
end

local function SpellIcon(parent, size)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(size, size)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    return icon
end

local function SpellTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(self.spellID)
    if self.hint then GameTooltip:AddLine(self.hint, 0.4, 1, 0.4, true) end
    GameTooltip:Show()
end

-- ------------------------------------------
-- Ventanas emergentes: confirmar y pedir un nombre
-- ------------------------------------------
local function PopupEditBox(dialog)
    return dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox
end

StaticPopupDialogs.ROTATIONGUIDE_CONFIRM = {
    text = "%s", button1 = YES, button2 = NO,
    OnAccept = function(self) self.data() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs.ROTATIONGUIDE_NAME = {
    text = "%s", button1 = ACCEPT, button2 = CANCEL,
    hasEditBox = true, maxLetters = 24,
    OnShow = function(self)
        local box = PopupEditBox(self)
        box:SetText(self.data.name or "")
        box:HighlightText()
        box:SetFocus()
    end,
    OnAccept = function(self) self.data.accept(PopupEditBox(self):GetText()) end,
    -- Segun la version el dato llega como argumento o en el dialogo padre
    EditBoxOnEnterPressed = function(box, data)
        data = data or box:GetParent().data
        data.accept(box:GetText())
        StaticPopup_Hide("ROTATIONGUIDE_NAME")
    end,
    EditBoxOnEscapePressed = function() StaticPopup_Hide("ROTATIONGUIDE_NAME") end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local function AskName(text, name, accept)
    StaticPopup_Show("ROTATIONGUIDE_NAME", text, nil, { name = name, accept = accept })
end

local function Confirm(text, action)
    StaticPopup_Show("ROTATIONGUIDE_CONFIRM", text, nil, action)
end

-- ------------------------------------------
-- Acciones sobre la rotacion
-- ------------------------------------------
-- Debajo del hechizo elegido o al final
local function AddSpell(id)
    if not Editable() then return end
    local rules = Profile().rules
    local at = selected and selected + 1 or #rules + 1
    table.insert(rules, at, { spell = id })
    selected = at
    Changed()
end

local function Move(index, delta)
    if not Editable() then return end
    local rules = Profile().rules
    local to = index + delta
    if to < 1 or to > #rules then return end
    rules[index], rules[to] = rules[to], rules[index]
    selected = to
    Changed()
end

local function Remove(index)
    if not Editable() then return end
    table.remove(Profile().rules, index)
    if selected == index then selected = nil elseif selected and selected > index then selected = selected - 1 end
    Changed()
end

local function Set(key, value)
    local rule = Rule()
    if not rule or not Editable() then return end
    rule[key] = value
    Changed()
end

-- ------------------------------------------
-- Acciones sobre perfiles
-- ------------------------------------------
-- Nuevo: copia de lo que se ve (Recomendada u otro perfil) para no empezar de cero
local function NewProfile()
    AskName(L.ASK_NEW, UniqueName(L.MY_PROFILE), function(name)
        AddProfile(name, Custom.CopyRules(Rules()))
        Message(format(L.CREATED, ProfileName()))
    end)
end

local function RenameProfile()
    local profile = Profile()
    if not Editable() then return end
    AskName(L.ASK_RENAME, profile.name, function(name)
        profile.name = ""  -- que no choque consigo mismo
        profile.name = UniqueName(name)
        Changed()
    end)
end

local function DeleteProfile()
    if not Editable() then return end
    Confirm(format(L.CONFIRM_DELETE, ProfileName()), function()
        local store = Store()
        table.remove(store.profiles, store.active)
        store.active, selected = nil, nil
        Changed()
    end)
end

local function UseProfile(index)
    Store().active = index
    selected = nil
    Message(format(L.USING, ProfileName()))
    Changed()
end

-- Menu desplegable de perfiles (propio: sin depender de la version del cliente)
local menu

local function OpenMenu()
    if menu and menu:IsShown() then return menu:Hide() end
    if not menu then
        menu = CreateFrame("Frame", "RotationGuideProfileMenu", ui.profile, "BackdropTemplate")
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:SetPoint("TOPLEFT", ui.profile, "BOTTOMLEFT", 0, -2)
        menu:SetWidth(220)
        Backdrop(menu, 0.97)
        menu.rows = {}
        table.insert(UISpecialFrames, "RotationGuideProfileMenu")
    end
    local store = Store()
    local count = #store.profiles + 1
    for i = 1, count do
        local row = menu.rows[i]
        if not row then
            row = CreateFrame("Button", nil, menu)
            row:SetHeight(20)
            row:SetPoint("TOPLEFT", 6, -6 - (i - 1) * 20)
            row:SetPoint("RIGHT", -6, 0)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            row.text = Label(row, "", "GameFontHighlightSmall")
            row.text:SetPoint("LEFT", 6, 0)
            row.text:SetPoint("RIGHT", -4, 0)
            row.text:SetWordWrap(false)
            row:SetScript("OnClick", function(self)
                menu:Hide()
                UseProfile(self.profile)
            end)
            menu.rows[i] = row
        end
        -- Fila 1: Recomendada (profile nil); el resto, los perfiles
        local profile = i > 1 and i - 1 or nil
        local name = profile and store.profiles[profile].name or (L.RECOMMENDED .. " |cff888888" .. L.RECOMMENDED_NOTE .. "|r")
        row.profile = profile
        row.text:SetText(name)
        if profile == store.active then row.text:SetTextColor(1, 0.82, 0) else row.text:SetTextColor(1, 1, 1) end
        row:Show()
    end
    for i = count + 1, #menu.rows do menu.rows[i]:Hide() end
    menu:SetHeight(12 + count * 20)
    menu:Show()
end

-- ------------------------------------------
-- Importar / exportar: un codigo de una linea
-- ------------------------------------------
local share

local function CreateShare()
    share = CreateFrame("Frame", "RotationGuideShare", UIParent, "BackdropTemplate")
    share:SetSize(480, 270)
    share:SetPoint("CENTER")
    share:SetFrameStrata("FULLSCREEN_DIALOG")
    share:EnableMouse(true)
    Backdrop(share, 0.97)
    table.insert(UISpecialFrames, "RotationGuideShare")  -- Esc la cierra

    share.title = Label(share, "", "GameFontNormalLarge")
    share.title:SetPoint("TOPLEFT", 16, -14)
    share.help = Label(share, "")
    share.help:SetPoint("TOPLEFT", share.title, "BOTTOMLEFT", 0, -6)
    share.help:SetPoint("RIGHT", -16, 0)

    local box = CreateFrame("Frame", nil, share, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 14, -66)
    box:SetPoint("BOTTOMRIGHT", -14, 66)
    Backdrop(box, 0.9)
    local scroll = CreateFrame("ScrollFrame", "RotationGuideShareScroll", box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetWidth(400)
    edit:SetScript("OnEscapePressed", function() share:Hide() end)
    scroll:SetScrollChild(edit)
    box:SetScript("OnMouseDown", function() edit:SetFocus() end)
    share.edit = edit

    share.status = Label(share, "")
    share.status:SetPoint("BOTTOMLEFT", 16, 44)
    share.status:SetPoint("RIGHT", -16, 0)

    share.action = Button(share, L.IMPORT, 120)
    share.action:SetPoint("BOTTOMRIGHT", -132, 14)
    local close = Button(share, CLOSE, 110)
    close:SetPoint("BOTTOMRIGHT", -16, 14)
    close:SetScript("OnClick", function() share:Hide() end)
end

local function Fail(text)
    share.status:SetText(text)
    share.status:SetTextColor(1, 0.3, 0.3)
end

local function ImportCode()
    local class, spec, rules, name = Custom.Decode(share.edit:GetText())
    if not class then
        -- en el error, spec es el codigo y rules el numero de regla
        return Fail(format(L["IMPORT_" .. string.upper(spec)], rules or 0))
    end
    if class ~= ns.class then return Fail(format(L.IMPORT_CLASS, class)) end
    -- Se guarda en la rama abierta aunque el codigo venga de otra: decide el jugador
    share:Hide()
    AddProfile(name ~= "" and name or L.IMPORTED_PROFILE, rules)
    Message(format(L.IMPORTED, ProfileName(), #rules))
end

local function OpenShare(export)
    if not share then CreateShare() end
    share.status:SetText("")
    share.action:SetShown(not export)
    local specName = ns.Rotations[ns.class][specIndex].name
    if export then
        share.title:SetText(format(L.EXPORT_TITLE, ProfileName()))
        share.help:SetText(L.EXPORT_HELP)
        share.edit:SetText(Custom.Encode(ns.class, specIndex, ProfileName(), Rules()))
        share:Show()
        share.edit:SetFocus()
        share.edit:HighlightText()
    else
        share.title:SetText(L.IMPORT_TITLE)
        share.help:SetText(format(L.IMPORT_HELP, specName))
        share.edit:SetText("")
        share.action:SetScript("OnClick", ImportCode)
        share:Show()
        share.edit:SetFocus()
    end
end

-- ------------------------------------------
-- Construccion del panel
-- ------------------------------------------
local function BuildHeader()
    local title = Label(panel, "|cffd597ffRotation Guide|r  ·  " .. L.EDITOR_TITLE, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    local help = Label(panel, L.EDITOR_HELP)
    help:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    help:SetPoint("RIGHT", -16, 0)
    help:SetTextColor(0.8, 0.8, 0.8)

    local specLabel = Label(panel, L.SPEC, "GameFontNormal")
    specLabel:SetPoint("TOPLEFT", 16, -80)
    ui.tabs = {}
    for index = 1, 3 do
        local tab = Button(panel, "", 112)
        tab:SetPoint("TOPLEFT", 74 + (index - 1) * 116, -76)
        tab:SetScript("OnClick", function()
            specIndex, selected = index, nil
            if menu then menu:Hide() end
            Message("")
            Editor.Refresh()
        end)
        Tooltip(tab, L.SPEC, L.SPEC_TIP)
        ui.tabs[index] = tab
    end

    local profileLabel = Label(panel, L.PROFILE, "GameFontNormal")
    profileLabel:SetPoint("TOPLEFT", 16, -108)
    local profile = CreateFrame("Button", nil, panel, "BackdropTemplate")
    profile:SetSize(220, 24)
    profile:SetPoint("TOPLEFT", 74, -102)
    Backdrop(profile, 0.9)
    profile:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    profile.text = Label(profile, "", "GameFontHighlight")
    profile.text:SetPoint("LEFT", 8, 0)
    profile.text:SetPoint("RIGHT", -22, 0)
    profile.text:SetWordWrap(false)
    local arrow = profile:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    arrow:SetSize(18, 18)
    arrow:SetPoint("RIGHT", -3, 0)
    profile:SetScript("OnClick", OpenMenu)
    Tooltip(profile, L.PROFILE, L.PROFILE_TIP)
    ui.profile = profile

    local new = Button(panel, L.NEW, 80)
    new:SetPoint("LEFT", profile, "RIGHT", 8, 0)
    new:SetScript("OnClick", NewProfile)
    Tooltip(new, L.NEW, L.NEW_TIP)
    ui.rename = Button(panel, L.RENAME, 90)
    ui.rename:SetPoint("LEFT", new, "RIGHT", 4, 0)
    ui.rename:SetScript("OnClick", RenameProfile)
    ui.delete = Button(panel, DELETE, 80)
    ui.delete:SetPoint("LEFT", ui.rename, "RIGHT", 4, 0)
    ui.delete:SetScript("OnClick", DeleteProfile)
end

local function BuildSpells()
    local box = Column(L.SPELLS)
    ui.spellBox = box
    local search = CreateFrame("EditBox", nil, box, "InputBoxTemplate")
    search:SetPoint("TOPLEFT", 14, -8)
    search:SetPoint("RIGHT", -8, 0)
    search:SetHeight(20)
    search:SetAutoFocus(false)
    local placeholder = Label(search, L.SEARCH)
    placeholder:SetPoint("LEFT", 2, 0)
    placeholder:SetTextColor(0.5, 0.5, 0.5)
    search:SetScript("OnTextChanged", function(self)
        placeholder:SetShown(self:GetText() == "")
        Editor.RefreshSpells()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    ui.search = search

    ui.spellList = ScrollList(box, "RotationGuideSpellScroll", -34, 24, function(parent)
        local row = CreateFrame("Button", nil, parent)
        row.icon = SpellIcon(row, 20)
        row.icon:SetPoint("LEFT", 2, 0)
        row.name = Label(row, "")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.name:SetPoint("RIGHT", -2, 0)
        row.name:SetWordWrap(false)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.hint = L.ADD_HINT
        row:SetScript("OnEnter", SpellTooltip)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:SetScript("OnClick", function(self) AddSpell(self.spellID) end)
        return row
    end)
end

local function BuildRotation()
    local box = Column(L.ROTATION)
    ui.rotationBox = box
    ui.empty = Label(box, L.EMPTY)
    ui.empty:SetPoint("TOPLEFT", 12, -12)
    ui.empty:SetPoint("RIGHT", -12, 0)
    ui.empty:SetTextColor(0.6, 0.6, 0.6)

    local function Small(row, texture, x)
        local button = CreateFrame("Button", nil, row)
        button:SetSize(18, 18)
        button:SetPoint("RIGHT", x, 0)
        button:SetNormalTexture(texture .. "-Up")
        button:SetPushedTexture(texture .. "-Down")
        button:SetHighlightTexture(texture .. "-Highlight", "ADD")
        return button
    end

    ui.ruleList = ScrollList(box, "RotationGuideRuleScroll", -6, 36, function(parent)
        local row = CreateFrame("Button", nil, parent)
        row.selected = row:CreateTexture(nil, "BACKGROUND")
        row.selected:SetAllPoints()
        row.selected:SetColorTexture(1, 0.82, 0, 0.14)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.number = Label(row, "", "GameFontNormalSmall")
        row.number:SetPoint("LEFT", 2, 0)
        row.number:SetWidth(18)
        row.number:SetJustifyH("RIGHT")
        row.icon = SpellIcon(row, 26)
        row.icon:SetPoint("LEFT", 24, 0)
        row.remove = Small(row, "Interface\\Buttons\\UI-GroupLoot-Pass", -2)
        row.down = Small(row, "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton", -20)
        row.up = Small(row, "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton", -38)
        row.name = Label(row, "", "GameFontHighlight")
        row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, 0)
        row.name:SetPoint("RIGHT", -58, 0)
        row.name:SetWordWrap(false)
        row.tags = Label(row, "", "GameFontDisableSmall")
        row.tags:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 6, 0)
        row.tags:SetPoint("RIGHT", -58, 0)
        row.tags:SetWordWrap(false)
        row:SetScript("OnEnter", SpellTooltip)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:SetScript("OnClick", function(self)
            selected = self.index
            Editor.Refresh()
        end)
        row.up:SetScript("OnClick", function() Move(row.index, -1) end)
        row.down:SetScript("OnClick", function() Move(row.index, 1) end)
        row.remove:SetScript("OnClick", function() Remove(row.index) end)
        return row
    end)
end

-- Boton que recorre valores: { { value, text }, ... }
local function Cycle(parent, key, options, width)
    local button = Button(parent, "", width or 130)
    button:SetScript("OnClick", function()
        local rule = Rule()
        if not rule then return end
        for i, option in ipairs(options) do
            if rule[key] == option[1] then
                return Set(key, options[i % #options + 1][1])
            end
        end
        Set(key, options[1][1])
    end)
    function button.Update(rule)
        for _, option in ipairs(options) do
            if rule[key] == option[1] then return button:SetText(option[2]) end
        end
        button:SetText(options[1][2])
    end
    return button
end

local function BuildConditions()
    local box = Column(L.CONDITIONS)
    ui.conditionBox = box
    ui.pick = Label(box, "")
    ui.pick:SetPoint("TOPLEFT", 12, -12)
    ui.pick:SetPoint("RIGHT", -12, 0)
    ui.pick:SetTextColor(0.6, 0.6, 0.6)

    local body = CreateFrame("Frame", nil, box)
    body:SetPoint("TOPLEFT", 8, -8)
    body:SetPoint("BOTTOMRIGHT", -8, 8)
    ui.body = body

    ui.icon = SpellIcon(body, 28)
    ui.icon:SetPoint("TOPLEFT", 2, -2)
    ui.name = Label(body, "", "GameFontNormal")
    ui.name:SetPoint("LEFT", ui.icon, "RIGHT", 8, 0)
    ui.name:SetPoint("RIGHT", -2, 0)
    ui.name:SetWordWrap(false)

    local y = -38
    ui.missing = Check(body, L.C_MISSING, function(on)
        local rule = Rule()
        if on and rule and not rule.dur then rule.dur = 15 end
        Set("missing", on or nil)
    end)
    ui.missing:SetPoint("TOPLEFT", 0, y)
    Tooltip(ui.missing, L.C_MISSING, L.C_MISSING_TIP)
    y = y - 24
    local durLabel = Label(body, L.C_DURATION)
    durLabel:SetPoint("TOPLEFT", 26, y - 4)
    ui.dur = NumberBox(body, function(value) Set("dur", value) end)
    ui.dur:SetPoint("LEFT", durLabel, "RIGHT", 8, 0)
    ui.on = Cycle(body, "on", { { nil, L.ON_TARGET }, { "player", L.ON_PLAYER } }, 92)
    ui.on:SetPoint("LEFT", ui.dur, "RIGHT", 6, 0)
    y = y - 30

    local function NumberRow(text, key, tip)
        local label = Label(body, text)
        label:SetPoint("TOPLEFT", 4, y - 4)
        local field = NumberBox(body, function(value) Set(key, value) end)
        field:SetPoint("TOPRIGHT", -4, y)
        if tip then Tooltip(field, text, tip) end
        y = y - 26
        return field
    end
    ui.aoe = NumberRow(L.C_AOE, "aoe", L.C_AOE_TIP)
    ui.cp = NumberRow(L.C_CP, "cp")

    local rangeLabel = Label(body, L.C_RANGE)
    rangeLabel:SetPoint("TOPLEFT", 4, y - 5)
    ui.melee = Cycle(body, "melee", { { nil, L.ANY }, { true, L.MELEE }, { false, L.RANGED } })
    ui.melee:SetPoint("TOPRIGHT", -2, y)
    y = y - 28

    ui.checks = {}
    for _, entry in ipairs({
        { "elite", L.C_ELITE }, { "ooc", L.C_OOC, L.C_OOC_TIP }, { "lowMana", L.C_LOWMANA },
        { "group", L.C_GROUP }, { "noPet", L.C_NOPET }, { "stealth", L.C_STEALTH },
    }) do
        local key = entry[1]
        local check = Check(body, entry[2], function(on) Set(key, on or nil) end)
        check:SetPoint("TOPLEFT", 0, y)
        if entry[3] then Tooltip(check, entry[2], entry[3]) end
        ui.checks[key] = check
        y = y - 22
    end

    ui.form = Button(body, "", 170)
    ui.form:SetPoint("TOPLEFT", 4, y - 4)
    ui.form:SetScript("OnClick", function()
        local rule = Rule()
        if not rule then return end
        if rule.form ~= nil then Set("form", nil) else Set("form", ns.State.Form()) end
    end)
    Tooltip(ui.form, L.C_FORM, L.C_FORM_TIP)
    y = y - 32

    ui.advanced = Label(body, "", "GameFontDisableSmall")
    ui.advanced:SetPoint("TOPLEFT", 4, y)
    ui.advanced:SetPoint("RIGHT", -4, 0)
end

local function BuildFooter()
    local export = Button(panel, L.EXPORT, 110)
    export:SetPoint("BOTTOMRIGHT", -16, 12)
    export:SetScript("OnClick", function() OpenShare(true) end)
    Tooltip(export, L.EXPORT, L.EXPORT_TIP)
    local import = Button(panel, L.IMPORT, 110)
    import:SetPoint("RIGHT", export, "LEFT", -6, 0)
    import:SetScript("OnClick", function() OpenShare(false) end)
    Tooltip(import, L.IMPORT, L.IMPORT_TIP)
    ui.message = Label(panel, "")
    ui.message:SetPoint("BOTTOMLEFT", 18, 17)
    ui.message:SetPoint("RIGHT", import, "LEFT", -10, 0)
    ui.message:SetWordWrap(false)
end

-- Columnas proporcionales: el lienzo de Opciones cambia de tamano
local function Layout()
    local width = panel:GetWidth() - 32 - 20
    if width <= 0 then return end
    ui.spellBox:SetWidth(width * 0.29)
    ui.rotationBox:SetWidth(width * 0.38)
end

local function Build()
    built = true
    BuildHeader()
    BuildSpells()
    BuildRotation()
    BuildConditions()
    BuildFooter()
    ui.spellBox:SetPoint("TOPLEFT", 16, -152)
    ui.spellBox:SetPoint("BOTTOMLEFT", 16, 44)
    ui.rotationBox:SetPoint("TOPLEFT", ui.spellBox, "TOPRIGHT", 10, 0)
    ui.rotationBox:SetPoint("BOTTOMLEFT", ui.spellBox, "BOTTOMRIGHT", 10, 0)
    ui.conditionBox:SetPoint("TOPLEFT", ui.rotationBox, "TOPRIGHT", 10, 0)
    ui.conditionBox:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 44)
    panel:HookScript("OnSizeChanged", Layout)
    Layout()
end

-- ------------------------------------------
-- Refresco
-- ------------------------------------------
function Editor.RefreshSpells()
    if not built then return end
    local query = strlower(ui.search:GetText() or "")
    local spells = {}
    for _, spell in ipairs(ns.State.BookSpells()) do
        if query == "" or strlower(spell.name):find(query, 1, true) then table.insert(spells, spell) end
    end
    ui.spellList.Fill(#spells, function(row, i)
        row.spellID = spells[i].id
        row.icon:SetTexture(C_Spell.GetSpellTexture(spells[i].id))
        row.name:SetText(spells[i].name)
    end)
end

local function RefreshConditions(editable)
    local rule = Rule()
    local show = rule ~= nil and editable
    ui.body:SetShown(show)
    ui.pick:SetShown(not show)
    ui.pick:SetText(editable and L.PICK or L.READ_ONLY)
    if not show then return end
    ui.icon:SetTexture(C_Spell.GetSpellTexture(rule.spell))
    ui.name:SetText(ns.State.NameOf(rule.spell) or ("#" .. rule.spell))
    ui.missing:SetChecked(rule.missing and true or false)
    ui.dur:SetText(rule.dur and tostring(rule.dur) or "")
    ui.on.Update(rule)
    ui.aoe:SetText(rule.aoe and tostring(rule.aoe) or "")
    ui.cp:SetText(rule.cp and tostring(rule.cp) or "")
    ui.melee.Update(rule)
    for key, check in pairs(ui.checks) do check:SetChecked(rule[key] == true) end
    ui.form:SetText(rule.form ~= nil and format(L.FORM_ID, rule.form) or L.FORM_ANY)
    local extra = {}
    for key in pairs(rule) do if ADVANCED[key] then table.insert(extra, key) end end
    table.sort(extra)
    ui.advanced:SetText(#extra > 0 and format(L.ADVANCED, table.concat(extra, ", ")) or "")
end

function Editor.Refresh()
    if not built or not ns.db then return end
    local specs = ns.Rotations[ns.class] or {}
    for index, tab in ipairs(ui.tabs) do
        local name = specs[index] and specs[index].name or "?"
        -- La rama detectada por talentos sale en verde
        tab:SetText(index == ns.spec and ("|cff66ff66" .. name .. "|r") or name)
        if index == specIndex then tab:LockHighlight() else tab:UnlockHighlight() end
    end
    local editable = Profile() ~= nil
    ui.profile.text:SetText(editable and ProfileName() or (L.RECOMMENDED .. " |cff888888" .. L.RECOMMENDED_NOTE .. "|r"))
    ui.rename:SetEnabled(editable)
    ui.delete:SetEnabled(editable)
    ui.rotationBox.title:SetText(format(L.ROTATION_OF, ProfileName()))

    local rules = Rules()
    ui.empty:SetShown(#rules == 0)
    ui.ruleList.Fill(#rules, function(row, i)
        local rule = rules[i]
        local known = ns.State.Known(rule.spell) ~= nil
        row.index, row.spellID = i, rule.spell
        row.hint = not known and L.UNKNOWN or nil
        row.number:SetText(i)
        row.icon:SetTexture(C_Spell.GetSpellTexture(rule.spell))
        row.icon:SetDesaturated(not known)
        row.name:SetText(ns.State.NameOf(rule.spell) or ("#" .. rule.spell))
        local shade = known and 1 or 0.5
        row.name:SetTextColor(shade, shade, shade)
        row.tags:SetText(Tags(rule))
        row.selected:SetShown(i == selected)
        row.up:SetShown(editable)
        row.down:SetShown(editable)
        row.remove:SetShown(editable)
        row.up:SetEnabled(i > 1)
        row.down:SetEnabled(i < #rules)
    end)
    RefreshConditions(editable)
end

-- ------------------------------------------
-- Registro en Opciones (o ventana propia si el cliente no tiene Settings)
-- ------------------------------------------
panel = CreateFrame("Frame", "RotationGuideEditor", UIParent, "BackdropTemplate")
panel:Hide()
panel:SetScript("OnShow", function()
    if not ns.db then return end
    if not built then Build() end
    specIndex, selected = ns.spec or 1, nil
    Message("")
    Editor.RefreshSpells()
    Editor.Refresh()
end)
panel:SetScript("OnHide", function()
    if menu then menu:Hide() end
end)

if Settings and Settings.RegisterCanvasLayoutCategory then
    category = Settings.RegisterCanvasLayoutCategory(panel, "Rotation Guide")
    Settings.RegisterAddOnCategory(category)
    Editor.category = category -- UI/Options.lua cuelga de aqui
else
    panel:SetSize(780, 600)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    Backdrop(panel, 0.95)
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    table.insert(UISpecialFrames, "RotationGuideEditor")
end

function Editor.Open()
    if category then
        Settings.OpenToCategory(category:GetID())
    else
        panel:Show()
    end
end
