# Contributing to Blured Engine

Blured Engine is an AI-powered game engine. Contributions are designed to be authored by **AI coding agents** (Claude Code, Cursor, etc.) working alongside human developers. This guide helps both AI agents and their operators contribute effectively.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Development Setup](#development-setup)a
- [Contribution Types](#contribution-types)
- [Community](#community)

## Architecture Overview

```
blured-engine/
  godot/              # Godot Engine source (C++, submodule)
  opencode/           # OpenCode AI server (TypeScript, submodule)
  launcher/           # Blured launcher (Rust)
  modules/            # Reusable game modules (GDScript)
  templates/          # Game project templates
  prompts/            # AI prompts and skills for game development
  .claude/skills/     # Claude Code skills for engine development
```

- **Godot** provides the game editor, renderer, and runtime
- **OpenCode** provides AI orchestration, LLM integration, and the AI server
- **GodotAI module** (`godot/modules/godot_ai/`) bridges the two -- embedding AI directly into the Godot editor
- **AA** (AI Assistant) is the built-in AI chat panel in the Godot editor

## Development Setup

### Prerequisites

- Python 3.x + SCons (for Godot builds)
- Visual Studio with C++ workload (Windows)
- Bun 1.3+ (for OpenCode)
- Rust toolchain (for launcher)
- Git with submodule support

### Clone

```bash
git clone --recurse-submodules https://github.com/bluredengine/blured.git
cd blured
```

### Build

```bash
# Build everything
build_blured.bat

# Or build components individually:

# OpenCode only
cd opencode/packages/opencode
bun install
bun run build --single

# Godot only (requires Visual Studio)
cd godot
python -m SCons platform=windows target=editor d3d12=no -j8

# Launcher only
cd launcher
cargo build --release
```

### Run

```bash
# Copy and configure environment
cp .env.example .env
# Edit .env with your project path

# Start the engine
start_blured.bat
```

The AI server runs on `http://localhost:4096` by default.

## Contribution Types

### AA Agent Tools

Tools that the AI Assistant can invoke from within the Godot editor to help users build games. These extend what the AA can do -- for example, generating scenes, analyzing screenshots, spawning enemies, or managing game state.

Tools are defined in the OpenCode server and exposed to the GodotAI module.

### AA Skills and Tasks

Predefined workflows that the AA can execute as multi-step operations. Skills live in `prompts/skills/` and define structured prompts for complex game development tasks like:

- `create-game` -- scaffold a complete game project
- `add-level` -- generate a new level for an existing game
- `analyze-screenshot` -- analyze a screenshot and suggest improvements
- `polish` -- polish and refine game feel
- `ui-layout-replicate` -- replicate a UI design in Godot
- `worldbuilding` -- build a game world's foundation

Contributors can add new skills by creating a folder in `prompts/skills/` with a `SKILL.md` file.

### Engine Development Skills

Claude Code skills for engine development workflow live in `.claude/skills/`. These automate engine-level tasks like building, starting, and managing the development process.

### Engine Features

Modifications to Godot source (`godot/`) or OpenCode source (`opencode/`) that add new AI capabilities to the editor. Please open an issue to discuss engine-level changes before starting work.

## Community

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and ideas

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
