local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

local EVOCATION = { spell = 12051, lowMana = true }  -- Evocation

-- Fuera de combate: Intelecto Arcano y la mejor armadura que se conozca
local ARMORS = { 168, 7302, 6117 }  -- Frost Armor, Ice Armor, Mage Armor
local PREP = {
    { spell = 1459, ooc = true, on = "player", missing = true },             -- Arcane Intellect
    { spell = 7302, ooc = true, on = "player", missing = ARMORS },           -- Ice Armor
    { spell = 168, ooc = true, on = "player", missing = ARMORS, ifUnknown = 7302 }, -- Frost Armor
}

ns.Rotations.MAGE = {
    [1] = { name = "Arcane", rules = ns.Engine.Join(PREP, {
        EVOCATION,
        { spell = 12042, elite = true },                        -- Arcane Power
        { spell = 1449, aoe = 3, melee = true },                -- Arcane Explosion
        { spell = 10, aoe = 3 },                                -- Blizzard
        { spell = 5143, has = 44404 },                          -- Arcane Missiles (proc)
        { spell = 2136 },                                       -- Fire Blast
        { spell = 400574 },                                     -- Arcane Blast
        { spell = 116, ifUnknown = 400574 },                    -- Frostbolt
    }) },
    [2] = { name = "Fire", rules = ns.Engine.Join(PREP, {
        EVOCATION,
        { spell = 11366, has = 400625 },                        -- Pyroblast (Hot Streak)
        -- Scorch acumula Improved Scorch (5) en el objetivo antes de Fireball
        { spell = 2948, aura = 22959, stacksBelow = 5, dur = 30, max = 5 }, -- Scorch
        { spell = 11129, elite = true },                        -- Combustion
        { spell = 11113, aoe = 3, melee = true },               -- Blast Wave
        { spell = 2120, aoe = 3 },                              -- Flamestrike
        { spell = 2136 },                                       -- Fire Blast
        { spell = 133 },                                        -- Fireball
        { spell = 2948 },                                       -- Scorch (relleno)
    }) },
    [3] = { name = "Frost", rules = ns.Engine.Join(PREP, {
        EVOCATION,
        { spell = 1312002, has = 400669 },                      -- Ice Lance (Fingers of Frost)
        { spell = 120, aoe = 2, melee = true },                 -- Cone of Cold
        { spell = 122, aoe = 3, melee = true },                 -- Frost Nova
        { spell = 10, aoe = 3 },                                -- Blizzard
        { spell = 116 },                                        -- Frostbolt
    }) },
}

ns.Heals.MAGE = {
    { spell = 11426 },                                          -- Ice Barrier
    { spell = 1463 },                                           -- Mana Shield
}
