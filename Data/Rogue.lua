local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- Guias de WoW Forever (parche 1.60.1). Ambush, Backstab y Riposte solo son
-- "usables" con daga, en sigilo o tras parar: basta con listarlas.
local Join = ns.Engine.Join

local SND = { spell = 5171, on = "player", cp = 1, missing = true, dur = 12 } -- Slice and Dice
local SHANK = { spell = 1329283 }                                -- Shank: da energia (y combo con Boot Knife)
local EXPOSE = { spell = 8647, elite = true, cp = 5, missing = true, dur = 30 } -- Expose Armor
local EVISCERATE = { spell = 2098, cp = 5 }                      -- Eviscerate

-- Raciales ofensivas: la que no tenga la raza se salta
local RACIALS = {
    { spell = 20572, elite = true },                            -- Blood Fury
    { spell = 20554, elite = true },                            -- Berserking
    { spell = 1259799, elite = true },                          -- Elune's Light
}

ns.Rotations.ROGUE = {
    [1] = { name = "Assassination", rules = Join({
        { spell = 8676, stealth = true },                       -- Ambush
        { spell = 703, stealth = true },                        -- Garrote
        { spell = 1833, stealth = true },                       -- Cheap Shot
        { spell = 14177, elite = true },                        -- Cold Blood
    }, RACIALS, {
        SHANK,
        SND,
        EXPOSE,
        EVISCERATE,
        { spell = 1752, cp = 4 },                               -- Sinister Strike (a 4 puntos, no Mutilate)
        { spell = 399956 },                                     -- Mutilate
        { spell = 1752, ifUnknown = 399956 },                   -- Sinister Strike
    }) },
    [2] = { name = "Combat", rules = Join({
        { spell = 8676, stealth = true },                       -- Ambush
        { spell = 1833, stealth = true },                       -- Cheap Shot
        SND,
        { spell = 13877 },                                      -- Blade Flurry
        { spell = 13750, elite = true },                        -- Adrenaline Rush
    }, RACIALS, {
        SHANK,
        { spell = 14251 },                                      -- Riposte
        EXPOSE,
        EVISCERATE,
        { spell = 53, group = true },                           -- Backstab (en grupo se esta a la espalda)
        { spell = 1752 },                                       -- Sinister Strike
    }) },
    [3] = { name = "Subtlety", rules = Join({
        { spell = 14183, stealth = true },                      -- Premeditation
        { spell = 8676, stealth = true },                       -- Ambush
        { spell = 703, stealth = true },                        -- Garrote
        { spell = 1833, stealth = true },                       -- Cheap Shot
    }, RACIALS, {
        SHANK,
        { spell = 8676, has = 14278 },                          -- Ambush sin sigilo tras Ghostly Strike
        SND,
        { spell = 1943, elite = true, cp = 5, missing = true, dur = 16 }, -- Rupture
        EXPOSE,
        { spell = 1316709, cp = 5 },                            -- Death Mark
        EVISCERATE,
        { spell = 14278, on = "player", dur = 7 },              -- Ghostly Strike
        { spell = 16511 },                                      -- Hemorrhage
        { spell = 53, group = true },                           -- Backstab
        { spell = 1752, ifUnknown = 16511 },                    -- Sinister Strike
    }) },
}

ns.Heals.ROGUE = {
    { spell = 5277 },                                           -- Evasion
    { spell = 20594 },                                          -- Stoneform
    { spell = 1856 },                                           -- Vanish
}
