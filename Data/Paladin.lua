local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}

-- Sellos: cualquier sello propio activo cuenta; si no hay, se pone el mejor
-- que se conozca. Martillo de colera solo es usable bajo el 20 %.

local SEALS = { 20375, 20154, 21084 }  -- Command, Righteousness (2 rangos)
local COMMAND     = { spell = 20375, on = "player", missing = SEALS, dur = 30 }  -- Seal of Command
local RIGHTEOUS   = { spell = 20154, on = "player", missing = SEALS, dur = 30 }  -- Seal of Righteousness
local JUDGEMENT   = { spell = 20271 }                                        -- Judgement
local HAMMER      = { spell = 24275 }                                        -- Hammer of Wrath
local HOLY_STRIKE = { spell = 679 }                                          -- Holy Strike

ns.Rotations.PALADIN = {
    [1] = { name = "Holy", rules = {
        RIGHTEOUS,
        JUDGEMENT,
        HAMMER,
        { spell = 1311606 },                                    -- Holy Shock
        HOLY_STRIKE,
        { spell = 26573, aoe = 2 },                             -- Consecration
    } },
    [2] = { name = "Protection", rules = {
        RIGHTEOUS,
        { spell = 20925, on = "player", missing = true, dur = 10 }, -- Holy Shield
        JUDGEMENT,
        { spell = 26573 },                                      -- Consecration
        HAMMER,
        HOLY_STRIKE,
    } },
    [3] = { name = "Retribution", rules = {
        COMMAND,
        RIGHTEOUS,
        JUDGEMENT,
        HAMMER,
        HOLY_STRIKE,
        { spell = 26573, aoe = 2 },                             -- Consecration
    } },
}
