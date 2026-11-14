# Rotation Guide

Highlights the next spell of your rotation on your action bar, for the 9 classes and 27 talent trees of **WoW Forever**.

- Glows the spell on the Blizzard action bars (stance bar included: paladin auras, warrior stances, druid forms, stealth) and shows it in a movable icon.
- Picks the rotation from the talent tree where you spent the most points.
- Only suggests spells you know, picking your highest rank.
- Works around Forever's hidden combat data: it tracks your own DoTs, buffs and totems from your casts.
- **Heal warning**: when your health drops below a threshold (40 % by default), your self-heal or defensive (Flash Heal, Evasion, Shield Wall...) covers the icon and glows red on your bar. Health is hidden from addons in Forever, so the game itself decides when it shows: the addon never reads your health.
- **Adapts to the situation**: long buffs, weapon imbues and your pet before the pull; big cooldowns saved for elites and bosses; tank trees play their damage tree when solo; AoE, melee/ranged, stealth and shapeshift aware.

## Commands

| Command | What it does |
|---|---|
| `/rg` | Turn on / off |
| `/rg single` | Force single target (ignore AoE rules) |
| `/rg icon` · `/rg glow` | Show / hide the icon or the bar glow |
| `/rg lock` · `/rg reset` | Lock the icon (Shift + drag moves it) / move it back |
| `/rg heal 40` | Heal warning threshold in % (`/rg heal 0` turns it off) |
| `/rg status` | Class, rotation and enemies counted |

Healer trees (Holy, Discipline, Restoration) get a damage rotation for levelling: heals depend on group health, which is hidden in combat.

---

## 🇪🇸 Español

Resalta en tu barra de acción el siguiente hechizo de tu rotación, para las 9 clases y las 27 ramas de talentos de **WoW Forever**.

- Hace brillar el hechizo en las barras de Blizzard (también la de posturas: auras de paladín, posturas de guerrero, formas de druida, sigilo) y lo muestra en un icono que puedes mover.
- Elige la rotación de la rama de talentos donde tienes más puntos.
- Solo propone hechizos que conoces, y siempre el rango más alto.
- Esquiva los datos de combate ocultos de Forever: lleva la cuenta de tus DoTs, buffs y tótems a partir de lo que lanzas.
- **Aviso de cura**: cuando tu vida baja de un umbral (40 % por defecto), tu cura o defensivo propio (Destello de luz, Evasión, Muro de escudo...) tapa el icono y brilla en rojo en tu barra. En Forever la vida está oculta para los addons, así que es el propio juego el que decide cuándo se ve: el addon nunca lee tu vida.
- **Se adapta a la situación**: buffs largos, encantamientos de arma y mascota antes de pelear; cooldowns grandes guardados para élites y jefes; las ramas de tanque usan la de daño cuando vas solo; tiene en cuenta área, melee/distancia, sigilo y formas.

Comandos: `/rg`, `/rg single`, `/rg icon`, `/rg glow`, `/rg lock`, `/rg reset`, `/rg heal 40`, `/rg status` (ver tabla de arriba).

Las ramas de curación (Sagrado, Disciplina, Restauración) usan una rotación de daño para subir de nivel: las curas dependen de la vida del grupo, que en combate está oculta.

## API for other addons

Read-only, versioned and always returns copies. Add `## OptionalDeps: RotationGuide` to your TOC.

```lua
local api = RotationGuideAPI
if api and api.version == 1 then
    api.GetClasses()              -- { "DRUID", "HUNTER", ... }
    api.GetSpecs("PALADIN")       -- { { index = 1, name = "Holy" }, ... }
    api.GetRotation("PALADIN", 3) -- { { spellID, name, conditions = { missing = {...}, aoe = 2, ... } }, ... }
    api.GetHeals("PALADIN")       -- heals/defensives used when health drops
    api.GetPlayerSpec()           -- class, specIndex, specName
    api.GetNext()                 -- spellID now highlighted, heal spellID, heal threshold %
end
```

`conditions` uses the rule fields documented at the top of `Core/Engine.lua`.

## Tests

```bash
uv run --no-project --with lupa python -I Tests/run.py
```

## License

MIT
