local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- Los totems se rastrean como "aura" del jugador durante su duracion.
-- En Forever los totems de buff duran 5 min y Fire Nova estalla en el totem de fuego.

local FLAME_SHOCK = { spell = 8050, missing = true, dur = 12 }                      -- Flame Shock
local SEARING     = { spell = 3599, on = "player", single = true, missing = { 3599, 8190 }, dur = 30 } -- Searing Totem
local MAGMA       = { spell = 8190, on = "player", aoe = 2, melee = true, missing = { 3599, 8190 }, dur = 20 } -- Magma Totem
local FIRE_NOVA   = { spell = 8443, aoe = 2 }                                       -- Fire Nova
local MANA_SPRING = { spell = 5675, on = "player", missing = true, dur = 300 }      -- Mana Spring Totem
local BOLT        = { spell = 403 }                                                 -- Lightning Bolt
-- Antes de Flame Shock (nivel 10), Earth Shock hace de choque
local EARLY_SHOCK = { spell = 8042, ifUnknown = 8050 }                              -- Earth Shock

-- Escudos: solo uno a la vez; Water Shield (talento de Restauracion) para mana
local SHIELDS = { 324, 408510 }
local SHIELD  = { spell = 324, ooc = true, on = "player", missing = SHIELDS }       -- Lightning Shield
local WATER   = { spell = 408510, ooc = true, on = "player", missing = SHIELDS }    -- Water Shield

-- Raciales ofensivas: orco y trol
local RACIALS = {
    { spell = 20572, elite = true },                            -- Blood Fury
    { spell = 20554, elite = true },                            -- Berserking
}

-- Mejora: encantamiento temporal en el arma (Viento furioso si se conoce, si no Muerdepiedras)
local IMBUE = {
    { spell = 8232, ooc = true, noImbue = true },                                   -- Windfury Weapon
    { spell = 8017, ooc = true, noImbue = true, ifUnknown = 8232 },                 -- Rockbiter Weapon
}

ns.Rotations.SHAMAN = {
    [1] = { name = "Elemental", rules = ns.Engine.Join({ WATER, SHIELD, MANA_SPRING }, RACIALS, {
        MAGMA, SEARING,
        FIRE_NOVA,
        FLAME_SHOCK,
        { spell = 408490 },                                     -- Lava Burst
        { spell = 421 },                                        -- Chain Lightning
        EARLY_SHOCK,
        BOLT,
    }) },
    [2] = { name = "Enhancement", rules = ns.Engine.Join({ SHIELD }, IMBUE, {
        { spell = 8075, on = "player", missing = true, dur = 300 }, -- Strength of Earth Totem
        { spell = 8835, on = "player", missing = true, dur = 300 }, -- Grace of Air Totem
        MANA_SPRING,
        { spell = 425336, elite = true },                       -- Rage of the Farseer
    }, RACIALS, {
        { spell = 403, melee = false },                         -- Lightning Bolt (pull)
        MAGMA, SEARING,
        FIRE_NOVA,
        { spell = 17364 },                                      -- Stormstrike
        { spell = 403, has = 408505 },                          -- Lightning Bolt (Maelstrom)
        FLAME_SHOCK,
        { spell = 8042 },                                       -- Earth Shock
    }) },
    [3] = { name = "Restoration", rules = ns.Engine.Join({ WATER, SHIELD, MANA_SPRING,
        { spell = 16190, lowMana = true },                      -- Mana Tide Totem
    }, RACIALS, {
        MAGMA, SEARING,
        FIRE_NOVA,
        FLAME_SHOCK,
        EARLY_SHOCK,
        BOLT,
    }) },
}

ns.Heals.SHAMAN = {
    { spell = 408521 },                                         -- Riptide
    { spell = 8004 },                                           -- Lesser Healing Wave
    { spell = 331 },                                            -- Healing Wave
}
