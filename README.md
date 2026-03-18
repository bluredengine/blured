# Makabaka Engine

An AI-powered game engine built on [Godot 4.x](https://godotengine.org/) and [OpenCode](https://github.com/opencode-ai/opencode). Create games using natural language — from asset generation to gameplay scripting.

## Architecture

```
Godot Editor (C++) <--HTTP--> OpenCode AI Server (Bun/TypeScript) <--> Cloud AI APIs
       |                            |
  Game runtime              LLM orchestration
  Editor UI                 Tool execution
  AI Assistant dock         Asset pipeline
```

**Makabaka Engine** = Modified Godot Engine + OpenCode AI Server

- **Godot** provides the game engine, editor, and runtime
- **OpenCode** provides AI orchestration, LLM integration, and natural language processing
- The native `godot_ai` module integrates AI directly into the editor

## Features

- **AI Assistant** — Chat interface embedded in the Godot editor with multi-instance support, streaming responses, and tool execution
- **AI Asset Generation** — Generate textures, sprites, 3D models, audio, and more via cloud AI (Replicate, Meshy, Suno)
- **Art Director** — Visual style exploration, style locking, and batch asset production with style consistency
- **Background Removal** — Automatic background removal in the asset pipeline (see [configuration](#background-removal))
- **Debugger Integration** — Runtime errors are automatically forwarded to the AI for diagnosis
- **Screenshot Analysis** — Capture game screenshots for AI-powered visual QA

See [docs/makabaka-engine.md](docs/makabaka-engine.md) for the full feature reference.

## Prerequisites

- **Python** 3.10+ (for SCons build and RMBG service)
- **SCons** (Godot build system)
- **Bun** 1.3+ (for OpenCode)
- **Git** with submodule support
- **Visual Studio 2022** or **MSVC Build Tools** (Windows) / GCC/Clang (Linux/macOS)

## Getting Started

```bash
# Clone with submodules
git clone --recursive https://github.com/makabaka-engine/makabaka-engine.git
cd makabaka-engine

# Install OpenCode dependencies
cd opencode
bun install
cd ..

# Build Godot
cd godot
python -m SCons platform=windows target=editor d3d12=no -j8
cd ..

# Start the engine
./start_makabaka.bat
```

## Configuration

### LLM Provider

Set your LLM API key in the project `.env` file or via the Setup Wizard in the AI Assistant panel.

### AI Asset Providers

Configure API keys for asset generation providers in the AI Assistant Setup Wizard:

| Provider | Purpose | Auth |
|----------|---------|------|
| **Replicate** | Textures, sprites, backgrounds | OAuth or API token |
| **Meshy** | 3D models with PBR textures | API key |
| **Suno** | Music, SFX, voice | API key |

### Background Removal

The asset pipeline automatically removes backgrounds from generated sprites and textures. Two providers are supported:

#### Option 1: PhotoRoom API (cloud, fast)

Set the `PHOTOROOM_API_KEY` environment variable. Get a key from [photoroom.com](https://www.photoroom.com/api).

#### Option 2: RMBG-2.0 (local, free)

A local background removal service using [BRIA RMBG-2.0](https://huggingface.co/briaai/RMBG-2.0). No API key needed.

```bash
# Install Python dependencies
pip install -r opencode/packages/opencode/services/rmbg/requirements.txt
```

The service starts automatically with the engine on port `7860`. On first run, the model (~1GB) is downloaded from HuggingFace.

**GPU acceleration** is optional — install the [CUDA version of PyTorch](https://pytorch.org/get-started/locally/) for faster inference. CPU also works.

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `MAKABAKA_RMBG_PORT` | `7860` | Port for the RMBG service |

**Priority:** PhotoRoom is used when configured. Otherwise RMBG-2.0 is used. If neither is available, background removal is skipped without breaking the pipeline.

> **License note:** The RMBG-2.0 model is licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/). Commercial use requires a separate agreement with [BRIA](https://bria.ai/).

## Project Structure

```
makabaka-engine/
  godot/                    # Modified Godot Engine (submodule)
    modules/godot_ai/       # Native AI integration module
    editor/plugins/         # AI Assistant & Art Director docks
  opencode/                 # OpenCode AI Server (submodule)
    packages/opencode/
      services/rmbg/        # RMBG-2.0 background removal service
      src/server/           # HTTP server & routes
      src/tool/             # AI tools (asset pipeline, postprocess, etc.)
  templates/                # Game templates
  modules/                  # Reusable game modules
  docs/                     # Documentation
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [MIT License](LICENSE).

- Godot Engine: [MIT License](godot/LICENSE.txt)
- OpenCode: [MIT License](opencode/LICENSE)
- RMBG-2.0 model weights: [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) (not included in this repo, downloaded on first use)
