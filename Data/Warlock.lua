local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}

-- Un brujo solo puede tener una maldicion suya en el objetivo: cada rama
-- lleva la que mas le rinde.

local TAP        = { spell = 1454, lowMana = true }                    -- Life Tap
local CORRUPTION = { spell = 172, missing = true, dur = 18 }           -- Corruption
local IMMOLATE   = { spell = 348, missing = true, dur = 15 }           -- Immolate
local AGONY      = { spell = 980, missing = { 980, 603, 440892 }, dur = 24 } -- Curse of Agony
local HELLFIRE   = { spell = 1949, aoe = 3, melee = true }             -- Hellfire
local RAIN       = { spell = 5740, aoe = 3 }                           -- Rain of Fire
local BOLT       = { spell = 686 }                                     -- Shadow Bolt

ns.Rotations.WARLOCK = {
    [1] = { name = "Affliction", rules = {
        TAP,
        { spell = 18288 },                                      -- Amplify Curse
        AGONY,
        CORRUPTION,
        { spell = 18265, missing = true, dur = 30 },            -- Siphon Life
        IMMOLATE,
        HELLFIRE, RAIN,
        BOLT,
    } },
    [2] = { name = "Demonology", rules = {
        TAP,
        AGONY,
        CORRUPTION,
        IMMOLATE,
        HELLFIRE, RAIN,
        BOLT,
    } },
    [3] = { name = "Destruction", rules = {
        TAP,
        { spell = 440892, missing = { 980, 603, 440892 }, dur = 300 }, -- Curse of the Elements
        { spell = 980, missing = { 980, 603, 440892 }, dur = 24, ifUnknown = 440892 }, -- Curse of Agony
        IMMOLATE,
        { spell = 1293817 },                                    -- Conflagrate
        CORRUPTION,
        { spell = 17877 },                                      -- Shadowburn
        HELLFIRE, RAIN,
        BOLT,
    } },
}
