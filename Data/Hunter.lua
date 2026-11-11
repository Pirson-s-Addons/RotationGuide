local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}

-- El cazador cambia de lista segun la distancia: a melee golpes cuerpo a
-- cuerpo, lejos los disparos. El Disparo automatico va solo y no se lista.

local MARK    = { spell = 1130, missing = true, dur = 120 }             -- Hunter's Mark
local RAPTOR  = { spell = 2973, melee = true }                          -- Raptor Strike
local BITE    = { spell = 1495, melee = true }                          -- Mongoose Bite
local STING   = { spell = 1978, melee = false, missing = true, dur = 15 } -- Serpent Sting
local RAPID   = { spell = 3045, melee = false }                         -- Rapid Fire
local AIMED   = { spell = 19434, melee = false }                        -- Aimed Shot
local MULTI   = { spell = 2643, melee = false }                         -- Multi-Shot
local ARCANE  = { spell = 3044, melee = false }                         -- Arcane Shot

ns.Rotations.HUNTER = {
    [1] = { name = "Beast Mastery", rules = {
        MARK,
        { spell = 19574 },                                      -- Bestial Wrath
        BITE, RAPTOR,
        STING, RAPID, AIMED, MULTI, ARCANE,
    } },
    [2] = { name = "Marksmanship", rules = {
        MARK,
        BITE, RAPTOR,
        STING, RAPID, AIMED,
        { spell = 1310687, melee = false },                     -- Sniper Shot
        MULTI, ARCANE,
    } },
    [3] = { name = "Survival", rules = {
        MARK,
        BITE, RAPTOR,
        { spell = 19306, melee = true },                        -- Counterattack
        STING, RAPID, AIMED, MULTI, ARCANE,
    } },
}
