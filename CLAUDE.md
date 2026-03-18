# Makabaka Engine Development Rules

## Core Principle
You are free to modify **Godot Engine source code** (`godot/`) and **OpenCode source code** (`opencode/`) to fully integrate these two components. Always choose the best approach for building a new AI-powered game engine.

## Architecture
- **Makabaka Engine** = Godot Engine + OpenCode AI
- Godot provides the game engine, editor, and runtime
- OpenCode provides AI orchestration, LLM integration, and natural language processing
- The native `godot_ai` module (`godot/modules/godot_ai/`) integrates AI directly into the editor

## Guidelines

### When to Modify Engine Source
- Add native support for AI features directly in Godot when it improves performance or UX
- Modify OpenCode to add Godot-specific tools, routes, or behaviors
- Create deep integrations that wouldn't be possible with plugins alone

### When to Use Plugins/Extensions
- For features that don't require engine-level access
- For rapid prototyping before committing to engine changes
- For optional features that users may want to disable

### Build Commands
- **Godot**: `python -m SCons platform=windows target=editor d3d12=no -j8` (from `godot/`)
- **OpenCode**: `bun run build --single` (from `opencode/packages/opencode/`)

### Key Paths
- Godot source: `g:/makabaka-engine/godot/`
- OpenCode source: `g:/makabaka-engine/opencode/`
- GodotAI module: `g:/makabaka-engine/godot/modules/godot_ai/`
- Game templates: `g:/makabaka-engine/templates/`
- Game modules: `g:/makabaka-engine/modules/`

### Testing
- Test project: `G:/MakabakaGames/Test`
- AI server: `http://localhost:4096`
- Start command: `start_makabaka.bat`

### Terminology
- **AA** = AI Assistant (the built-in AI chat panel in the Godot editor)

### Editor Development Workflow
When debugging Godot editor changes (especially UI/AA):
1. Add `print_line()` debug statements to trace execution
2. Rebuild with `/build-makabaka` and restart with `/start-makabaka`
3. Check console output for debug messages
4. **Auto-iterate**: Repeat the kill->rebuild->restart->check cycle at least 5 times automatically until the issue is resolved
5. Don't ask user to check logs manually - automate the process
6. **Do NOT** kill, rebuild, or restart the editor unless the user explicitly asks (e.g. `/build-makabaka`, `/start-makabaka`)

### ASCII-Only in C++ String Literals
When writing or modifying C++ string literals (especially in Godot editor UI code), use **only ASCII characters**. Non-ASCII characters (em dashes, smart quotes, ellipsis, etc.) cause garbled text in the Godot UI.
- Use `-` or `--` instead of `—` (em dash) or `–` (en dash)
- Use `"` instead of `"` `"` (smart quotes)
- Use `'` instead of `'` `'` (smart apostrophes)
- Use `...` instead of `…` (ellipsis character)
- Use `*` instead of `✓` or other Unicode symbols

## Game Development Rules
- AI-powered asset generation: See `prompts/game-development-rule.md`
- Event logging: All game events must be logged using `GameLogger` for LLM verification
- See `prompts/game-development-rule.md` for detailed requirements

## UGC Game Code Generation Standards

When generating GDScript game code (templates, modules, or any user-requested game features), follow these standards from `docs/context-optimization-guide.md`:

### File Structure
- Every script **must** start with a standardized header: `class_name`, `extends`, then a doc comment block with PURPOSE, REQUIREMENTS, DEPENDENCIES, CONFIGURATION (@exports), SIGNALS, and PUBLIC API
- Organize code into labeled `#region` / `#endregion` sections: SIGNALS, CONFIGURATION, STATE, PUBLIC API, INTERNAL
- Keep modules under **200 lines**. If larger, split into focused sub-modules
- Each file must be **self-contained** — understandable without reading other files

### Type Safety
- All function parameters and return types **must** have type hints
- All variables **must** be typed: `var health: int = 100`, `var velocity: Vector2 = Vector2.ZERO`
- Use typed arrays: `Array[Node2D]`, `Array[Vector2]`

### Naming Conventions
- Signals: past tense or noun (`enemy_died`, `health_changed`)
- Methods: verb phrase (`spawn_enemy`, `take_damage`)
- Booleans: `is_`/`has_`/`can_` prefix (`is_alive`, `has_weapon`, `can_move`)
- Private members: underscore prefix (`_internal_timer`, `_calculate_path`)
- Constants: `UPPER_SNAKE_CASE` (`MAX_ENEMIES`, `DEFAULT_SPEED`)

### Architecture
- Use **composition over inheritance** — attach behavior modules as child nodes
- **Explicit dependencies** — inject via `setup()` method, never use hidden globals
- **Configuration as data** — use JSON files in `data/` for balance values, enemy stats, wave configs
- Create `interface.json` for each reusable module documenting inputs, outputs, signals, methods

### Module Interface Files
For each reusable module, create an `interface.json`:
```json
{
  "module_id": "module_name",
  "description": "What it does",
  "inputs": {},
  "outputs": {},
  "signals": [],
  "methods": [],
  "dependencies": []
}
```

### Anti-Patterns to Avoid
- No god classes (one class doing everything)
- No deep inheritance chains (max 1 level)
- No scattered/duplicated constants
- No implicit state via global event buses
