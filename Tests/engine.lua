-- Comprobaciones del motor y de los datos, fuera del juego (Lua 5.1).
-- Se lanza desde Tests/run.py, que antes compila todos los .lua.

local ns = {}
local function load(path) assert(loadfile(path))("RotationGuide", ns) end

load("Core/Engine.lua")
for _, class in ipairs({ "Warrior", "Rogue", "Hunter", "Mage", "Warlock", "Priest", "Paladin", "Shaman", "Druid" }) do
    load("Data/" .. class .. ".lua")
end

local fails = 0
local function check(ok, text)
    if not ok then fails = fails + 1; print("FALLO: " .. text) end
end

-- 1) Datos: 9 clases x 3 ramas, reglas con spell numerico y campos conocidos
local FIELDS = { spell = 1, aura = 1, on = 1, dur = 1, max = 1, missing = 1, has = 1, stacksBelow = 1,
    cp = 1, aoe = 1, single = 1, melee = 1, form = 1, notForm = 1, stealth = 1, lowMana = 1, ifUnknown = 1,
    ooc = 1, elite = 1, noPet = 1, group = 1, noImbue = 1 }
local function CheckRule(rule, where)
    check(type(rule.spell) == "number", where .. ": spell no numerico")
    check(rule.on == nil or rule.on == "player" or rule.on == "target", where .. ": on invalido")
    for key in pairs(rule) do check(FIELDS[key], where .. ": campo desconocido " .. key) end
    -- En combate la API de auras se oculta: sin dur, una condicion de aura
    -- solo funciona fuera de combate (reglas ooc)
    if (rule.missing or rule.stacksBelow) and not rule.ooc then
        check(rule.dur, where .. ": missing/stacksBelow sin dur")
    end
end
local specs = 0
for class, list in pairs(ns.Rotations) do
    for index = 1, 3 do
        local spec = list[index]
        check(spec and spec.name and #spec.rules > 0, class .. " rama " .. index .. " sin reglas")
        specs = specs + 1
        for n, rule in ipairs(spec and spec.rules or {}) do
            CheckRule(rule, class .. "/" .. spec.name .. " regla " .. n)
        end
        check(spec.solo == nil or list[spec.solo], class .. "/" .. spec.name .. ": solo apunta a una rama inexistente")
    end
    check(type(ns.Heals[class]) == "table", class .. " sin lista de curas")
    for n, rule in ipairs(ns.Heals[class] or {}) do
        CheckRule(rule, class .. "/curas regla " .. n)
        check(not rule.ooc, class .. "/curas regla " .. n .. ": una cura no es ooc")
    end
end
check(specs == 27, "se esperaban 27 ramas, hay " .. specs)

-- 2) Motor con un estado falso
local function State(over)
    local S = {
        known = { [1] = 1, [2] = 2, [3] = 3 }, ready = { [1] = true, [2] = true, [3] = true },
        auras = {}, stacks = {}, form = 0, targets = 1, melee = true, cp = 0,
        combat = true, enemy = true, elite = false, pet = true, group = false, imbued = false,
    }
    for k, v in pairs(over or {}) do S[k] = v end
    S.Known = function(id) return S.known[id] end
    S.Ready = function(id) return S.ready[id] end
    S.AuraActive = function(id) return S.auras[id] == true end
    S.Stacks = function(id) return S.stacks[id] or 0 end
    S.Form = function() return S.form end
    S.Stealthed = function() return false end
    S.Targets = function() return S.targets end
    S.InMelee = function() return S.melee end
    S.ComboPoints = function() return S.cp end
    S.LowMana = function() return false end
    S.InCombat = function() return S.combat end
    S.HasEnemy = function() return S.enemy end
    S.Elite = function() return S.elite end
    S.HasPet = function() return S.pet end
    S.InGroup = function() return S.group end
    S.WeaponImbued = function() return S.imbued end
    return S
end
local Next = ns.Engine.Next
local rules = { { spell = 1, missing = true, dur = 10 }, { spell = 2, cp = 3 }, { spell = 3 } }

check(Next(rules, State()) == 1, "sin aura debe recomendar la regla 1")
check(Next(rules, State({ auras = { [1] = true } })) == 3, "con aura y 0 combo salta a la 3")
check(Next(rules, State({ auras = { [1] = true }, cp = 3 })) == 2, "con 3 combo toca la 2")
check(Next(rules, State({ ready = { [3] = true } })) == 3, "lo que no esta listo se salta")
check(Next(rules, State({ known = {} })) == nil, "sin hechizos conocidos no hay recomendacion")
check(Next({ { spell = 1, melee = false }, { spell = 2 } }, State({ melee = nil })) == 2, "distancia desconocida no cumple melee=false")
check(Next({ { spell = 1, aoe = 2 }, { spell = 2, single = true } }, State({ targets = 3 })) == 1, "aoe con 3 enemigos")
check(Next({ { spell = 1, missing = { 7, 8 } }, { spell = 2 } }, State({ auras = { [8] = true } })) == 2, "missing de lista")
check(Next({ { spell = 1, ifUnknown = 2 }, { spell = 3 } }, State()) == 3, "ifUnknown con el hechizo conocido")
check(Next({ { spell = 1, stacksBelow = 5, dur = 1 }, { spell = 2 } }, State({ stacks = { [1] = 5 } })) == 2, "stacksBelow lleno")

-- Situaciones
local prep = { { spell = 1, ooc = true, missing = true }, { spell = 2, noPet = true, ooc = true }, { spell = 3 } }
check(Next(prep, State({ combat = false, enemy = false })) == 1, "fuera de combate y sin objetivo: buff")
check(Next(prep, State({ combat = false, enemy = false, auras = { [1] = true }, pet = false })) == 2, "sin mascota: invocarla")
check(Next(prep, State({ combat = false, enemy = false, auras = { [1] = true } })) == nil, "sin objetivo no hay rotacion")
check(Next(prep, State()) == 3, "en combate se ignoran las reglas ooc")
check(Next({ { spell = 1, elite = true }, { spell = 2 } }, State()) == 2, "cooldown guardado contra no elite")
check(Next({ { spell = 1, elite = true }, { spell = 2 } }, State({ elite = true })) == 1, "cooldown contra elite")
check(Next({ { spell = 1, group = true }, { spell = 2 } }, State()) == 2, "regla de grupo en solitario")
check(Next({ { spell = 1, noImbue = true, ooc = true } }, State({ combat = false, imbued = true })) == nil, "arma ya encantada")
check(Next({ { spell = 1 } }, State({ enemy = false }), true) == 1, "ungated: la cura no necesita enemigo")

-- TrackIndex: una entrada por regla con dur, aura por defecto el propio spell
local index = ns.Engine.TrackIndex({ { spell = 9, dur = 5 }, { spell = 9, aura = 4, dur = 3, max = 5, on = "player" }, { spell = 6 } })
check(#index[9] == 2 and index[9][1].aura == 9 and index[9][2].max == 5 and index[6] == nil, "TrackIndex")

-- API publica: copias, no los datos internos
ns.State = { NameOf = function(id) return "spell" .. id end }
load("Core/API.lua")
local api = RotationGuideAPI
check(api.version == 1 and #api.GetClasses() == 9, "API: version y 9 clases")
local ret = api.GetRotation("PALADIN", 3)
check(ret and ret[1].spellID and ret[1].name == "spell" .. ret[1].spellID, "API: paso con id y nombre")
ret[1].conditions.dur = 999
if type(ret[1].conditions.missing) == "table" then ret[1].conditions.missing[1] = 0 end
local again = api.GetRotation("PALADIN", 3)
check(again[1].conditions.dur ~= 999 and again[1].conditions.missing[1] ~= 0, "API: devuelve copias")
check(api.GetSpecs("WARRIOR")[3].solo == 1 and api.GetRotation("NOPE", 1) == nil, "API: specs y clase inexistente")
check(#api.GetHeals("PRIEST") == 3, "API: curas")

print(fails == 0 and ("ENGINE OK (" .. specs .. " ramas)") or (fails .. " fallos"))
os.exit(fails == 0 and 0 or 1)
