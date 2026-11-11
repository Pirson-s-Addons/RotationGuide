local ADDON_NAME, ns = ...

-- ==========================================
-- IDIOMA POR DEFECTO (enUS / enGB)
-- ==========================================
-- Define TODAS las claves; los demas idiomas sobrescriben las suyas.

local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

L.ON = "on."
L.OFF = "off."
L.SINGLE_ON = "single target forced: AoE rules ignored."
L.SINGLE_OFF = "counting enemies again for AoE."
L.ICON_ON = "icon shown."
L.ICON_OFF = "icon hidden."
L.GLOW_ON = "action bar glow on."
L.GLOW_OFF = "action bar glow off."
L.LOCKED = "icon locked."
L.UNLOCKED = "icon unlocked: Shift + drag to move it."
L.RESET = "icon back to its default position."
L.HEAL_AT = "heal warning below %d%% health."
L.HEAL_OFF = "heal warning off."
L.NO_ROTATION = "no rotation"
L.STATUS = "class %s, rotation %s, enemies counted: %d."
L.HELP = "/rg (on/off), /rg single, /rg icon, /rg glow, /rg lock, /rg reset, /rg heal <%>, /rg status"
