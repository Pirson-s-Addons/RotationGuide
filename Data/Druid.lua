local ADDON_NAME, ns = ...
ns.Rotations = ns.Rotations or {}
ns.Heals = ns.Heals or {}

-- Formas: 0 sin forma, 1 gato, 5 oso, 31 lechucico. Cada rama recomienda
-- segun la forma en la que estas: no te saca de oso para lanzar Fuego estelar.

local CAT = {
    { spell = 6785, form = 1, stealth = true },                 -- Ravage
    { spell = 1822, form = 1, missing = true, dur = 9 },        -- Rake
    { spell = 16857, form = 1, missing = true, dur = 40 },      -- Faerie Fire (Feral)
    { spell = 1079, form = 1, cp = 5, missing = true, dur = 12 }, -- Rip
    { spell = 22568, form = 1, cp = 5 },                        -- Ferocious Bite
    { spell = 1082, form = 1 },                                 -- Claw
}

local BEAR = {
    { spell = 779, form = 5, aoe = 2 },                         -- Swipe
    { spell = 16857, form = 5, missing = true, dur = 40 },      -- Faerie Fire (Feral)
    { spell = 99, form = 5, missing = true, dur = 30 },         -- Demoralizing Roar
    { spell = 407995, form = 5 },                               -- Primal Bite
    { spell = 414644, form = 5, stacksBelow = 5, dur = 15, max = 5 }, -- Lacerate
    { spell = 6807, form = 5 },                                 -- Maul
}

-- Lanzador: sin forma o en lechucico
local function Caster(form)
    return {
        { spell = 29166, form = form, lowMana = true },         -- Innervate
        { spell = 770, form = form, missing = true, dur = 40 }, -- Faerie Fire
        { spell = 8921, form = form, missing = true, dur = 12 }, -- Moonfire
        { spell = 5570, form = form, missing = true, dur = 12 }, -- Insect Swarm
        { spell = 16914, form = form, aoe = 3 },                -- Hurricane
        { spell = 2912, form = form },                          -- Starfire
        { spell = 5176, form = form },                          -- Wrath
    }
end

local Join = ns.Engine.Join

-- Fuera de combate y sin forma: Marca de lo Salvaje y Espinas
local PREP = {
    { spell = 1126, ooc = true, form = 0, on = "player", missing = true },  -- Mark of the Wild
    { spell = 467, ooc = true, form = 0, on = "player", missing = true },   -- Thorns
}

ns.Rotations.DRUID = {
    [1] = { name = "Balance", rules = Join(PREP,
        { { spell = 24858, form = 0 } },                        -- Moonkin Form
        Caster(31), Caster(0), CAT, BEAR) },
    [2] = { name = "Feral", rules = Join(PREP,
        CAT, BEAR,
        { { spell = 768, form = 0 } }) },                       -- Cat Form
    [3] = { name = "Restoration", rules = Join(PREP, Caster(0), CAT, BEAR) },
}

-- En oso, Regeneracion frenetica; sin forma, las curas normales
ns.Heals.DRUID = {
    { spell = 22842, form = 5 },                                -- Frenzied Regeneration
    { spell = 774, form = 0, on = "player", missing = true, dur = 12 }, -- Rejuvenation
    { spell = 8936, form = 0 },                                 -- Regrowth
    { spell = 5185, form = 0 },                                 -- Healing Touch
}
