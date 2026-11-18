local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

local EVOCATION = { spell = 12051, lowMana = true }  -- Evocation

-- Fuera de combate: Intelecto Arcano y la mejor armadura (Mage Armor en grupo)
local ARMORS = { 168, 7302, 6117 }  -- Frost Armor, Ice Armor, Mage Armor
local PREP = {
    { spell = 1459, ooc = true, on = "player", missing = true },             -- Arcane Intellect
    { spell = 6117, ooc = true, on = "player", missing = ARMORS, group = true }, -- Mage Armor
    { spell = 7302, ooc = true, on = "player", missing = ARMORS },           -- Ice Armor
    { spell = 168, ooc = true, on = "player", missing = ARMORS, ifUnknown = 7302 }, -- Frost Armor
}

-- Cooldowns de talento y raciales (Troll, Orco, Gnomo): lo desconocido se salta
local CDS = {
    { spell = 12042, elite = true },                            -- Arcane Power
    { spell = 11129, elite = true },                            -- Combustion
    { spell = 12043, elite = true },                            -- Presence of Mind
    { spell = 20554, elite = true },                            -- Berserking
    { spell = 20572, elite = true },                            -- Blood Fury
    { spell = 1259823, elite = true },                          -- Eureka!
}

local BARRAGE  = { spell = 5143, has = 400589 }                 -- Arcane Missiles (Missile Barrage)
local FINGERS  = { spell = 1312002, has = 400669 }              -- Ice Lance (Fingers of Frost)
local FIREBALL = { spell = 133, ifUnknown = 116 }               -- Fireball (niveles 1-3)

ns.Rotations.MAGE = {
    -- Arcane Blast hasta 4 cargas (18 s), luego Arcane Wrath y relleno que busca Missile Barrage
    [1] = { name = "Arcane", rules = ns.Engine.Join(PREP, { EVOCATION }, CDS, {
        { spell = 1449, aoe = 3, melee = true },                -- Arcane Explosion
        { spell = 10, aoe = 3 },                                -- Blizzard
        BARRAGE,
        { spell = 400574, has = 12536 },                        -- Arcane Blast (Clearcasting)
        { spell = 400574, aura = 400573, on = "player", stacksBelow = 4, dur = 18, max = 4 }, -- Arcane Blast
        { spell = 1326079 },                                    -- Arcane Wrath
        { spell = 2136 },                                       -- Fire Blast
        { spell = 116 },                                        -- Frostbolt
        FIREBALL,
    }) },
    [2] = { name = "Fire", rules = ns.Engine.Join(PREP, { EVOCATION }, CDS, {
        { spell = 11366, has = 400625, hasStacks = 3 },         -- Pyroblast (3 cargas de Heating Up)
        BARRAGE,
        FINGERS,
        -- Scorch acumula Improved Scorch (5) en el objetivo antes de Fireball
        { spell = 2948, aura = 22959, stacksBelow = 5, dur = 30, max = 5 }, -- Scorch
        { spell = 2120, aoe = 3, missing = true, dur = 8 },     -- Flamestrike
        { spell = 11113, aoe = 3, melee = true },               -- Blast Wave
        { spell = 1449, aoe = 3, melee = true },                -- Arcane Explosion
        { spell = 2136 },                                       -- Fire Blast
        { spell = 133 },                                        -- Fireball
    }) },
    [3] = { name = "Frost", rules = ns.Engine.Join(PREP, {
        { spell = 11426, ooc = true, on = "player", missing = true },        -- Ice Barrier
        EVOCATION,
        { spell = 11426, on = "player", missing = true, dur = 60 },          -- Ice Barrier
    }, CDS, {
        FINGERS,
        BARRAGE,
        { spell = 122, aoe = 3, melee = true },                 -- Frost Nova
        { spell = 120, aoe = 2, melee = true },                 -- Cone of Cold
        { spell = 1449, aoe = 3, melee = true },                -- Arcane Explosion
        { spell = 10, aoe = 3 },                                -- Blizzard
        { spell = 116 },                                        -- Frostbolt
        FIREBALL,
    }) },
}

-- Ice Block solo cuando el escudo de mana ya esta puesto
ns.Heals.MAGE = {
    { spell = 11426 },                                          -- Ice Barrier
    { spell = 1463, on = "player", missing = true, dur = 60 },  -- Mana Shield
    { spell = 11958 },                                          -- Ice Block
}
