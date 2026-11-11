local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- Disciplina y Sagrado: rotacion de dano para subir de nivel o en solitario.
-- Las curas dependen de la vida del grupo, que en combate es secreta.

local SWP      = { spell = 589, missing = true, dur = 18 }  -- Shadow Word: Pain
local NOVA     = { spell = 15237, aoe = 3, melee = true }   -- Holy Nova
local SMITE    = { spell = 585 }                            -- Smite

local PREP = {
    { spell = 1243, ooc = true, on = "player", missing = true }, -- Power Word: Fortitude
    { spell = 588, ooc = true, on = "player", missing = true },  -- Inner Fire
}

local HOLY_DPS = ns.Engine.Join(PREP, {
    { spell = 14914, missing = true, dur = 10 },            -- Holy Fire
    { spell = 402174 },                                     -- Penance
    SWP,
    NOVA,
    SMITE,
})

ns.Rotations.PRIEST = {
    [1] = { name = "Discipline", rules = ns.Engine.Join(
        { { spell = 14751, elite = true } },                -- Inner Focus
        HOLY_DPS) },
    [2] = { name = "Holy", rules = HOLY_DPS },
    [3] = { name = "Shadow", rules = ns.Engine.Join(PREP, {
        { spell = 15473, notForm = 28 },                    -- Shadowform
        SWP,
        { spell = 2944, missing = true, dur = 24 },         -- Devouring Plague
        { spell = 8092 },                                   -- Mind Blast
        { spell = 1309595 },                                -- Shadow Word: Death
        { spell = 15407 },                                  -- Mind Flay
        { spell = 585, ifUnknown = 15407 },                 -- Smite (antes de Mind Flay)
    }) },
}

-- Escudo primero; Alma debilitada (6788) impide repetirlo durante 15 s
ns.Heals.PRIEST = {
    { spell = 17, on = "player", aura = 6788, missing = true, dur = 15 }, -- Power Word: Shield
    { spell = 2061 },                                           -- Flash Heal
    { spell = 2050 },                                           -- Lesser Heal
}
