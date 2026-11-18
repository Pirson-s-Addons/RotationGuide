local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- WoW Forever: el Juicio ya no consume el sello, asi que es un boton mas.
-- Mando sustituye a Rectitud en cuanto se conoce; la proteccion en grupo
-- usa Sello de furia (su Juicio provoca). Martillo de colera solo es usable
-- bajo el 20 %. Exorcismo y Colera sagrada (solo no-muertos y demonios) no
-- se listan: el motor no distingue el tipo de criatura.

local COMMAND     = { spell = 20375, on = "player", missing = { 20375 }, dur = 30 } -- Seal of Command
local FURY        = { spell = 1311649, on = "player", missing = { 1311649 }, dur = 30 } -- Seal of Fury
local RIGHTEOUS   = { spell = 20154, on = "player", missing = { 20375, 20154, 21084 }, dur = 30 } -- Seal of Righteousness
local JUDGEMENT   = { spell = 20271 }                                        -- Judgement
local HAMMER      = { spell = 24275 }                                        -- Hammer of Wrath
local HOLY_STRIKE = { spell = 679 }                                          -- Holy Strike

-- Fuera de combate: aura propia y Reyes (o la bendicion de la rama si aun no)
local AURAS = { 465, 7294, 19746 }  -- Devotion, Retribution, Concentration
local BLESSINGS = { 20217, 19740, 19742, 25898, 25782, 25894 }  -- Kings, Might, Wisdom y sus mayores
local function Prep(aura, blessing)
    return {
        { spell = aura, ooc = true, on = "player", missing = AURAS },
        { spell = 465, ooc = true, on = "player", missing = AURAS, ifUnknown = aura },   -- Devotion Aura
        { spell = 20217, ooc = true, on = "player", missing = BLESSINGS },               -- Blessing of Kings
        { spell = blessing, ooc = true, on = "player", missing = BLESSINGS, ifUnknown = 20217 },
    }
end
local MIGHT, WISDOM = 19740, 19742  -- Blessing of Might / Wisdom

ns.Rotations.PALADIN = {
    [1] = { name = "Holy", rules = ns.Engine.Join(Prep(465, WISDOM), {
        RIGHTEOUS,
        HAMMER,
        { spell = 1311606 },                                    -- Holy Shock
        JUDGEMENT,
        HOLY_STRIKE,
        { spell = 26573, aoe = 2 },                             -- Consecration
    }) },
    [2] = { name = "Protection", solo = 3, rules = ns.Engine.Join(Prep(465, MIGHT), {
        { spell = 25780, group = true, on = "player", missing = true, dur = 1800 }, -- Righteous Fury
        FURY,
        RIGHTEOUS,
        { spell = 20925, on = "player", missing = true, dur = 10 }, -- Holy Shield
        JUDGEMENT,
        { spell = 1310994 },                                    -- Swift Judgement (reinicia Juicio)
        HOLY_STRIKE,
        { spell = 26573 },                                      -- Consecration
        HAMMER,
    }) },
    [3] = { name = "Retribution", rules = ns.Engine.Join(Prep(7294, MIGHT), {
        COMMAND,
        RIGHTEOUS,
        HAMMER,
        HOLY_STRIKE,
        JUDGEMENT,
        { spell = 26573, aoe = 2 },                             -- Consecration
    }) },
}

-- Vida baja: defensivos (uno por Abstinencia), curas y, sin mana, Imposicion de manos
ns.Heals.PALADIN = {
    { spell = 1311015 },                                        -- Templar's Bulwark
    { spell = 642 },                                            -- Divine Shield
    { spell = 498, ifUnknown = 642 },                           -- Divine Protection
    { spell = 20594 },                                          -- Stoneform
    { spell = 19750 },                                          -- Flash of Light
    { spell = 635 },                                            -- Holy Light
    { spell = 633 },                                            -- Lay on Hands
}
