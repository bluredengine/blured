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

### Editor Development Workflow
When debugging Godot editor changes (especially UI/AI Assistant):
1. Add `print_line()` debug statements to trace execution
2. Kill Godot, rebuild, and restart with console: `godot.windows.editor.x86_64.console.exe`
3. Check console output for debug messages
4. **Auto-iterate**: Repeat the kill→rebuild→restart→check cycle at least 5 times automatically until the issue is resolved
5. Don't ask user to check logs manually - automate the process

## Game Development Rules
- All game events must be logged using `GameLogger` for LLM verification
- See `docs/game-development-rule.md` for detailed logging requirements
