# BabyGuard - Technical Director Configuration

## Project Overview
- **Project Name**: BabyGuard Tower Defense
- **Engine**: Godot 4 GDScript (HTML5 export target)
- **Project Type**: 2D Tower Defense Game
- **Target Platform**: Web (HTML5), Desktop

## Architecture

### Directory Structure
```
tower-baby-guard/
├── design/gdd/          # Game Design Documents
├── src/
│   ├── core/            # Game state, config, constants
│   ├── entities/
│   │   ├── towers/      # Tower implementations
│   │   └── enemies/     # Enemy implementations
│   ├── systems/         # Wave manager, combat, pathfinding
│   ├── scenes/          # Scene templates
│   └── scripts/         # Utility scripts
├── assets/              # (future) Sprites, audio
└── project.godot        # Godot 4 project file
```

### Core Systems (Priority Order)
1. **game_state.gd** - Global game state (gold, lives, wave, pause)
2. **wave_manager.gd** - Spawns enemies in waves, difficulty scaling
3. **tower.gd** - Base tower class with targeting/attack logic
4. **enemy.gd** - Base enemy class with pathfinding/health

### Tower Types
| Tower | Role | Ability |
|-------|------|---------|
| MomTower | Healer | Heals nearby towers |
| DadTower | Slow | Reduces enemy speed |
| GrandmaTower | Stunner | Stuns enemies briefly |
| DoctorTower | Damage | High single-target DPS |
| ChefTower | AoE | Damages all enemies in range |

### Enemy Types
| Enemy | HP | Speed | Special |
|-------|-----|-------|---------|
| Tantrum | Low | Fast | - |
| Bedtime | Medium | Slow | Sleeps (invuln during) |
| Veggie | High | Medium | - |
| ScreenTime | Medium | Medium | - |

### Technical Constraints
- **Target**: HTML5 export via Godot 4
- **Resolution**: 1280x720 base, responsive scaling
- **Target FPS**: 60
- **State Management**: AutoLoad singletons for GameState

### Implementation Notes
- Use `@export` for configurable tower/enemy stats
- Enemies follow Path2D/PathFollow2D nodes
- Towers use Area2D for range detection
- Damage numbers via Label2D floating text
- Wave difficulty scales via wave_manager.gd multipliers
