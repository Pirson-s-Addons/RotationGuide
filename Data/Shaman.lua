local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}

-- Los totems se rastrean como "aura" del jugador durante su duracion.

local FLAME_SHOCK = { spell = 8050, missing = true, dur = 12 }                      -- Flame Shock
local SEARING     = { spell = 3599, on = "player", single = true, missing = { 3599, 8190 }, dur = 30 } -- Searing Totem
local MAGMA       = { spell = 8190, on = "player", aoe = 2, melee = true, missing = { 3599, 8190 }, dur = 20 } -- Magma Totem
local BOLT        = { spell = 403 }                                                 -- Lightning Bolt

ns.Rotations.SHAMAN = {
    [1] = { name = "Elemental", rules = {
        MAGMA, SEARING,
        FLAME_SHOCK,
        { spell = 408490 },                                     -- Lava Burst
        { spell = 421 },                                        -- Chain Lightning
        BOLT,
    } },
    [2] = { name = "Enhancement", rules = {
        { spell = 8075, on = "player", missing = true, dur = 120 }, -- Strength of Earth Totem
        { spell = 8835, on = "player", missing = true, dur = 120 }, -- Grace of Air Totem
        MAGMA, SEARING,
        { spell = 17364 },                                      -- Stormstrike
        { spell = 403, has = 408505 },                          -- Lightning Bolt (Maelstrom)
        FLAME_SHOCK,
        { spell = 8042 },                                       -- Earth Shock
    } },
    [3] = { name = "Restoration", rules = {
        FLAME_SHOCK,
        { spell = 408341, aoe = 2 },                            -- Fire Nova
        BOLT,
    } },
}
