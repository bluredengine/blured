# Blured Engine

An AI-powered game engine built on [Godot 4.x](https://godotengine.org/) and [OpenCode](https://github.com/opencode-ai/opencode). Create games using natural language — from asset generation to gameplay scripting.

## Why Blured Engine?

Making a game today requires programming, art, UI design, animation, and fluency with complex editor tools. Most people have great game ideas but lack one or more of these skills, so their ideas never become reality.

Blured Engine aims to change that. By embedding AI directly into every part of the game development workflow, we want to make it possible for **anyone** to create indie games — whether you can code or not, whether you can draw or not, whether you've ever used a game editor or not. Just describe what you want, and the engine helps you build it.

## AI Agents

Blured Engine uses specialized AI agents that understand different aspects of game development:

| Agent | Status | Description |
|-------|--------|-------------|
| **Game Dev Agent** | Available | Writes and modifies gameplay scripts, fixes bugs, answers questions about your project |
| **QA Agent** | Available | Captures screenshots, analyzes game visuals, diagnoses runtime errors automatically |
| **UI Agent** | Available | Designs and builds user interfaces from natural language descriptions |
| **Animation Agent** | Planned | Will create and edit animations from descriptions |
| **Level Design Agent** | Planned | Will build and arrange game scenes and environments |
| **3D Agent** | Planned | Will generate and refine 3D models, materials, and lighting |

All agents work inside the editor through the **AI Assistant** panel — no external tools or command lines needed.

## Architecture

```
Godot Editor (C++) <--HTTP--> OpenCode AI Server (Bun/TypeScript) <--> Cloud AI APIs
       |                            |
  Game runtime              LLM orchestration
  Editor UI                 Tool execution
  AI Assistant dock         Asset pipeline
```

**Blured Engine** = Modified Godot Engine + OpenCode AI Server

- **Godot** provides the game engine, editor, and runtime
- **OpenCode** provides AI orchestration, LLM integration, and natural language processing
- The native `godot_ai` module integrates AI directly into the editor

## Features

- **AI Assistant** — Chat interface embedded in the editor with multi-instance support, streaming responses, and tool execution
- **AI Asset Generation** — Generate textures, sprites, 3D models, audio, and more via cloud AI (Replicate, Meshy, Suno)
- **Art Director** — Visual style exploration, style locking, and batch asset production with style consistency
- **Background Removal** — Automatic background removal in the asset pipeline (see [configuration](#background-removal))
- **Debugger Integration** — Runtime errors are automatically forwarded to the AI for diagnosis
- **Screenshot Analysis** — Capture game screenshots for AI-powered visual QA

See [docs/Blured-engine.md](docs/Blured-engine.md) for the full feature reference.

## Installation

### Prerequisites

- **Windows 10/11** (64-bit)

### Quick Start

1. Download the latest release from [Releases](https://github.com/bluredengine/blured/releases)
2. Extract to a folder (e.g. `C:\BluredEngine\`)
3. Run `blured.exe`
4. Open the **AI Assistant** panel (right side) and configure your LLM API key via the Setup Wizard

The engine ships with all local AI providers (image processing, GIF recording, atlas splitting) pre-installed. No extra setup needed.

### Optional: RMBG-2.0 (Local Background Removal)

RMBG-2.0 is a free, local background removal service using [BRIA RMBG-2.0](https://huggingface.co/briaai/RMBG-2.0). It requires extra setup because it depends on Python and PyTorch.

**Requirements:**
- **Python 3.10+** installed and on PATH
- ~2GB disk space (model weights downloaded on first run)
- GPU optional but recommended (CUDA-compatible NVIDIA GPU)

**Setup:**
```bash
cd services/rmbg
pip install -r requirements.txt
python main.py
```

If you don't want to set up RMBG locally, you can configure an **online provider** instead (e.g. Replicate) in the Setup Wizard to get background removal capability without any local Python/ML setup.

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `BLURED_RMBG_PORT` | `7860` | Port for the RMBG service |

> **License note:** The RMBG-2.0 model is licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/). Commercial use requires a separate agreement with [BRIA](https://bria.ai/).

## Configuration

All providers are configured through the **Setup Wizard** in the AI Assistant panel.

### Recommended Provider Setup

| Provider | Purpose | Auth |
|----------|---------|------|
| **Anthropic** | Chat / coding assistant (Claude) | OAuth token |
| **Replicate** | Image generation, background removal | API token |

Anthropic supports OAuth login -- no API key needed. Replicate handles both image generation and background removal, since no existing AI model generates good transparent images directly.

### Additional Providers (Optional)

| Provider | Purpose | Auth |
|----------|---------|------|
| **Meshy** | 3D models with PBR textures | API key |
| **Suno** | Music, SFX, voice | API key |
| **Google** | Chat (Gemini) | API key |

### Background Removal

The asset pipeline automatically removes backgrounds from generated sprites and textures. Two methods are supported:

- **Online provider** (e.g. Replicate) -- configure in the Setup Wizard. No local setup needed.
- **RMBG-2.0** (local, free) -- see [Optional: RMBG-2.0](#optional-rmbg-20-local-background-removal) above.

If neither is available, background removal is skipped without breaking the pipeline.

## Building from Source

### Prerequisites

- **Python** 3.10+ and **SCons** (Godot build system)
- **Bun** 1.3+ (for OpenCode)
- **Git** with submodule support
- **Visual Studio 2022** or **MSVC Build Tools** (Windows) / GCC/Clang (Linux/macOS)

### Build Steps

```bash
# Clone with submodules
git clone --recursive https://github.com/bluredengine/blured.git
cd blured

# Build (OpenCode + Godot)
/build-blured

# Start the engine
/start-blured
```

These are [Claude Code](https://claude.com/claude-code) slash commands defined in `.claude/skills/`. They handle dependency detection, incremental builds, and launching both the AI server and editor.

## Project Structure

```
blured-engine/
  godot/                    # Modified Godot Engine (submodule)
    editor/plugins/         # AI Assistant & Art Director docks
  opencode/                 # OpenCode AI Server (submodule)
    packages/opencode/
      services/rmbg/        # RMBG-2.0 background removal service
      src/server/           # HTTP server & routes
      src/tool/             # AI tools (asset pipeline, postprocess, etc.)
  launcher/                 # Rust launcher
  docs/                     # Documentation
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [MIT License](LICENSE).

- Godot Engine: [MIT License](godot/LICENSE.txt)
- OpenCode: [MIT License](opencode/LICENSE)
- RMBG-2.0 model weights: [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) (not included in this repo, downloaded on first use)
