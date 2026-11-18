local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- Disciplina y Sagrado: rotacion de dano (Smite) para subir de nivel o en solitario.
-- Las curas dependen de la vida del grupo, que en combate es secreta.
-- Raciales y talentos que no se conocen se saltan solos.

local SWP        = { spell = 589, missing = true, dur = 18 }   -- Shadow Word: Pain
local PLAGUE     = { spell = 2944, missing = true, dur = 24 }  -- Devouring Plague
local STARSHARDS = { spell = 10797 }                           -- Starshards (elfo de la noche)

-- Fuera de combate: buffs propios (Shadowguard trol, Touch of Weakness no-muerto)
local PREP = {
    { spell = 1243, ooc = true, on = "player", missing = true },  -- Power Word: Fortitude
    { spell = 14752, ooc = true, on = "player", missing = true }, -- Divine Spirit
    { spell = 588, ooc = true, on = "player", missing = true },   -- Inner Fire
    { spell = 18137, ooc = true, on = "player", missing = true }, -- Shadowguard
    { spell = 2652, ooc = true, on = "player", missing = true },  -- Touch of Weakness
}

-- Mana y cooldowns para elites y jefes
local COOLDOWNS = {
    { spell = 1277324, lowMana = true },                       -- Dark Sacrifice (no-muerto)
    { spell = 20554, elite = true },                           -- Berserking (trol)
    { spell = 10060, elite = true },                           -- Power Infusion
    { spell = 14751, elite = true },                           -- Inner Focus
    { spell = 9035, elite = true, missing = true, dur = 120 }, -- Hex of Weakness (trol)
}

-- Holy Fire primero: abre y Power in Light potencia Smite y Penance
local SMITE_DPS = ns.Engine.Join(PREP, COOLDOWNS, {
    { spell = 14914, missing = true, dur = 10 },            -- Holy Fire
    SWP,
    PLAGUE,
    { spell = 402174 },                                     -- Penance
    STARSHARDS,
    { spell = 15237, aoe = 3, melee = true },               -- Holy Nova
    { spell = 585 },                                        -- Smite
})

ns.Rotations.PRIEST = {
    [1] = { name = "Discipline", rules = SMITE_DPS },
    [2] = { name = "Holy", rules = SMITE_DPS },
    [3] = { name = "Shadow", rules = ns.Engine.Join(PREP,
        { { spell = 15473, notForm = 28 } },                -- Shadowform
        COOLDOWNS, {
        { spell = 15286 },                                  -- Vampiric Embrace (su cooldown marca el refresco)
        SWP,
        PLAGUE,
        { spell = 8092 },                                   -- Mind Blast
        { spell = 1309595 },                                -- Shadow Word: Death
        STARSHARDS,
        { spell = 15407 },                                  -- Mind Flay
        { spell = 585, ifUnknown = 15407 },                 -- Smite (antes de Mind Flay)
    }) },
}

-- Rezo desesperado (instantaneo, sin mana) y luego escudo; Alma debilitada (6788) impide repetirlo 15 s
ns.Heals.PRIEST = {
    { spell = 13908 },                                          -- Desperate Prayer (enano/humano)
    { spell = 17, on = "player", aura = 6788, missing = true, dur = 15 }, -- Power Word: Shield
    { spell = 2061 },                                           -- Flash Heal
    { spell = 2050 },                                           -- Lesser Heal
}
