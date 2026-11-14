local ADDON_NAME, ns = ...

-- ==========================================
-- API PUBLICA (solo lectura)
-- ==========================================
-- Para que otros addons (p. ej. Azeroth AI) puedan explicar una rotacion:
-- que hechizos usa cada rama, en que orden y con que condiciones. Devuelve
-- siempre copias: quien la use no puede tocar los datos del addon.
--
-- Estable: version solo sube si cambia el significado de algo ya existente;
-- anadir funciones o campos nuevos no la sube.
--
--   local api = RotationGuideAPI
--   if api and api.version == 1 then
--       for _, step in ipairs(api.GetRotation("PALADIN", 3) or {}) do
--           print(step.spellID, step.name, step.conditions.missing)
--       end
--   end

local function CopyRule(rule)
    local conditions = {}
    for key, value in pairs(rule) do
        if key ~= "spell" then
            if type(value) == "table" then
                local list = {}
                for i, id in ipairs(value) do list[i] = id end
                value = list
            end
            conditions[key] = value
        end
    end
    -- name: en el idioma del cliente; nil si el juego no conoce el hechizo
    return { spellID = rule.spell, name = ns.State.NameOf(rule.spell), conditions = conditions }
end

local function CopyRules(rules)
    local out = {}
    for i, rule in ipairs(rules or {}) do out[i] = CopyRule(rule) end
    return out
end

RotationGuideAPI = {
    version = 1,

    -- { "DRUID", "HUNTER", ... }: clases con rotacion (token en ingles, como UnitClass)
    GetClasses = function()
        local out = {}
        for class in pairs(ns.Rotations) do table.insert(out, class) end
        table.sort(out)
        return out
    end,

    -- { { index = 1, name = "Holy", solo = nil }, ... } o nil si la clase no existe.
    -- index es la rama de talentos (1-3); solo = rama que se usa en solitario.
    GetSpecs = function(class)
        local specs = ns.Rotations[class]
        if not specs then return nil end
        local out = {}
        for index, spec in ipairs(specs) do
            out[index] = { index = index, name = spec.name, solo = spec.solo }
        end
        return out
    end,

    -- Pasos de la rotacion en orden de prioridad:
    -- { { spellID, name, conditions = { cp = 5, aoe = 2, missing = true, ... } }, ... }
    -- conditions usa los mismos campos que Core/Engine.lua documenta.
    GetRotation = function(class, specIndex)
        local spec = ns.Rotations[class] and ns.Rotations[class][specIndex]
        return spec and CopyRules(spec.rules) or nil
    end,

    -- Curas o defensivos de la clase cuando baja la vida, en orden
    GetHeals = function(class)
        return ns.Heals[class] and CopyRules(ns.Heals[class]) or nil
    end,

    -- Lo que usa ahora el jugador: class, specIndex, nombre de la rama (o nil antes de cargar)
    GetPlayerSpec = function()
        return ns.class, ns.spec, ns.specName
    end,

    -- Lo que resalta ahora mismo: spellID de la rotacion, spellID de la cura
    -- (solo se lista; si hace falta lo decide la vida, que es secreta) y el
    -- umbral de vida de la cura en % (0 = curas desactivadas). nil = nada.
    GetNext = function()
        return ns.nextSpell, ns.nextHeal, ns.db and ns.db.healAt
    end,
}
