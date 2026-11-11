local ADDON_NAME, ns = ...

-- ==========================================
-- ESPAÑOL (esES / esMX)
-- ==========================================
local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end
local L = ns.L

L.ON = "activado."
L.OFF = "desactivado."
L.SINGLE_ON = "un solo objetivo forzado: se ignoran las reglas de área."
L.SINGLE_OFF = "vuelvo a contar enemigos para el área."
L.ICON_ON = "icono visible."
L.ICON_OFF = "icono oculto."
L.GLOW_ON = "brillo en la barra activado."
L.GLOW_OFF = "brillo en la barra desactivado."
L.LOCKED = "icono bloqueado."
L.UNLOCKED = "icono desbloqueado: Mayús + arrastrar para moverlo."
L.RESET = "icono de vuelta a su sitio."
L.HEAL_AT = "aviso de cura por debajo del %d%% de vida."
L.HEAL_OFF = "aviso de cura desactivado."
L.NO_ROTATION = "sin rotación"
L.STATUS = "clase %s, rotación %s, enemigos contados: %d."
L.HELP = "/rg (activar/desactivar), /rg single, /rg icon, /rg glow, /rg lock, /rg reset, /rg heal <%>, /rg status"
