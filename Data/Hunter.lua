local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- El cazador cambia de lista segun la distancia: a melee golpes cuerpo a
-- cuerpo, lejos los disparos. El Disparo automatico va solo y no se lista.
-- Forever: Disparo apuntado (nivel 20) y Multidisparo comparten cooldown;
-- Invocar halcon comparte cooldown con Disparo arcano.

-- Fuera de combate: aspecto (Mono hasta aprender Halcon)
local ASPECT = {
    { spell = 13165, ooc = true, on = "player", missing = true }, -- Aspect of the Hawk
    { spell = 13163, ooc = true, on = "player", missing = true, ifUnknown = 13165 }, -- Aspect of the Monkey
}
-- Mascota (revivir si murio, llamarla si no esta); Punteria y Supervivencia
-- juegan sin ella (Lobo solitario) y no la piden
local PET = {
    { spell = 982, ooc = true, noPet = true },                  -- Revive Pet
    { spell = 883, ooc = true, noPet = true },                  -- Call Pet
}

-- Raciales ofensivas y Fuego rapido: solo elites y jefes
local CDS = {
    { spell = 20572, elite = true },                            -- Blood Fury
    { spell = 20554, elite = true },                            -- Berserking
    { spell = 1259799, elite = true },                          -- Elune's Light
    { spell = 3045, melee = false, elite = true },              -- Rapid Fire
}

local MARK    = { spell = 1130, missing = true, dur = 120 }             -- Hunter's Mark
local RAPTOR  = { spell = 2973, melee = true }                          -- Raptor Strike
local BITE    = { spell = 1495, melee = true }                          -- Mongoose Bite
local XTRAP   = { spell = 13813, melee = true, aoe = 3 }                -- Explosive Trap
local STING   = { spell = 1978, melee = false, missing = true, dur = 15 } -- Serpent Sting
local VOLLEY  = { spell = 1510, melee = false, aoe = 3 }                -- Volley
local HAWK    = { spell = 1293241 }                                     -- Summon Hawk (sin rango minimo)
local AIMED   = { spell = 19434, melee = false }                        -- Aimed Shot
local MULTI   = { spell = 2643, melee = false }                         -- Multi-Shot
local ARCANE  = { spell = 3044, melee = false }                         -- Arcane Shot

ns.Rotations.HUNTER = {
    [1] = { name = "Beast Mastery", rules = ns.Engine.Join(PET, ASPECT, {
        { spell = 19574, elite = true },                        -- Bestial Wrath
    }, CDS, {
        MARK,
        { spell = 19577 },                                      -- Intimidation
        BITE, RAPTOR, XTRAP,
        VOLLEY, STING, HAWK, ARCANE, MULTI, AIMED,
    }) },
    [2] = { name = "Marksmanship", rules = ns.Engine.Join(ASPECT, {
        { spell = 1299346, ooc = true, on = "player", missing = true }, -- Trueshot Aura
    }, CDS, {
        MARK,
        BITE, RAPTOR, XTRAP,
        VOLLEY,
        { spell = 2643, melee = false, aoe = 2 },               -- Multi-Shot
        AIMED, STING,
        { spell = 1310687, melee = false },                     -- Sniper Shot
        ARCANE, MULTI,
    }) },
    [3] = { name = "Survival", rules = ns.Engine.Join(ASPECT, CDS, {
        MARK,
        RAPTOR, BITE,
        { spell = 19306, melee = true },                        -- Counterattack
        { spell = 1317257, melee = true },                      -- Strider Kick
        XTRAP,
        { spell = 13795, melee = true },                        -- Immolation Trap
        VOLLEY, STING, ARCANE, MULTI, AIMED,
    }) },
}

-- Defensivas con poca vida
ns.Heals.HUNTER = {
    { spell = 19263 },                                          -- Deterrence
    { spell = 20594 },                                          -- Stoneform
    { spell = 5384, group = true },                             -- Feign Death
}
