# Flashy Hub

[![Reviewed on ScriptBlox](https://scriptblox.com/badge/Industrialist-OP-Script-Keyless-227159)](https://scriptblox.com/script/Industrialist-OP-Script-Keyless-227159)
[![Reviewed on ScriptBlox](https://scriptblox.com/badge/Industrialist-OP-AI-Helper-Bot-%28KeylessOpenSource%29-229071)](https://scriptblox.com/script/Industrialist-OP-AI-Helper-Bot-%28KeylessOpenSource%29-229071)
[![Reviewed on ScriptBlox](https://scriptblox.com/badge/Universal-Script-OP-Bring-Loose-Parts-%28Keyless-OpenSource%29-5+-Modes-230067)](https://scriptblox.com/script/Universal-Script-OP-Bring-Loose-Parts-%28Keyless-OpenSource%29-5+-Modes-230067)
[![Reviewed on ScriptBlox](https://scriptblox.com/badge/Film-Animals-1-6-Player-Not-Really-OP-Script-But-Good-Enough-Keyless-232024)](https://scriptblox.com/script/Film-Animals-1-6-Player-Not-Really-OP-Script-But-Good-Enough-Keyless-232024)

Flashy Hub is a Roblox script collection from Flashy Studios. The repository includes a game-aware loader, an Industrialist toolkit, a Safari / Film Animals script, and standalone universal utilities.

The published Industrialist toolkit is an obfuscated build. Its editable source is not included in this repository.

## Scripts

| Script | Type | Description |
|---|---|---|
| [Industrialist](https://github.com/flashyshadowstrike/Flashy-Hub/blob/main/Scripts/Industrialist.lua) | Game script | Blueprint tools, factory utilities, statistics, deletion tools, world states, mobile controls, and performance options for Industrialist. |
| [Safari / Film Animals](https://github.com/flashyshadowstrike/Flashy-Hub/blob/main/Scripts/FilmAnimals.lua) | Game script | Wildlife tracking, filming assistance, vehicle and first-person fly, free camera, free mouse, route planning, and live trip statistics. |
| [Bring Parts](https://github.com/flashyshadowstrike/Flashy-Hub/blob/main/UniversalScripts/BringParts.lua) | Universal | Controls loose physics parts with orbit, surf, tornado, targeting, filters, and configurable movement modes. |
| [Industrialist AI Assistant](https://github.com/flashyshadowstrike/Flashy-Hub/blob/main/UniversalScripts/IndustrialistAI.lua) | Universal utility | AI-assisted Industrialist questions, factory calculations, chat triggers, activity monitoring, and player statistics. |

## Quick Start

### Game-aware loader

The main loader detects the current game using `game.GameId` (the universe ID) and loads its matching script.

| Game | Universe ID | Script |
| --- | --- | --- |
| Industrialist | `3448264866` | `Scripts/Industrialist.lua` |
| Safari / Film Animals | `10766395909` | `Scripts/FilmAnimals.lua` |

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/flashyshadowstrike/Flashy-Hub/main/Loader.lua"))()
```

### Safari / Film Animals

Join the game and let it load, then run the main loader above or use this direct command:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/flashyshadowstrike/Flashy-Hub/main/Scripts/FilmAnimals.lua"))()
```

### Bring Parts

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/flashyshadowstrike/Flashy-Hub/main/UniversalScripts/BringParts.lua"))()
```

### Industrialist AI Assistant

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/flashyshadowstrike/Flashy-Hub/main/UniversalScripts/IndustrialistAI.lua"))()
```

The AI Assistant requires your own Groq API key before AI requests can work. Keep API keys private and never publish them in a script or screenshot.

## Industrialist Features

### Blueprint system

- Copy builds with desktop drag selection or mobile corner selection
- Highlight every selected building and show complete normal-mode paste previews without count caps
- Paste complete builds or one rounded quarter
- Preserve building rotation and snap placement to the stud grid
- Nudge placement with keyboard or mobile arrows relative to the character's current facing direction, snapped to the grid
- Move selected builds by pasting the destination before deleting verified originals
- Optional undo tracking for the last paste
- Name exported blueprints and inspect names when importing
- Display blueprint cost, item quantities, pipes, and wires
- Import and export compact `IND-` blueprint codes
- Save blueprint files and restore saved world states
- Expand the placement grid to match large builds

### Placement and connections

- Adjustable live placement and deletion speed
- Separate power-line and logic-wire speed
- Pipe, power cable, and logic connection restoration
- Pause and resume active pastes
- Automatic recovery for temporary placement failures
- Optional build verification
- Cached connection checks with bounded retries for unresolved links and replication grace for late models or connectors
- Optional adaptive pasting based on client FPS and server responsiveness
- Optional low-lag white deployment screen with progress, a dedicated live time-remaining estimate, pause controls, and finalizing status

### Automatic pipe routing (BETA)

- Select a machine output and destination input with clicks, taps, or the mobile crosshair picker
- Direction-aware A* routing on a two-stud grid, with Shortest, Fewer Turns, and Avoid Replacements preferences
- Shortest mode prioritizes modeled distance, includes endpoint connections, and widens its bounded search when an outside shortcut could improve the route
- Automatically combine measured 2x2, 2x4, and 2x8 item or fluid pipes along compatible straight runs, including the long models' offset pivots
- Place supported intersections and reconnect existing lines through separate channels
- Check complete placement footprints and preserve existing connections during cancellation or recovery

Same-type crossings require a wired calibration example. Unsupported crossings remain obstacles rather than being joined speculatively. Larger pipe templates must pass runtime geometry checks; incompatible sizes fall back to smaller supported pieces. Routing is still a beta feature, and automated tests do not establish live-game placement, throughput, or timing.

### Factory and world tools

- Area deletion and replacement tools
- Direction-aware building replacement
- Spawn Items sections for sandbox, limited, and other items
- Money and pollution tracking from live game values
- Expandable graphs with zoom, averages, minimums, maximums, and per-second change
- Pollution visual removal and fullbright options

### Interface and device support

- Fluent Modded interface
- Organized tabs and searchable controls
- Desktop and mobile input support
- Mobile placement toolbar and configurable interface sizing
- Hold-to-nudge arrows, lock controls, and explicit mobile selection confirmation
- Lightweight or full-model previews without normal-mode count limits
- Optional selection-highlight cleanup and manual clearing
- Reversible Potato Mode with reduced visuals and conservative request concurrency
- Anti-AFK and player utility controls

## Safari / Film Animals Features

- **Vehicle Fly** — Fly your vehicle while seated using the same movement controls as avatar flight.
- **First-Person Fly** — Move through the air with camera-relative controls.
- **Free Camera** — Explore without moving your character.
- **Free Mouse** — Unlock your cursor while keeping flight controls available.
- **Wildlife ESP** — Highlight loaded animals with names, states, mutations, and distances.
- **Auto Recording** — Record when a visible wildlife target is in frame, with film-reserve and upload checks.
- **Route Planner** — Show an eight-stop route through filtered wildlife.
- **Live Trip Stats** — Track earnings, quota, remaining time, film, inventory, and the direction back to the bus.
- **Custom Keybinds** — Choose your own shortcuts and save preferences.
- **Visual Options** — Adjust lighting, distance fog, field of view, and camera effects.

### Default controls

| Key | Action |
| --- | --- |
| K | Open or minimize the menu |
| F | Toggle fly; selects vehicle flight when seated in a detected vehicle |
| N | Toggle free camera |
| Right Alt | Free or lock the mouse |
| T | Toggle animal tracking |
| X | Select the next animal |
| P | Stop movement and filming helpers |
| WASD | Move while flying or using free camera |
| Space / E | Ascend |
| Ctrl / Q | Descend |
| Shift | Speed boost |

The script uses the same Fluent-style interface as Industrialist. Movement and filming helpers start disabled. Use the Wildlife tab to filter targets and the Filming tab to enable recording assistance. Flight and free-camera movement currently require a keyboard and mouse.

Vehicle movement depends on the game's physics and client network ownership. Wildlife tracking shows objects currently loaded on your client.

## Bring Parts Features

- Scan and control nearby loose physics parts
- Orbit, surf, tornado, sphere, line, and stack arrangements
- Target yourself or another player
- Radius and size filters
- Character, tool, accessory, and handle exclusions
- Collision and movement tuning
- Desktop and mobile interface layouts

Part control depends on Roblox network ownership and the current game's physics behavior, so results can vary between games and servers.

## Industrialist AI Assistant Features

- Ask Industrialist questions through chat triggers
- Factory production calculations and bottleneck help
- Configurable response styles and assistant personality
- Conversation history and request queue controls
- Live activity, FPS, ping, and memory monitoring
- Optional public chat responses
- Industrialist knowledge and wiki shortcuts

AI output can be incorrect. Verify important recipes, costs, and production values in the game or its current documentation.

## Requirements

- Roblox on desktop or mobile
- An environment that supports `loadstring` and HTTP requests
- Clipboard support for copy-code actions
- File APIs for blueprint files, settings, and world-state saves
- A Groq API key only when using Industrialist AI Assistant

Feature availability depends on the environment being used. Missing optional APIs should only affect the features that rely on them.

## Repository Layout

```text
Flashy-Hub/
|-- Loader.lua
|-- Scripts/
|   |-- Industrialist.lua
|   `-- FilmAnimals.lua
`-- UniversalScripts/
    |-- BringParts.lua
    `-- IndustrialistAI.lua
```

## Support and Community

Join the [Flashy Studios Discord](https://discord.gg/7SC5FDyJkn) for updates, support, previews, and community discussion.

Find verified releases and the complete script catalog on the [Flashy Studios ScriptBlox profile](https://scriptblox.com/u/FlashyStudios).

When reporting a problem, include:

- The script name
- Your device type
- The feature you were using
- The exact error message
- Whether the issue happens every time

Do not include API keys, account tokens, or other private information.

## Disclaimer

This project is not affiliated with Roblox Corporation or the developers of the supported games. Game updates can change remotes, models, interfaces, or behavior without notice. Use scripts responsibly and follow the rules that apply to the games and services you use.

## Credits

Created and maintained by Flashy Studios.

Industrialist obfuscation designer: FLAXO.

The Industrialist and Safari interfaces use [Fluent Modded](https://github.com/StyearX/Fluent-modded).
