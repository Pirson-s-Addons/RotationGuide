local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- Comun a las tres ramas: abrir desde sigilo y mantener Hacer picadillo
local SND = { spell = 5171, on = "player", cp = 1, missing = true, dur = 12 } -- Slice and Dice

ns.Rotations.ROGUE = {
    [1] = { name = "Assassination", rules = {
        { spell = 703, stealth = true },                        -- Garrote
        { spell = 1833, stealth = true },                       -- Cheap Shot
        SND,
        { spell = 14177, elite = true },                        -- Cold Blood
        { spell = 1943, cp = 4, missing = true, dur = 16 },     -- Rupture
        { spell = 2098, cp = 4 },                               -- Eviscerate
        { spell = 399956 },                                     -- Mutilate
        { spell = 1752, ifUnknown = 399956 },                   -- Sinister Strike
    } },
    [2] = { name = "Combat", rules = {
        { spell = 1833, stealth = true },                       -- Cheap Shot
        SND,
        { spell = 13877, aoe = 2 },                             -- Blade Flurry
        { spell = 13750, elite = true },                        -- Adrenaline Rush
        { spell = 2098, cp = 5 },                               -- Eviscerate
        { spell = 1752 },                                       -- Sinister Strike
    } },
    [3] = { name = "Subtlety", rules = {
        { spell = 14183, stealth = true },                      -- Premeditation
        { spell = 8676, stealth = true },                       -- Ambush
        { spell = 1833, stealth = true },                       -- Cheap Shot
        SND,
        { spell = 1943, cp = 3, missing = true, dur = 16 },     -- Rupture
        { spell = 2098, cp = 4 },                               -- Eviscerate
        { spell = 16511 },                                      -- Hemorrhage
        { spell = 1752, ifUnknown = 16511 },                    -- Sinister Strike
    } },
}

ns.Heals.ROGUE = {
    { spell = 5277 },                                           -- Evasion
}
