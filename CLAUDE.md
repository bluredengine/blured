# Blured Engine Development Rules

## Core Principle
You are free to modify **Godot Engine source code** (`godot/`) and **OpenCode source code** (`opencode/`) to fully integrate these two components. Always choose the best approach for building a new AI-powered game engine.

## Architecture
- **blured Engine** = Godot Engine + OpenCode AI
- Godot provides the game engine, editor, and runtime
- OpenCode provides AI orchestration, LLM integration, and natural language processing

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
- **Full build**: `/build-blured`
- **Start engine**: `/start-blured`

### Key Paths
- Godot source: `godot/`
- OpenCode source: `opencode/`

### Terminology
- **AA** = AI Assistant (the built-in AI chat panel in the Godot editor)

### Editor Development Workflow
When debugging Godot editor changes (especially UI/AA):
1. Add `print_line()` debug statements to trace execution
2. Rebuild with `/build-blured` and restart with `/start-blured`
3. Check console output for debug messages
4. **Auto-iterate**: Repeat the kill->rebuild->restart->check cycle at least 5 times automatically until the issue is resolved
5. Don't ask user to check logs manually - automate the process
6. **Do NOT** kill, rebuild, or restart the editor unless the user explicitly asks (e.g. `/build-blured`, `/start-blured`)

### ASCII-Only in C++ String Literals
When writing or modifying C++ string literals (especially in Godot editor UI code), use **only ASCII characters**. Non-ASCII characters (em dashes, smart quotes, ellipsis, etc.) cause garbled text in the Godot UI.
- Use `-` or `--` instead of `—` (em dash) or `–` (en dash)
- Use `"` instead of `"` `"` (smart quotes)
- Use `'` instead of `'` `'` (smart apostrophes)
- Use `...` instead of `…` (ellipsis character)
- Use `*` instead of `✓` or other Unicode symbols

### File Structure
- Every script **must** start with a standardized header: `class_name`, `extends`, then a doc comment block with PURPOSE, REQUIREMENTS, DEPENDENCIES, CONFIGURATION (@exports), SIGNALS, and PUBLIC API
- Organize code into labeled `#region` / `#endregion` sections: SIGNALS, CONFIGURATION, STATE, PUBLIC API, INTERNAL
- Keep modules under **200 lines**. If larger, split into focused sub-modules
- Each file must be **self-contained** — understandable without reading other files