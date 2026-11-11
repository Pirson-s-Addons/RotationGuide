local ADDON_NAME, ns = ...

-- ==========================================
-- ESTADO DEL JUGADOR (lo que el motor pregunta)
-- ==========================================
-- En combate Forever oculta (valores secretos) auras, cooldowns y recursos.
-- Cada consulta intenta primero la API y, si el valor llega secreto, tira de
-- un plan B: cooldowns via un Cooldown oculto, auras via nuestro propio
-- rastreo de casts y recursos via "no hay poder suficiente" de IsSpellUsable.

local S = {}
ns.State = S

local issecretvalue = issecretvalue
local GetTime = GetTime

-- nil si el valor es secreto: compararlo lanzaria un error
local function Clean(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
ns.Clean = Clean

-- ------------------------------------------
-- Libro de hechizos: nombre -> id del rango mas alto conocido
-- ------------------------------------------
local bookByName = {}

function S.CacheSpellbook()
    wipe(bookByName)
    local line = 1
    while true do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
        if not info then break end
        for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
            local item = C_SpellBook.GetSpellBookItemInfo(slot, Enum.SpellBookSpellBank.Player)
            local id = item and Clean(item.spellID)
            if id and not item.isPassive then
                local name = C_Spell.GetSpellName(id)
                -- El libro lista los rangos de menor a mayor: el ultimo gana
                if name then bookByName[name] = id end
            end
        end
        line = line + 1
    end
end

local nameCache = {}
local function NameOf(id)
    local name = nameCache[id]
    if name == nil then
        name = C_Spell.GetSpellName(id) or false
        nameCache[id] = name
    end
    return name or nil
end
S.NameOf = NameOf

function S.Known(id)
    local name = NameOf(id)
    return name and bookByName[name] or nil
end

-- ------------------------------------------
-- Cooldowns
-- ------------------------------------------
local scratch

-- El objeto de duracion puede venir con valores secretos; un frame Cooldown
-- si sabe pintarlo, y si se muestra o no es un dato que podemos leer.
local function ShownByCooldownFrame(duration)
    if not scratch then
        local holder = CreateFrame("Frame", nil, UIParent)
        holder:Hide()
        scratch = CreateFrame("Cooldown", nil, holder, "CooldownFrameTemplate")
    end
    local ok = pcall(scratch.SetCooldownFromDurationObject, scratch, duration)
    if not ok then return false end
    local shown = scratch:IsShown()
    pcall(scratch.Clear, scratch)
    return shown and true or false
end

local function OnCooldown(id)
    if C_Spell.GetSpellCooldownDuration then
        local ok, duration = pcall(C_Spell.GetSpellCooldownDuration, id, true)
        if not ok or not duration then return false end
        local okZero, zero = pcall(duration.IsZero, duration)
        zero = okZero and Clean(zero)
        if zero ~= nil then return not zero end
        return ShownByCooldownFrame(duration)
    end
    local info = C_Spell.GetSpellCooldown(id)
    local length = info and Clean(info.duration)
    -- Sin el objeto de duracion: 1.5 s o menos es el cooldown global
    return length ~= nil and length > 1.5
end

-- Usable cubre recursos (mana, ira, energia, combo), actitud y requisitos
-- como "objetivo por debajo del 20 %" de Ejecutar o Martillo de cólera.
function S.Ready(id)
    local usable = Clean(C_Spell.IsSpellUsable(id))
    return usable == true and not OnCooldown(id)
end

-- ------------------------------------------
-- Auras: API cuando se puede, rastreo propio cuando no
-- ------------------------------------------
local track = { player = {} }
local trackByName = {}

local function TargetKey()
    local guid = Clean(UnitGUID("target"))
    return guid or "target"
end

local function KeyFor(unit)
    return unit == "player" and "player" or TargetKey()
end

-- Indice del motor (spell -> auras que deja) pasado a nombres, porque el
-- evento de cast trae el id del rango lanzado, no el de la regla
function S.SetTracking(index)
    wipe(trackByName)
    for spell, entries in pairs(index) do
        local name = NameOf(spell)
        if name then trackByName[name] = entries end
    end
end

function S.OnCast(spellID)
    spellID = Clean(spellID)
    local entries = spellID and trackByName[NameOf(spellID) or ""]
    if not entries then return end
    local now = GetTime()
    for _, entry in ipairs(entries) do
        local key = KeyFor(entry.on)
        local auraName = NameOf(entry.aura)
        if auraName then
            track[key] = track[key] or {}
            local current = track[key][auraName]
            local stacks = 1
            if current and current.expires > now then
                stacks = math.min(current.stacks + 1, entry.max)
            end
            track[key][auraName] = { expires = now + entry.dur, stacks = stacks }
        end
    end
end

-- Al salir de combate o morir, los objetivos rastreados ya no valen
function S.ForgetTargets()
    local player = track.player
    wipe(track)
    track.player = player
end

function S.ForgetAll()
    wipe(track)
    track.player = {}
end

-- Sin GUID legible la clave es "target": no sobrevive a un cambio de objetivo
function S.OnTargetChanged()
    track.target = nil
end

local function ApiAura(id, unit)
    local name = NameOf(id)
    if not name then return nil end
    local filter = unit == "player" and "HELPFUL" or "HARMFUL|PLAYER"
    local ok, data = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, name, filter)
    if ok and data and Clean(data) then return data end
    return nil
end

local function Tracked(id, unit)
    local name = NameOf(id)
    local bucket = name and track[KeyFor(unit)]
    local entry = bucket and bucket[name]
    if entry and entry.expires > GetTime() then return entry end
    return nil
end

-- Sellos de paladin: si Seal Timers Forever esta instalado, sabe cual hay puesto
-- y cuando se acaba aunque el aura sea secreta (cuenta desde el lanzamiento).
-- true / false si lo sabe; nil si no esta o el nombre no es de un sello.
local function SealActive(name, unit)
    local api = SealTimersForeverAPI
    if unit ~= "player" or type(api) ~= "table" or api.version ~= 1 or not api.IsSeal(name) then return nil end
    local seal = api.GetActiveSeal()
    if not seal or seal.name ~= name then return false end
    return seal.expiresAt == nil or seal.expiresAt > GetTime()
end

function S.AuraActive(id, unit)
    local seal = SealActive(NameOf(id), unit)
    if seal ~= nil then return seal end
    return (ApiAura(id, unit) or Tracked(id, unit)) and true or false
end

function S.Stacks(id, unit)
    local data = ApiAura(id, unit)
    if data then
        local count = Clean(data.applications)
        return count and math.max(count, 1) or 1
    end
    local entry = Tracked(id, unit)
    return entry and entry.stacks or 0
end

-- ------------------------------------------
-- Resto de condiciones
-- ------------------------------------------
function S.Form()
    return Clean(GetShapeshiftFormID()) or 0
end

function S.Stealthed()
    return Clean(IsStealthed()) == true
end

function S.ComboPoints()
    local points = Clean(GetComboPoints("player", "target"))
    if points == nil and Enum.PowerType.ComboPoints then
        points = Clean(UnitPower("player", Enum.PowerType.ComboPoints))
    end
    return points
end

-- Hechizo de melee por clase para medir distancia; el resto usa los 10 m de
-- CheckInteractDistance
local MELEE_PROBE = {
    WARRIOR = 78, ROGUE = 1752, HUNTER = 2973, PALADIN = 679, DRUID = 1082,
}

function S.InMelee()
    local probe = MELEE_PROBE[ns.class] and S.Known(MELEE_PROBE[ns.class])
    if probe then
        local inRange = Clean(C_Spell.IsSpellInRange(probe, "target"))
        if inRange ~= nil then return inRange == true end
    end
    local ok, near = pcall(CheckInteractDistance, "target", 3)
    near = ok and Clean(near)
    if near == nil then return nil end
    return near == true
end

-- Hechizo basico de cada clase de mana: si no hay mana ni para el, vamos justos
local MANA_PROBE = {
    MAGE = 116, PRIEST = 585, WARLOCK = 686, SHAMAN = 403, DRUID = 5176, PALADIN = 639, HUNTER = 3044,
}

function S.LowMana()
    local mana = Clean(UnitPower("player", Enum.PowerType.Mana))
    local maximum = Clean(UnitPowerMax("player", Enum.PowerType.Mana))
    if mana and maximum and maximum > 0 then
        return mana / maximum < 0.2
    end
    local probe = MANA_PROBE[ns.class] and S.Known(MANA_PROBE[ns.class])
    if not probe then return false end
    local _, noPower = C_Spell.IsSpellUsable(probe)
    return Clean(noPower) == true
end

-- Enemigos en combate con placa de nombre visible (unos 40 m).
-- shortcut: sin filtro de distancia fina; si el AoE salta de mas, usar /rg single
local targetsAt, targetsCount = -1, 1

function S.Targets()
    if ns.db.forceSingle then return 1 end
    local now = GetTime()
    if now == targetsAt then return targetsCount end
    local count = 0
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
        if unit and Clean(UnitCanAttack("player", unit)) and Clean(UnitAffectingCombat(unit)) then
            count = count + 1
        end
    end
    targetsAt, targetsCount = now, math.max(count, 1)
    return targetsCount
end

-- ------------------------------------------
-- Situacion: combate, enemigo, elite, mascota, grupo, arma
-- ------------------------------------------
function S.InCombat()
    return InCombatLockdown() or Clean(UnitAffectingCombat("player")) == true
end

function S.HasEnemy()
    return Clean(UnitExists("target")) and Clean(UnitCanAttack("player", "target"))
        and not Clean(UnitIsDead("target")) or false
end

local ELITE = { elite = true, rareelite = true, worldboss = true }

function S.Elite()
    if ELITE[Clean(UnitClassification("target")) or ""] then return true end
    return Clean(UnitLevel("target")) == -1  -- calavera: jefe
end

function S.HasPet()
    return Clean(UnitExists("pet")) and not Clean(UnitIsDead("pet")) or false
end

function S.InGroup()
    return IsInGroup() and true or false
end

function S.WeaponImbued()
    return Clean((GetWeaponEnchantInfo())) == true
end
