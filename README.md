# Flashy Hub

Flashy Hub is a Roblox script collection from Flashy Studios. The repository includes a game-aware loader, a full Industrialist toolkit, and standalone universal utilities.

## Scripts

| Script | Type | Description |
|---|---|---|
| [Industrialist](https://github.com/flashyshadowstrike/Flashy-Hub/blob/main/Scripts/Industrialist.lua) | Game script | Blueprint tools, factory utilities, statistics, deletion tools, world states, mobile controls, and performance options for Industrialist. |
| [Bring Parts](https://github.com/flashyshadowstrike/Flashy-Hub/blob/main/UniversalScripts/BringParts.lua) | Universal | Controls loose physics parts with orbit, surf, tornado, targeting, filters, and configurable movement modes. |
| [Industrialist AI Assistant](https://github.com/flashyshadowstrike/Flashy-Hub/blob/main/UniversalScripts/IndustrialistAI.lua) | Universal utility | AI-assisted Industrialist questions, factory calculations, chat triggers, activity monitoring, and player statistics. |

## Quick Start

### Game-aware loader

The main loader detects the current supported game and loads its matching script. Industrialist is currently mapped to place ID `9312740628`.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/flashyshadowstrike/Flashy-Hub/main/Loader.lua"))()
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

- Copy builds with drag selection
- Paste complete builds or one rounded quarter
- Preserve building rotation and snap placement to the stud grid
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
- Optional adaptive pasting based on client FPS and server responsiveness
- Optional low-lag white deployment screen with progress and estimated time remaining

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
- Lightweight previews with adjustable detail
- Selection highlight limits and automatic cleanup
- Anti-AFK and player utility controls

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
|   `-- Industrialist.lua
`-- UniversalScripts/
    |-- BringParts.lua
    `-- IndustrialistAI.lua
```

## Support and Community

Join the [Flashy Studios Discord](https://discord.gg/7SC5FDyJkn) for updates, support, previews, and community discussion.

When reporting a problem, include:

- The script name
- Your device type
- The feature you were using
- The exact error message
- Whether the issue happens every time

Do not include API keys, account tokens, or other private information.

## Disclaimer

This project is not affiliated with Roblox Corporation or the developers of Industrialist. Game updates can change remotes, models, interfaces, or behavior without notice. Use scripts responsibly and follow the rules that apply to the games and services you use.

## Credits

Created and maintained by Flashy Studios.

The Industrialist interface uses [Fluent Modded](https://github.com/StyearX/Fluent-modded).

