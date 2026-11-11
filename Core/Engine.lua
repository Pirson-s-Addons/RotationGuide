local ADDON_NAME, ns = ...

-- ==========================================
-- MOTOR DE PRIORIDADES
-- ==========================================
-- Logica pura: no toca la API del juego, solo el objeto S (Core/State.lua),
-- para poder probarla fuera del cliente (Tests/engine.lua).
--
-- Una rotacion es una lista ordenada de reglas. Gana la primera cuyo hechizo
-- conoce el jugador, esta listo (usable y sin cooldown) y cumple todas sus
-- condiciones. Campos de una regla (todos opcionales salvo spell):
--   spell      id de cualquier rango; se resuelve por nombre al rango mas alto
--   aura       id del aura que deja (por defecto la del propio spell)
--   on         "player" | "target": donde vive el aura (por defecto target)
--   dur, max   duracion y stacks maximos del aura, para el rastreo propio
--   missing    true: el aura no esta; o lista de ids: no esta ninguna
--   has        id de aura (proc) que debe estar activa en el jugador
--   stacksBelow n: menos de n stacks del aura
--   cp         puntos de combo minimos
--   aoe        minimo de enemigos; single = true: menos de 2
--   melee      true/false: el objetivo esta (o no) a melee
--   form       forma/actitud exigida (0 = sin forma); notForm la contraria
--   stealth    true: solo en sigilo
--   lowMana    true: solo con poco mana
--   ifUnknown  id: solo si el jugador NO conoce ese hechizo

local Engine = {}
ns.Engine = Engine

local function AuraOf(rule)
    return rule.aura or rule.spell
end

local function UnitOf(rule)
    return rule.on or "target"
end

local function Missing(rule, S)
    if rule.missing == true then
        return not S.AuraActive(AuraOf(rule), UnitOf(rule))
    end
    for _, id in ipairs(rule.missing) do
        if S.AuraActive(id, UnitOf(rule)) then return false end
    end
    return true
end

-- Condiciones baratas primero: las de aura pueden consultar la API varias veces
local function Passes(rule, S)
    if rule.form ~= nil and S.Form() ~= rule.form then return false end
    if rule.notForm ~= nil and S.Form() == rule.notForm then return false end
    if rule.stealth and not S.Stealthed() then return false end
    if rule.single and S.Targets() >= 2 then return false end
    if rule.aoe and S.Targets() < rule.aoe then return false end
    -- Distancia desconocida (nil): ni melee ni rango, la regla no aplica
    if rule.melee ~= nil and S.InMelee() ~= rule.melee then return false end
    if rule.cp and (S.ComboPoints() or -1) < rule.cp then return false end
    if rule.lowMana and not S.LowMana() then return false end
    if rule.ifUnknown and S.Known(rule.ifUnknown) then return false end
    if rule.missing and not Missing(rule, S) then return false end
    if rule.has and not S.AuraActive(rule.has, "player") then return false end
    if rule.stacksBelow and S.Stacks(AuraOf(rule), UnitOf(rule)) >= rule.stacksBelow then return false end
    return true
end

-- Devuelve el id (rango conocido) del siguiente hechizo y su regla, o nil
function Engine.Next(rules, S)
    for _, rule in ipairs(rules) do
        local id = S.Known(rule.spell)
        if id and S.Ready(id) and Passes(rule, S) then
            return id, rule
        end
    end
    return nil
end

-- Indice cast -> auras que deja, para que State rastree duraciones cuando la
-- API las oculta en combate. Se indexa por el spell (id de la regla).
function Engine.TrackIndex(rules)
    local index = {}
    for _, rule in ipairs(rules) do
        if rule.dur then
            index[rule.spell] = index[rule.spell] or {}
            table.insert(index[rule.spell], {
                aura = AuraOf(rule), on = UnitOf(rule), dur = rule.dur, max = rule.max or 1,
            })
        end
    end
    return index
end
