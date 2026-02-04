# Creating Game Templates

Game templates are complete starter projects that help users quickly begin new games. They provide:
- Working gameplay out of the box
- Customization points for AI modification
- Documentation for manual customization

## Template Structure

```
templates/
└── your_template/
    ├── template.json           # Required: Template manifest
    ├── project/                # Complete Godot project
    │   ├── project.godot
    │   ├── scenes/
    │   ├── scripts/
    │   └── assets/
    ├── documentation.md        # Required: Setup guide
    └── preview.png            # Recommended: Gallery thumbnail (800x600)
```

## Creating a Template

### Step 1: Plan Your Template

Decide on:
- Game genre and core mechanics
- Target audience (beginner/intermediate/advanced)
- What customization points to expose
- Which modules to include

### Step 2: Create template.json

```json
{
  "id": "your_template",
  "name": "Your Template Name",
  "version": "1.0",
  "description": "Brief description of the game type",

  "keywords": ["genre", "type", "style"],

  "modules_included": [
    "game_manager",
    "player_movement",
    "spawn_system"
  ],

  "customization_points": {
    "theme": {
      "options": ["default", "alternative"],
      "affects": ["assets", "colors"],
      "default": "default"
    },
    "difficulty": {
      "parameters": {
        "player_health": {"default": 100, "min": 50, "max": 200},
        "enemy_speed": {"default": 50, "min": 25, "max": 100}
      }
    },
    "mechanics": {
      "double_jump": true,
      "wall_slide": false
    }
  },

  "scenes": {
    "main": "res://scenes/main.tscn",
    "game": "res://scenes/game.tscn",
    "menu": "res://scenes/ui/menu.tscn"
  },

  "ai_hints": {
    "common_requests": [
      "Add new enemy type",
      "Add power-up items",
      "Change player abilities"
    ],
    "complexity_estimate": "beginner",
    "key_systems": ["PlayerController", "LevelManager"]
  }
}
```

### Step 3: Create the Godot Project

Create a fully playable game in `project/`:

```
project/
├── project.godot
├── scenes/
│   ├── main.tscn              # Entry point
│   ├── game.tscn              # Main gameplay
│   ├── player/
│   │   └── player.tscn
│   ├── enemies/
│   │   └── enemy.tscn
│   └── ui/
│       ├── hud.tscn
│       └── menu.tscn
├── scripts/
│   ├── player/
│   │   └── player.gd
│   ├── enemies/
│   │   └── enemy.gd
│   └── systems/
│       └── game_manager.gd
└── assets/
    ├── sprites/
    ├── audio/
    └── fonts/
```

### Step 4: Use Modules

Import and use modules from the module library:

```gdscript
# In player.gd
extends CharacterBody2D

# Add module as child node or use composition
@onready var movement = $PlayerMovement  # Module instance
@onready var stats = $PlayerStats        # Module instance

func _ready() -> void:
    movement.speed = 300
    stats.max_health = 100
```

### Step 5: Write Documentation

Create `documentation.md`:

```markdown
# Your Template Name

Brief description of what this template provides.

## Quick Start

1. Open in Godot 4.x
2. Run main scene
3. Use arrow keys to move, space to jump

## Project Structure

Explain the file organization.

## Core Systems

Document the main systems and how they work.

## Customization

### Easy Changes (Inspector)
- Player speed: Select Player node, change Speed
- Enemy health: Select Enemy prefab, change Max Health

### Code Changes
- Add new enemy: Duplicate enemy.gd, modify behavior
- Add power-ups: Create new script extending PowerupBase

## AI Prompts

Suggested prompts for AI modification:
- "Add a double jump ability"
- "Create a new enemy that flies"
- "Add a health pickup item"
```

### Step 6: Create Preview Image

- Size: 800x600 pixels
- Format: PNG
- Show actual gameplay
- Include UI elements

## Best Practices

### 1. Make It Playable

The template should be a complete, working game:
- Has win/lose conditions
- Includes at least one level
- UI is functional (menus, HUD)
- Sounds and basic visuals included

### 2. Use Placeholder Assets

Include simple but functional assets:
- Colored rectangles for sprites (easily replaceable)
- Basic sound effects
- Clear, readable fonts

```gdscript
# Create placeholder sprite in code
var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
image.fill(Color.BLUE)
var texture = ImageTexture.create_from_image(image)
```

### 3. Clear Customization Points

Make it obvious what can be changed:
- Use @export for tweakable values
- Group related settings
- Add tooltips

```gdscript
@export_group("Movement")
@export var speed: float = 200.0 ## Player movement speed
@export var jump_force: float = 400.0 ## Initial jump velocity

@export_group("Combat")
@export var damage: int = 10 ## Damage dealt per hit
```

### 4. Modular Design

Use the module system:
- Import existing modules when possible
- Create template-specific modules for unique features
- Keep scripts focused and single-purpose

### 5. AI-Friendly Code

Write code that AI can easily understand and modify:
- Clear variable names
- Comments explaining "why" not "what"
- Avoid complex patterns
- Keep functions short

## Submission Checklist

- [ ] `template.json` manifest complete
- [ ] Fully playable game
- [ ] `documentation.md` with setup guide
- [ ] Preview image (800x600 PNG)
- [ ] Uses modules where appropriate
- [ ] Clear customization points
- [ ] All assets included (no external dependencies)
- [ ] Works with Godot 4.x
- [ ] MIT licensed

## Complexity Levels

### Beginner
- Simple mechanics (move, jump, collect)
- 1-2 core systems
- Minimal code to understand
- Examples: Platformer, Endless Runner

### Intermediate
- Multiple interacting systems
- Enemy AI, inventory, etc.
- Requires some coding knowledge
- Examples: Tower Defense, Top-down Shooter

### Advanced
- Complex systems (RPG stats, quest systems)
- Multiple scenes and progression
- Significant codebase
- Examples: RPG, Strategy Game

## Example Templates

Study existing templates:
- `platformer_2d/` - Simple platformer (beginner)
- `tower_defense/` - Strategic TD (intermediate)
