local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- En Forever Agonia y Fatalidad son Perdiciones (Banes): el brujo lleva una
-- perdicion y una maldicion suyas a la vez en cada objetivo.
local BANES  = { 980, 603, 1225228 }                     -- Agony, Doom, Havoc
local CURSES = { 440892, 702, 704, 1714, 18223 }         -- Elements, Weakness, Recklessness, Tongues, Exhaustion

local TAP        = { spell = 1454, lowMana = true }                    -- Life Tap
local CORRUPTION = { spell = 172, missing = true, dur = 18 }           -- Corruption
local IMMOLATE   = { spell = 348, missing = true, dur = 15 }           -- Immolate
local DOOM       = { spell = 603, missing = BANES, dur = 60, elite = true } -- Bane of Doom
local AGONY      = { spell = 980, missing = BANES, dur = 24 }          -- Bane of Agony
local ELEMENTS   = { spell = 440892, missing = CURSES, dur = 300 }     -- Curse of the Elements
local HELLFIRE   = { spell = 1949, aoe = 3, melee = true }             -- Hellfire
local RAIN       = { spell = 5740, aoe = 3 }                           -- Rain of Fire
local DRAIN      = { spell = 689 }                                     -- Drain Life
local BOLT       = { spell = 686 }                                     -- Shadow Bolt
local RACIALS = {
    { spell = 20572, elite = true },                                   -- Blood Fury
    { spell = 20554, elite = true },                                   -- Berserking
}

-- Fuera de combate: armadura y el demonio de cada rama (si no lo conoce, el siguiente)
local ARMORS = { 687, 706 }  -- Demon Skin, Demon Armor
local PREP = {
    { spell = 706, ooc = true, on = "player", missing = ARMORS },              -- Demon Armor
    { spell = 687, ooc = true, on = "player", missing = ARMORS, ifUnknown = 706 }, -- Demon Skin
}
local function Pets(...)
    local list = {}
    for i = 1, select("#", ...) do
        table.insert(list, { spell = (select(i, ...)), ooc = true, noPet = true })
    end
    return list
end
local VOIDWALKER, IMP, SUCCUBUS, INCUBUS = 697, 688, 712, 713

ns.Rotations.WARLOCK = {
    [1] = { name = "Affliction", rules = ns.Engine.Join(PREP, Pets(SUCCUBUS, INCUBUS, VOIDWALKER, IMP), {
        TAP,
    }, RACIALS, {
        { spell = 18288 },                                      -- Amplify Curse
        DOOM, AGONY,
        CORRUPTION,
        { spell = 18265, missing = true, dur = 30 },            -- Siphon Life
        ELEMENTS,
        IMMOLATE,
        { spell = 686, has = 17941 },                           -- Shadow Bolt (Shadow Trance)
        HELLFIRE, RAIN,
        { spell = 1316697 },                                    -- Wrack (acelera los DoTs)
        DRAIN,
        BOLT,
    }) },
    [2] = { name = "Demonology", rules = ns.Engine.Join(PREP, Pets(SUCCUBUS, INCUBUS, VOIDWALKER, IMP), {
        { spell = 19028, ooc = true, on = "player", missing = true }, -- Soul Link
        TAP,
    }, RACIALS, {
        { spell = 5676, aura = 1293695, missing = true, dur = 10 }, -- Searing Pain (Demonic Brand)
        { spell = 6353, has = 440873 },                         -- Soul Fire (Decimation)
        DOOM, AGONY,
        CORRUPTION,
        ELEMENTS,
        IMMOLATE,
        HELLFIRE, RAIN,
        DRAIN,
        BOLT,
    }) },
    -- Diablillo en grupo (Pacto de sangre); en solitario, Sayaad
    [3] = { name = "Destruction", rules = ns.Engine.Join(PREP,
        { { spell = IMP, ooc = true, noPet = true, group = true } },
        Pets(SUCCUBUS, INCUBUS, VOIDWALKER, IMP), {
        TAP,
    }, RACIALS, {
        IMMOLATE,
        -- Consume Inmolar: dur 0 lo da por gastado en el rastreo propio
        { spell = 1293817, aura = 348, dur = 0 },               -- Conflagrate
        DOOM, AGONY,
        ELEMENTS,
        CORRUPTION,
        { spell = 17877, elite = true },                        -- Shadowburn (gasta fragmento: solo elites)
        HELLFIRE, RAIN,
        { spell = 412758 },                                     -- Incinerate
        BOLT,
    }) },
}

ns.Heals.WARLOCK = {
    { spell = 6789 },                                           -- Death Coil
    { spell = 689 },                                            -- Drain Life
}
