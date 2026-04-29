# BabyGuard - Game Design Document

## Concept & Vision

**BabyGuard** is a family-themed tower defense game where parents and caregivers defend their home against childhood mishaps personified as mischievous enemies. The game blends strategic tower placement with charming, relatable parenting scenarios. The tone is warm, humorous, and lighthearted—every "enemy" is a playful representation of everyday toddler challenges.

The game feels like a cozy Saturday morning cartoon meets satisfying strategic gameplay. Visual style is soft and inviting with pastel colors and rounded shapes.

---

## Gameplay Overview

### Core Loop
1. Enemies spawn and follow a path toward the baby's room
2. Player places towers along the path to stop enemies
3. Towers attack enemies within range using unique abilities
4. Player earns gold for defeated enemies
5. Waves increase in difficulty until player loses all lives or clears all waves

### Win/Lose Conditions
- **Win**: Survive all waves (10 waves per level)
- **Lose**: Lives reach 0 (enemies reach the baby's room)

---

## Towers

### 1. Mom Tower (Healer)
- **Cost**: 100 gold
- **Range**: Medium (150px)
- **Ability**: Heals all towers in range for 5 HP/second
- **Visual**: Heart icon, pink/aqua color scheme
- **Upgrade**: Increases heal amount

### 2. Dad Tower (Slow)
- **Cost**: 75 gold
- **Range**: Large (200px)
- **Ability**: Slows all enemies in range by 40%
- **Visual**: Football icon, blue/brown color scheme
- **Upgrade**: Increases slow percentage

### 3. Grandma Tower (Stunner)
- **Cost**: 125 gold
- **Range**: Medium (125px)
- **Ability**: Stuns one random enemy in range for 1.5 seconds
- **Cooldown**: 5 seconds
- **Visual**: knitting needles icon, purple/gray color scheme
- **Upgrade**: Reduces cooldown, increases stun duration

### 4. Doctor Tower (Damage)
- **Cost**: 150 gold
- **Range**: Long (250px)
- **Ability**: High damage single target (25 DPS)
- **Visual**: syringe icon, white/red color scheme
- **Upgrade**: Increases damage, attack speed

### 5. Chef Tower (AoE)
- **Cost**: 175 gold
- **Range**: Medium (150px)
- **Ability**: Damages ALL enemies in range for 10 damage/second
- **Visual**: pot icon, orange/yellow color scheme
- **Upgrade**: Increases AoE damage

---

## Enemies

### 1. Tantrum
- **HP**: 50
- **Speed**: Fast (120px/sec)
- **Reward**: 10 gold
- **Visual**: Red-faced child icon
- **Special**: None (basic enemy)

### 2. Bedtime
- **HP**: 100
- **Speed**: Slow (60px/sec)
- **Reward**: 20 gold
- **Visual**: Moon/sleepy icon
- **Special**: Periodically falls asleep for 3 seconds (invulnerable while sleeping)

### 3. Veggie
- **HP**: 200
- **Speed**: Medium (80px/sec)
- **Reward**: 30 gold
- **Visual**: Broccoli icon
- **Special**: High HP tank

### 4. Screen Time
- **HP**: 75
- **Speed**: Medium (90px/sec)
- **Reward**: 25 gold
- **Visual**: Tablet/phone icon
- **Special**: Immune to slow effects

---

## Wave System

### Wave Structure
- 10 waves per level
- Each wave has a fixed composition of enemies
- 10-second break between waves for tower placement
- Boss wave (wave 10) has 2x enemy HP

### Difficulty Scaling
- Wave 1-3: Tutorial difficulty, mostly Tantrums
- Wave 4-6: Introduce Bedtime and Veggie
- Wave 7-9: Mixed enemy types, increased count
- Wave 10: Final boss wave, all enemy types + buffed HP

---

## Economy

### Starting Resources
- **Gold**: 200
- **Lives**: 20

### Income
- Enemy kill rewards (varies by enemy type)
- No passive income

---

## Visual Style

### Color Palette
- **Primary**: Soft pastel pink (#FFB5BA)
- **Secondary**: Baby blue (#A8D8EA)
- **Accent**: Sunny yellow (#FFEAA7)
- **Background**: Cream white (#FFF9E6)
- **UI Text**: Dark brown (#5D4E37)

### Art Direction
- Rounded, soft shapes
- Cute character icons (not realistic)
- Clear visual feedback for abilities
- Floating damage numbers
- Smooth animations (60 FPS target)

---

## Audio (Future)
- BGM: Light, playful melody
- SFX: Pop for placement, whoosh for attacks, cha-ching for gold

---

## UI Elements

### HUD
- Top bar: Gold, Lives, Wave number
- Bottom panel: Tower selection bar
- Right side: Start wave button, pause button

### Tower Placement
- Click tower in panel to select
- Valid placement areas highlighted green
- Invalid areas highlighted red
- Click to place, right-click to cancel

---

## Scenes

### Main Scenes
1. **MainMenu** - Title, Play, Settings buttons
2. **GameScene** - Main gameplay
3. **GameOver** - Lose screen with retry
4. **Victory** - Win screen with next level

---

## Technical Specs
- **Engine**: Godot 4
- **Language**: GDScript
- **Export**: HTML5 (web), Windows, macOS
- **Resolution**: 1280x720 base, responsive
- **Target**: 60 FPS
