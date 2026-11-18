local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- Formas: 0 sin forma, 1 gato, 5 oso, 8 oso temible, 31 lechucico. Cada rama
-- recomienda segun la forma en la que estas: no te saca de oso para lanzar
-- Fuego estelar. Guias de WoW Forever (Warcraft Tavern).

local Join = ns.Engine.Join

local CAT = {
    { spell = 6785, form = 1, stealth = true },                 -- Ravage
    { spell = 417141, form = 1, elite = true },                 -- Berserk
    { spell = 1238122, form = 1, melee = false },               -- Feral Charge
    { spell = 770, form = 1, missing = true, dur = 40 },        -- Faerie Fire (en forma, si Forever lo permite)
    { spell = 1079, form = 1, cp = 5, missing = true, dur = 12 }, -- Rip
    { spell = 22568, form = 1, cp = 5 },                        -- Ferocious Bite
    { spell = 1822, form = 1, missing = true, dur = 9 },        -- Rake
    { spell = 5221, form = 1, group = true },                   -- Shred (en grupo sueles estar detras)
    { spell = 1082, form = 1 },                                 -- Claw
    { spell = 1322605, form = 1 },                              -- Shifting Power (sin energia para lo anterior)
}

-- Oso (5) y oso temible (8, nivel 40) son formas distintas
local function Bear(form)
    return {
        { spell = 417141, form = form, elite = true },          -- Berserk
        { spell = 5229, form = form, melee = false },           -- Enrage
        { spell = 1238122, form = form, melee = false },        -- Feral Charge
        { spell = 779, form = form, aoe = 2 },                  -- Swipe
        { spell = 770, form = form, missing = true, dur = 40 }, -- Faerie Fire
        { spell = 99, form = form, missing = true, dur = 30 },  -- Demoralizing Roar
        { spell = 407995, form = form },                        -- Primal Bite
        { spell = 1328617, form = form, stacksBelow = 5, dur = 15, max = 5 }, -- Lacerate
        { spell = 6807, form = form },                          -- Maul
    }
end

-- Lanzador: sin forma o en lechucico. Eclipse (408255): Ira acorta los
-- siguientes Fuego estelar; en combate se rastrea 15 s desde cada Ira.
local function Caster(form)
    return {
        { spell = 29166, form = form, lowMana = true },         -- Innervate
        { spell = 16689, form = form, melee = true },           -- Nature's Grasp
        { spell = 770, form = form, group = true, missing = true, dur = 40 }, -- Faerie Fire
        { spell = 8921, form = form, missing = true, dur = 12 }, -- Moonfire
        { spell = 5570, form = form, missing = true, dur = 12 }, -- Insect Swarm
        { spell = 16914, form = form, aoe = 5 },                -- Hurricane
        { spell = 2912, form = form, has = 408255 },            -- Starfire (Eclipse)
        { spell = 5176, form = form, aura = 408255, on = "player", dur = 15, max = 4 }, -- Wrath
    }
end

local BEAR = Join(Bear(5), Bear(8))

-- Fuera de combate y sin forma: Marca de lo Salvaje y Espinas; racial contra elites
local PREP = {
    { spell = 1126, ooc = true, form = 0, on = "player", missing = true },  -- Mark of the Wild
    { spell = 467, ooc = true, form = 0, on = "player", missing = true },   -- Thorns
    { spell = 1259799, elite = true },                          -- Elune's Light (elfo de la noche)
}

ns.Rotations.DRUID = {
    [1] = { name = "Balance", rules = Join(PREP,
        { { spell = 24858, form = 0 } },                        -- Moonkin Form
        Caster(31), Caster(0), CAT, BEAR) },
    [2] = { name = "Feral", rules = Join(PREP,
        CAT, BEAR, {
            { spell = 768, form = 0 },                          -- Cat Form
            { spell = 5487, form = 0, ifUnknown = 768 },        -- Bear Form (antes del 20)
        }, Caster(0)) },
    [3] = { name = "Restoration", rules = Join(PREP, Caster(0), CAT, BEAR) },
}

-- Corteza en cualquier forma; en oso, Regeneracion frenetica; sin forma, curas
ns.Heals.DRUID = {
    { spell = 22812 },                                          -- Barkskin
    { spell = 22842, form = 5 },                                -- Frenzied Regeneration
    { spell = 22842, form = 8 },                                -- Frenzied Regeneration
    { spell = 18562, form = 0, has = 774 },                     -- Swiftmend (con Rejuvenecimiento puesto)
    { spell = 774, form = 0, on = "player", missing = true, dur = 12 }, -- Rejuvenation
    { spell = 8936, form = 0 },                                 -- Regrowth
    { spell = 5185, form = 0 },                                 -- Healing Touch
}
