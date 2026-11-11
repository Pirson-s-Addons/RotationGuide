local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}

-- Formas: 17 Batalla, 18 Defensiva, 19 Rabia.
-- Ejecutar, Abrumar y Revancha solo son "usables" cuando el juego lo permite
-- (objetivo bajo 20 %, tras esquiva o bloqueo), asi que basta con listarlas.

local SHOUT  = { spell = 6673, on = "player", missing = true, dur = 120 } -- Battle Shout
local SUNDER = { spell = 7386, missing = true, dur = 30, max = 5 }        -- Sunder Armor

ns.Rotations.WARRIOR = {
    [1] = { name = "Arms", rules = {
        { spell = 2457, notForm = 17 },                         -- Battle Stance
        SHOUT,
        { spell = 5308 },                                       -- Execute
        { spell = 7384 },                                       -- Overpower
        { spell = 12294 },                                      -- Mortal Strike
        { spell = 1310222 },                                    -- Spearing Strike
        { spell = 6343, aoe = 2 },                              -- Thunder Clap
        { spell = 1160, aoe = 2, missing = true, dur = 30 },    -- Demoralizing Shout
        { spell = 772, single = true, missing = true, dur = 21 }, -- Rend
        SUNDER,
        { spell = 1240193 },                                    -- Slam
        { spell = 845, aoe = 2 },                               -- Cleave
        { spell = 78, single = true },                          -- Heroic Strike
    } },
    [2] = { name = "Fury", rules = {
        { spell = 2458, notForm = 19 },                         -- Berserker Stance
        SHOUT,
        { spell = 5308 },                                       -- Execute
        { spell = 12328 },                                      -- Death Wish
        { spell = 23881 },                                      -- Bloodthirst
        { spell = 1680 },                                       -- Whirlwind
        { spell = 1310222 },                                    -- Spearing Strike
        { spell = 1160, aoe = 2, missing = true, dur = 30 },    -- Demoralizing Shout
        SUNDER,
        { spell = 1240193 },                                    -- Slam
        { spell = 845, aoe = 2 },                               -- Cleave
        { spell = 78, single = true },                          -- Heroic Strike
    } },
    [3] = { name = "Protection", rules = {
        { spell = 71, notForm = 18 },                           -- Defensive Stance
        SHOUT,
        { spell = 23922 },                                      -- Shield Slam
        { spell = 6572 },                                       -- Revenge
        { spell = 6343, missing = true, dur = 26 },             -- Thunder Clap
        { spell = 1160, missing = true, dur = 30 },             -- Demoralizing Shout
        { spell = 7386, stacksBelow = 5, dur = 30, max = 5 },   -- Sunder Armor
        { spell = 845, aoe = 2 },                               -- Cleave
        { spell = 78 },                                         -- Heroic Strike
        { spell = 7386 },                                       -- Sunder Armor (relleno)
    } },
}
