local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}

local EVOCATION = { spell = 12051, lowMana = true }  -- Evocation

ns.Rotations.MAGE = {
    [1] = { name = "Arcane", rules = {
        EVOCATION,
        { spell = 12042 },                                      -- Arcane Power
        { spell = 1449, aoe = 3, melee = true },                -- Arcane Explosion
        { spell = 10, aoe = 3 },                                -- Blizzard
        { spell = 5143, has = 44404 },                          -- Arcane Missiles (proc)
        { spell = 2136 },                                       -- Fire Blast
        { spell = 400574 },                                     -- Arcane Blast
        { spell = 116, ifUnknown = 400574 },                    -- Frostbolt
    } },
    [2] = { name = "Fire", rules = {
        EVOCATION,
        { spell = 11366, has = 400625 },                        -- Pyroblast (Hot Streak)
        -- Scorch acumula Improved Scorch (5) en el objetivo antes de Fireball
        { spell = 2948, aura = 22959, stacksBelow = 5, dur = 30, max = 5 }, -- Scorch
        { spell = 11129 },                                      -- Combustion
        { spell = 11113, aoe = 3, melee = true },               -- Blast Wave
        { spell = 2120, aoe = 3 },                              -- Flamestrike
        { spell = 2136 },                                       -- Fire Blast
        { spell = 133 },                                        -- Fireball
        { spell = 2948 },                                       -- Scorch (relleno)
    } },
    [3] = { name = "Frost", rules = {
        EVOCATION,
        { spell = 1312002, has = 400669 },                      -- Ice Lance (Fingers of Frost)
        { spell = 120, aoe = 2, melee = true },                 -- Cone of Cold
        { spell = 122, aoe = 3, melee = true },                 -- Frost Nova
        { spell = 10, aoe = 3 },                                -- Blizzard
        { spell = 116 },                                        -- Frostbolt
    } },
}
