local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- Sellos: cualquier sello propio activo cuenta; si no hay, se pone el mejor
-- que se conozca. Martillo de colera solo es usable bajo el 20 %.

local SEALS = { 20375, 20154, 21084 }  -- Command, Righteousness (2 rangos)
local COMMAND     = { spell = 20375, on = "player", missing = SEALS, dur = 30 }  -- Seal of Command
local RIGHTEOUS   = { spell = 20154, on = "player", missing = SEALS, dur = 30 }  -- Seal of Righteousness
local JUDGEMENT   = { spell = 20271 }                                        -- Judgement
local HAMMER      = { spell = 24275 }                                        -- Hammer of Wrath
local HOLY_STRIKE = { spell = 679 }                                          -- Holy Strike

-- Fuera de combate: aura y bendicion propias
local AURAS = { 465, 7294, 19746 }  -- Devotion, Retribution, Concentration
local function Prep(aura, blessing)
    return {
        { spell = aura, ooc = true, on = "player", missing = AURAS },
        { spell = 465, ooc = true, on = "player", missing = AURAS, ifUnknown = aura },   -- Devotion Aura
        { spell = blessing, ooc = true, on = "player", missing = true },
    }
end
local MIGHT, WISDOM = 19740, 19742  -- Blessing of Might / Wisdom

ns.Rotations.PALADIN = {
    [1] = { name = "Holy", rules = ns.Engine.Join(Prep(465, WISDOM), {
        RIGHTEOUS,
        JUDGEMENT,
        HAMMER,
        { spell = 1311606 },                                    -- Holy Shock
        HOLY_STRIKE,
        { spell = 26573, aoe = 2 },                             -- Consecration
    }) },
    [2] = { name = "Protection", solo = 3, rules = ns.Engine.Join(Prep(465, MIGHT), {
        { spell = 25780, group = true, on = "player", missing = true, dur = 1800 }, -- Righteous Fury
        RIGHTEOUS,
        { spell = 20925, on = "player", missing = true, dur = 10 }, -- Holy Shield
        JUDGEMENT,
        { spell = 26573 },                                      -- Consecration
        HAMMER,
        HOLY_STRIKE,
    }) },
    [3] = { name = "Retribution", rules = ns.Engine.Join(Prep(7294, MIGHT), {
        COMMAND,
        RIGHTEOUS,
        JUDGEMENT,
        HAMMER,
        HOLY_STRIKE,
        { spell = 26573, aoe = 2 },                             -- Consecration
    }) },
}

ns.Heals.PALADIN = {
    { spell = 19750 },                                          -- Flash of Light
    { spell = 635 },                                            -- Holy Light
}
