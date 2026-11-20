<p align="center"><a href="https://www.curseforge.com/wow/addons/rotation-guide"><img src="https://raw.githubusercontent.com/Pirson-s-Addons/.github/main/profile/assets/readme-rg-en.svg" width="100%" alt="Rotation Guide"/></a></p>

<p align="center"><b>English</b> · <a href="README.es.md">Español</a></p>

<p align="center">
<a href="https://www.curseforge.com/wow/addons/rotation-guide"><b>CurseForge</b></a> ·
<a href="https://github.com/Pirson-s-Addons/RotationGuide/releases/latest"><b>Download</b></a>
</p>

> [!TIP]
> **Quick start:** just play. The next spell of your rotation glows on your action bar. Type `/rg` to open its options.

## What it does

Highlights the next spell of your rotation on your action bar, for the 9 classes and 27 talent trees of **WoW Forever**.

## Screenshots

<p align="center">
<img src="https://raw.githubusercontent.com/Pirson-s-Addons/.github/main/profile/assets/cf/shots/rg-combat.png" width="640" alt="Your next spell glows on your bar and in its icon"><br>
<sub>Your next spell glows on your bar and in its icon</sub>
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/Pirson-s-Addons/.github/main/profile/assets/cf/shots/rg-aura.png" width="640" alt="Ready before the pull: your aura"><br>
<sub>Ready before the pull: your aura</sub>
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/Pirson-s-Addons/.github/main/profile/assets/cf/shots/rg-blessing.png" width="640" alt="Buffs and blessings before the fight"><br>
<sub>Buffs and blessings before the fight</sub>
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/Pirson-s-Addons/.github/main/profile/assets/cf/shots/rg-editor.png" width="640" alt="Make your own rotation and share it"><br>
<sub>Make your own rotation and share it</sub>
</p>

<p align="center">
<img src="https://raw.githubusercontent.com/Pirson-s-Addons/.github/main/profile/assets/cf/shots/rg-options.png" width="640" alt="Options and heal warning"><br>
<sub>Options and heal warning</sub>
</p>

## Features

- Glows the spell on the Blizzard action bars (stance bar included: paladin auras, warrior stances, druid forms, stealth) and shows it in a movable icon.
- Picks the rotation from the talent tree where you spent the most points.
- **Your own rotation**: in *Options > AddOns > Rotation Guide > My rotation* (or `/rg editor`) create per-tree profiles with the spells in your spellbook, order them and choose when each one is used. **Export** gives you a code to share; **Import** saves a friend's code as a new profile without touching yours, and you can switch profiles any time.
- Only suggests spells you know, picking your highest rank.
- Works around Forever's hidden combat data: it tracks your own DoTs, buffs and totems from your casts.
- **Heal warning**: when your health drops below a threshold (40 % by default), your self-heal or defensive (Flash Heal, Evasion, Shield Wall...) covers the icon and glows red on your bar. Health is hidden from addons in Forever, so the game itself decides when it shows: the addon never reads your health.
- **Adapts to the situation**: long buffs, weapon imbues and your pet before the pull; big cooldowns saved for elites and bosses; tank trees play their damage tree when solo; AoE, melee/ranged, stealth and shapeshift aware.

## Commands

| Command | What it does |
|---|---|
| `/rg` | Opens the options |
| `/rg toggle` | Turn on / off |
| `/rg single` | Force single target (ignore AoE rules) |
| `/rg icon` · `/rg glow` | Show / hide the icon or the bar glow |
| `/rg lock` · `/rg reset` | Lock the icon (Shift + drag moves it) / move it back |
| `/rg heal 40` | Heal warning threshold in % (`/rg heal 0` turns it off) |
| `/rg status` | Class, rotation, points per tree and enemies counted |
| `/rg editor` | Opens the rotation and profile editor |

## Installation

1. Get it from [CurseForge](https://www.curseforge.com/wow/addons/rotation-guide) or download the zip from the [latest release](https://github.com/Pirson-s-Addons/RotationGuide/releases/latest).
2. Extract the `RotationGuide` folder into the `Interface/AddOns/` folder of your WoW Forever installation.
3. Restart WoW and enable the addon.

## Notes

Healer trees (Holy, Discipline, Restoration) get a damage rotation for levelling: heals depend on group health, which is hidden in combat.

## For addon authors

<details>
<summary><b>Public API</b></summary>

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
</details>

<details>
<summary><b>Tests</b></summary>

```bash
uv run --no-project --with lupa python -I Tests/run.py
```
</details>

<br/>

<p align="center"><a href="https://github.com/Pirson-s-Addons"><img src="https://raw.githubusercontent.com/Pirson-s-Addons/.github/main/profile/assets/readme-footer-en.svg" width="100%" alt="Part of Pirson's Addons. See all addons."/></a></p>
