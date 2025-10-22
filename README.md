# Fizzlebee's Treasure Tracker

Track mob kills and loot drops with intelligent drop rate calculation for World of Warcraft.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![WoW](https://img.shields.io/badge/WoW-11.0.5-orange)
![License](https://img.shields.io/badge/license-BSD--3--Clause-green)

## Features

- **Kill Tracking** - Session and lifetime kill counts per mob
- **Loot Tracking** - Drop rates calculated as ratio (1:X format)
- **Gold Tracking** - Session and total gold earned
- **DPS Calculation** - Real-time damage per second tracking
- **Quality Statistics** - Count items by rarity (Green, Blue, Purple, Orange)
- **Performance Metrics** - Kills per second and kills per hour
- **Item Highlighting** - Mark specific items to track across all mobs
- **Zone Filtering** - Show only mobs from current zone
- **Auto-Collapse** - Inactive mobs (>5 minutes) automatically collapse
- **Multi-Language** - Supports 10 languages (EN, DE, FR, ES, RU, CN, TW, KR, PT, IT)

## Installation

1. Download the latest release from [GitHub Releases](https://github.com/Fizzlebees-Rocket-Shop/FizzlebeesTreasureTracker/releases)
2. Extract the ZIP file
3. Move the `FizzlebeesTreasureTracker` folder to:
   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ```
   **Example path:**
   ```
   C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\FizzlebeesTreasureTracker
   ```
4. Restart World of Warcraft
5. Enable the addon in the AddOns menu

## Usage

```
/ftt              Toggle tracker window
/ftt help         Show available commands
/ftt debug        Display debug information
/ftt refresh      Refresh the display
```

**Settings:** Click the gear icon in the tracker window to customise appearance and behaviour.

## Requirements

- World of Warcraft: The War Within (11.0.5+)
- No dependencies required

## Configuration

**Customisation options:**
- Transparent mode with adjustable opacity
- Font scaling (Small, Medium, Large)
- Auto-sizing or manual window resize
- Position locking
- Quality filtering (All, Green+, Blue+, Purple+)
- Debug mode for troubleshooting

## Public API

FTT provides a public API for other addons to integrate with font scaling and settings.

See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for details.

## License

BSD 3-Clause License - See [LICENSE](LICENSE) for details.

## Documentation

- **[PATCHNOTES.txt](PATCHNOTES.txt)** - Version history and changelog
- **[.claude/CLAUDE.md](.claude/CLAUDE.md)** - Comprehensive developer documentation (German)
- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** - Public API reference

## Author

**Fizzlebee (Vivian Voss)**
Boulder Dash Heroes - EU Servers

## Contributing

This is a personal project, but bug reports and suggestions are welcome via GitHub Issues.

## Repository

**GitHub:** [Fizzlebees-Rocket-Shop/FizzlebeesTreasureTracker](https://github.com/Fizzlebees-Rocket-Shop/FizzlebeesTreasureTracker)

---

*Goblin-engineered precision tracking. No explosions guaranteed.*
