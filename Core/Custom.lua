local ADDON_NAME, ns = ...

-- ==========================================
-- ROTACIONES DEL JUGADOR: copiar, exportar e importar
-- ==========================================
-- Logica pura (sin API del juego) para probarla en Tests/engine.lua.
-- El codigo que se comparte es una sola linea, facil de pegar en Discord o
-- en una web:
--   RG1:PRIEST:3:Mi rotacion:589,dur=18,missing=y;8092;15407
-- version : clase : rama : nombre del perfil : reglas separadas por ";".
-- Cada regla empieza por el id del hechizo y sigue con campo=valor (los de
-- Core/Engine.lua).

local Custom = {}
ns.Custom = Custom

-- Tipo de cada campo: n numero, b si/no, s texto (on), l si o lista (missing)
local TYPES = {
    aura = "n", dur = "n", max = "n", has = "n", hasStacks = "n", stacksBelow = "n",
    cp = "n", aoe = "n", form = "n", notForm = "n", ifUnknown = "n",
    on = "s", missing = "l",
    single = "b", melee = "b", stealth = "b", lowMana = "b", ooc = "b",
    elite = "b", noPet = "b", group = "b", noImbue = "b",
}
Custom.TYPES = TYPES

local MAX_TEXT, MAX_RULES, MAX_NAME = 8000, 80, 64

-- Nombre de perfil sin los separadores del codigo ni "|" (codigos de color del chat)
function Custom.CleanName(name)
    return ((name or ""):gsub("[|:;\r\n]", ""):match("^%s*(.-)%s*$"))
end

-- Copia profunda de una regla (missing puede ser una lista)
function Custom.CopyRule(rule)
    local out = {}
    for key, value in pairs(rule) do
        if type(value) == "table" then
            local list = {}
            for i, id in ipairs(value) do list[i] = id end
            value = list
        end
        out[key] = value
    end
    return out
end

function Custom.CopyRules(rules)
    local out = {}
    for i, rule in ipairs(rules or {}) do out[i] = Custom.CopyRule(rule) end
    return out
end

local function EncodeValue(value)
    if value == true then return "y" end
    if value == false then return "n" end
    if type(value) == "table" then return table.concat(value, "/") end
    return tostring(value)
end

function Custom.Encode(class, spec, name, rules)
    local parts = {}
    for i, rule in ipairs(rules) do
        local keys = {}
        for key in pairs(rule) do
            if TYPES[key] then table.insert(keys, key) end
        end
        table.sort(keys)  -- mismo texto para la misma rotacion
        local fields = { tostring(rule.spell) }
        for _, key in ipairs(keys) do
            table.insert(fields, key .. "=" .. EncodeValue(rule[key]))
        end
        parts[i] = table.concat(fields, ",")
    end
    return "RG1:" .. class .. ":" .. spec .. ":" .. Custom.CleanName(name) .. ":" .. table.concat(parts, ";")
end

-- Ids y duraciones: numeros >= 0 razonables (nada de nan, inf ni negativos)
local function Number(text)
    local value = text:match("^%d+%.?%d*$") and tonumber(text)
    if value and value < 1e8 then return value end
    return nil
end

local function DecodeValue(kind, text)
    if kind == "n" then return Number(text) end
    if kind == "b" then
        if text == "y" then return true end
        if text == "n" then return false end
        return nil
    end
    if kind == "s" then
        return (text == "player" or text == "target") and text or nil
    end
    -- l: "y" o lista de ids "980/603"
    if text == "y" then return true end
    local list = {}
    for id in text:gmatch("[^/]+") do
        local value = Number(id)
        if not value then return nil end
        table.insert(list, value)
    end
    return #list > 0 and list or nil
end

-- Texto -> class, spec, rules, name; o nil, codigo de error, numero de regla.
-- Errores: "empty", "long", "format", "many", "rule"
function Custom.Decode(text)
    text = (text or ""):match("^%s*(.-)%s*$")
    if text == "" then return nil, "empty" end
    if #text > MAX_TEXT then return nil, "long" end
    local class, spec, name, body = text:match("^RG1:(%u+):([123]):([^:]*):(.+)$")
    if not class or #name > MAX_NAME then return nil, "format" end
    -- Los espacios solo cuentan en el nombre (al pegar se cuelan saltos de linea)
    body = body:gsub("%s+", "")
    local rules = {}
    for chunk in body:gmatch("[^;]+") do
        if #rules >= MAX_RULES then return nil, "many" end
        local index = #rules + 1
        local rule = {}
        for field in chunk:gmatch("[^,]+") do
            if not rule.spell then
                rule.spell = Number(field)
                if not rule.spell then return nil, "rule", index end
            else
                local key, value = field:match("^(%a+)=(.+)$")
                local kind = key and TYPES[key]
                local decoded = kind and DecodeValue(kind, value)
                if decoded == nil then return nil, "rule", index end
                rule[key] = decoded
            end
        end
        table.insert(rules, rule)
    end
    if #rules == 0 then return nil, "format" end
    return class, tonumber(spec), rules, Custom.CleanName(name:gsub("%s+", " "))
end
