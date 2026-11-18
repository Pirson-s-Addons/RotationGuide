local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- Formas: 17 Batalla, 18 Defensiva, 19 Rabia.
-- Ejecutar, Abrumar, Revancha, Carga y Arremetida victoriosa solo son "usables"
-- cuando el juego lo permite (objetivo bajo 20 %, tras esquiva o bloqueo,
-- fuera de combate, tras matar) y la actitud la comprueba el juego, asi que
-- basta con listarlas. Talentos, runas y raciales que no se conocen se saltan.

local CHARGE  = { spell = 100, melee = false }                       -- Charge
local SHOUT   = { spell = 6673, on = "player", missing = true, dur = 180 } -- Battle Shout (3 min en Forever)
local VICTORY = { spell = 402927 }                                   -- Victory Rush
local SUNDER  = { spell = 7386, missing = true, dur = 30, max = 5 }  -- Sunder Armor

-- Generadores de ira: en cuanto esten listos
local RAGE = {
    { spell = 2687 },                                           -- Bloodrage
    { spell = 1329555 },                                        -- Reckless Swings
}

-- Cooldowns para elites y jefes
local BURST = {
    { spell = 12328, elite = true },                            -- Death Wish
    { spell = 20572, elite = true },                            -- Blood Fury (orco)
    { spell = 20554, elite = true },                            -- Berserking (trol)
}

ns.Rotations.WARRIOR = {
    [1] = { name = "Arms", rules = ns.Engine.Join({
        { spell = 2457, notForm = 17 },                         -- Battle Stance
        CHARGE,
        SHOUT,
        VICTORY,
    }, RAGE, BURST, {
        { spell = 12292, aoe = 2 },                             -- Sweeping Strikes
        { spell = 7384 },                                       -- Overpower
        { spell = 12294 },                                      -- Mortal Strike
        { spell = 772, single = true, missing = true, dur = 15 }, -- Rend (activa Bloodthrill)
        { spell = 5308 },                                       -- Execute
        SUNDER,
        { spell = 6343, aoe = 2 },                              -- Thunder Clap
        { spell = 1160, aoe = 2, missing = true, dur = 45 },    -- Demoralizing Shout
        { spell = 1240193 },                                    -- Slam
        { spell = 1310222 },                                    -- Spearing Strike
        { spell = 429765, single = true },                      -- Quick Strike
        { spell = 845, aoe = 2 },                               -- Cleave
        { spell = 78, single = true },                          -- Heroic Strike
    }) },
    [2] = { name = "Fury", rules = ns.Engine.Join({
        { spell = 2458, notForm = 19 },                         -- Berserker Stance
        CHARGE,
        { spell = 20252, melee = false },                       -- Intercept
        SHOUT,
        VICTORY,
    }, RAGE, BURST, {
        { spell = 1719, elite = true },                         -- Recklessness
        { spell = 5308 },                                       -- Execute
        { spell = 23881 },                                      -- Bloodthirst
        { spell = 1680 },                                       -- Whirlwind
        { spell = 402911 },                                     -- Raging Blow
        { spell = 7384 },                                       -- Overpower (antes de Rabia)
        { spell = 1310222 },                                    -- Spearing Strike (antes de Rabia)
        { spell = 1160, aoe = 2, missing = true, dur = 45 },    -- Demoralizing Shout
        SUNDER,
        { spell = 1240193 },                                    -- Slam
        { spell = 845, aoe = 2 },                               -- Cleave
        { spell = 78, single = true },                          -- Heroic Strike
    }) },
    [3] = { name = "Protection", solo = 1, rules = ns.Engine.Join({
        { spell = 71, notForm = 18 },                           -- Defensive Stance
        CHARGE,                                                 -- (en Defensiva con Vanguard)
        SHOUT,
        VICTORY,
    }, RAGE, {
        { spell = 23922 },                                      -- Shield Slam
        { spell = 6572 },                                       -- Revenge
        { spell = 2565 },                                       -- Shield Block
        { spell = 6343, missing = true, dur = 18 },             -- Thunder Clap
        { spell = 1160, missing = true, dur = 45 },             -- Demoralizing Shout
        { spell = 440488, aoe = 2 },                            -- Shockwave
        { spell = 7386, stacksBelow = 5, dur = 30, max = 5 },   -- Sunder Armor
        { spell = 845, aoe = 2 },                               -- Cleave
        { spell = 78 },                                         -- Heroic Strike
        { spell = 7386 },                                       -- Sunder Armor (relleno)
    }) },
}

-- Sin curas propias: defensivos cuando la vida baja
ns.Heals.WARRIOR = {
    { spell = 402927 },                                         -- Victory Rush
    { spell = 402913 },                                         -- Enraged Regeneration
    { spell = 12975 },                                          -- Last Stand
    { spell = 871 },                                            -- Shield Wall
    { spell = 20594 },                                          -- Stoneform (enano)
}
