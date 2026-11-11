# Rotation Guide

Highlights the next spell of your rotation on your action bar, for the 9 classes and 27 talent trees of **WoW Forever**.

- Glows the spell on the Blizzard action bars and shows it in a movable icon.
- Picks the rotation from the talent tree where you spent the most points.
- Only suggests spells you know, picking your highest rank.
- Works around Forever's hidden combat data: it tracks your own DoTs, buffs and totems from your casts.

## Commands

| Command | What it does |
|---|---|
| `/rg` | Turn on / off |
| `/rg single` | Force single target (ignore AoE rules) |
| `/rg icon` · `/rg glow` | Show / hide the icon or the bar glow |
| `/rg lock` · `/rg reset` | Lock the icon (Shift + drag moves it) / move it back |
| `/rg status` | Class, rotation and enemies counted |

Healer trees (Holy, Discipline, Restoration) get a damage rotation for levelling: heals depend on group health, which is hidden in combat.

---

## 🇪🇸 Español

Resalta en tu barra de acción el siguiente hechizo de tu rotación, para las 9 clases y las 27 ramas de talentos de **WoW Forever**.

- Hace brillar el hechizo en las barras de Blizzard y lo muestra en un icono que puedes mover.
- Elige la rotación de la rama de talentos donde tienes más puntos.
- Solo propone hechizos que conoces, y siempre el rango más alto.
- Esquiva los datos de combate ocultos de Forever: lleva la cuenta de tus DoTs, buffs y tótems a partir de lo que lanzas.

Comandos: `/rg`, `/rg single`, `/rg icon`, `/rg glow`, `/rg lock`, `/rg reset`, `/rg status` (ver tabla de arriba).

Las ramas de curación (Sagrado, Disciplina, Restauración) usan una rotación de daño para subir de nivel: las curas dependen de la vida del grupo, que en combate está oculta.

## Tests

```bash
uv run --no-project --with lupa python -I Tests/run.py
```

## License

MIT
