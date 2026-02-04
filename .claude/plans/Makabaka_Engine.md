# Plan: Makabaka Engine - Open Source AI Game Engine

## Summary

Create **Makabaka Engine** - an open source AI-powered game engine by merging:
- **Godot Engine** (with AI plugin) - the runtime and editor
- **OpenCode** (via git subtree) - the AI orchestration infrastructure

This replaces the Python `ai_service` with OpenCode's sophisticated TypeScript infrastructure while adding Godot-specific features (modules, templates, game commands).

## Open Source Strategy

### Repository Structure (Community-Friendly)
```
makabaka-engine/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── module_proposal.md      # For community modules
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── workflows/
│   │   ├── build.yml               # CI for all platforms
│   │   ├── test.yml
│   │   └── release.yml             # Auto-release binaries
│   └── FUNDING.yml
├── docs/
│   ├── getting-started.md
│   ├── architecture.md
│   ├── contributing/
│   │   ├── modules.md              # How to create modules
│   │   ├── templates.md            # How to create templates
│   │   └── core.md                 # Core development guide
│   └── api/
├── README.md                       # Project overview + quick start
├── CONTRIBUTING.md                 # Contribution guidelines
├── CODE_OF_CONDUCT.md
├── LICENSE                         # MIT recommended
├── CHANGELOG.md
└── ROADMAP.md                      # Public roadmap
```

### Licensing
- **Engine Core**: MIT License (matches Godot)
- **OpenCode subtree**: MIT License (already MIT)
- **Community modules/templates**: MIT (required for inclusion)

### Community Contribution Areas

| Area | Difficulty | Good for |
|------|------------|----------|
| **Game Templates** | Easy | Beginners, game designers |
| **Game Modules** | Easy-Medium | GDScript developers |
| **Documentation** | Easy | Writers, translators |
| **Godot Skills** | Medium | TypeScript developers |
| **Core Engine** | Hard | Experienced contributors |

### Beginner-Friendly Features
1. **Template Gallery** - Community can submit game templates
2. **Module Marketplace** - Searchable registry of modules
3. **"Good First Issue"** labels for newcomers
4. **Comprehensive docs** with tutorials

## Architecture Overview

```
Makabaka Engine
├── godot/                    (Godot Engine source - existing)
├── addons/godot_ai/          (Godot AI Plugin - existing, needs updates)
├── opencode/                  (OpenCode subtree - from G:\opencode)
│   └── packages/opencode/    (Core AI service)
├── modules/                   (Game module library - NEW)
├── templates/                 (Game templates - NEW)
└── makabaka.json             (Engine configuration)
```

## Phase 1: Git Subtree Setup

### 1.1 Add OpenCode as subtree
```bash
cd g:\godot
git subtree add --prefix=opencode G:\opencode master --squash
```

### 1.2 Create engine configuration
Create `makabaka.json` at project root with engine-wide settings.

## Phase 2: OpenCode Modifications

### Files to Modify in `opencode/packages/opencode/`

#### 2.1 [src/agent/agent.ts](opencode/packages/opencode/src/agent/agent.ts)
**Add Godot-specific agent:**
- Create "godot" agent type with game development system prompt
- Load module interfaces as context
- Include template awareness

#### 2.2 [src/server/routes/](opencode/packages/opencode/src/server/routes/)
**Add new routes:**
- `godot.ts` - Godot-specific endpoints:
  - `POST /godot/command` - Execute Godot commands
  - `GET /godot/state` - Get project state
  - `GET /godot/modules` - List available modules
  - `GET /godot/templates` - List templates

#### 2.3 [src/skill/](opencode/packages/opencode/src/skill/)
**Add Godot skills (tools):**
- `godot-scene.ts` - Scene manipulation tools
- `godot-script.ts` - Script creation/modification
- `godot-resource.ts` - Asset management
- `godot-editor.ts` - Editor control
- `godot-project.ts` - Project/run commands

#### 2.4 [src/index.ts](opencode/packages/opencode/src/index.ts)
**Add `makabaka` CLI command:**
```typescript
.command("makabaka", "Start Makabaka Engine server", (yargs) => {
  return yargs.option("port", { default: 4096 })
}, async (args) => {
  // Start with Godot-specific configuration
})
```

## Phase 3: Godot Plugin Updates

### Files to Modify in `addons/godot_ai/`

#### 3.1 [bridge/service_manager.gd](addons/godot_ai/bridge/service_manager.gd)
**Start OpenCode/Makabaka server:**
```gdscript
# Change from Python to OpenCode
@export var service_port: int = 4096

func _find_makabaka_path() -> String:
    var paths = [
        "res://opencode/packages/opencode/bin/opencode",
        ProjectSettings.globalize_path("res://") + "opencode/packages/opencode/dist/opencode-win32-x64/opencode.exe"
    ]
    # ...

func start_service() -> Error:
    var args = ["makabaka", "--port", str(service_port)]
    _process_id = OS.create_process(makabaka_path, args, false)
```

#### 3.2 [bridge/bridge.gd](addons/godot_ai/bridge/bridge.gd)
**Convert WebSocket to HTTP/SSE:**
- Replace `WebSocketPeer` with `HTTPRequest`
- Implement session management via REST API
- Subscribe to SSE events at `GET /event`
- Parse tool results and execute commands

#### 3.3 [dock/ai_dock.gd](addons/godot_ai/dock/ai_dock.gd)
**Update UI:**
- Add template selector dropdown
- Add module browser panel
- Update status messages for Makabaka

## Phase 4: New Directories

### 4.1 `modules/` - Game Module Library
```
modules/
├── module_registry.json
├── core/
│   ├── game_manager/
│   │   ├── interface.json      # Module interface for LLM context
│   │   └── game_manager.gd
│   ├── input_handler/
│   └── audio_manager/
├── player/
│   ├── player_movement/
│   └── player_combat/
└── world/
    ├── level_manager/
    └── spawn_system/
```

### 4.2 `templates/` - Game Templates
```
templates/
├── template_registry.json
├── platformer_2d/
│   ├── template.json
│   └── project/
├── tower_defense/
└── rpg_topdown/
```

## Phase 5: Delete Python Service

Remove `ai_service/` directory entirely after migration is complete.

## Implementation Order

| Step | Description | Files |
|------|-------------|-------|
| 1 | Git subtree add OpenCode | CLI |
| 2 | Build OpenCode executable | `opencode/packages/opencode/` |
| 3 | Update service_manager.gd | [service_manager.gd](addons/godot_ai/bridge/service_manager.gd) |
| 4 | Convert bridge to HTTP | [bridge.gd](addons/godot_ai/bridge/bridge.gd) |
| 5 | Add Godot skills to OpenCode | `opencode/packages/opencode/src/skill/` |
| 6 | Add Godot routes | `opencode/packages/opencode/src/server/routes/godot.ts` |
| 7 | Create module system | `modules/` |
| 8 | Create template system | `templates/` |
| 9 | Update dock UI | [ai_dock.gd](addons/godot_ai/dock/ai_dock.gd) |
| 10 | Delete ai_service | `ai_service/` |

## Godot Skills (Tools) for OpenCode

```typescript
// opencode/packages/opencode/src/skill/godot-scene.ts
export const GodotSceneSkills = {
  "godot.scene.create_node": {
    description: "Create a node in the Godot scene tree",
    args: {
      type: z.string(),    // e.g., "CharacterBody2D"
      name: z.string(),
      parent: z.string().default("/root"),
      properties: z.record(z.any()).optional()
    },
    execute: async (args) => ({
      type: "godot_command",
      command: { action: "scene.create_node", params: args }
    })
  },
  // ... more skills
}
```

## Verification

1. **Build OpenCode:**
   ```bash
   cd opencode && bun install && bun run build
   ```

2. **Test Makabaka server:**
   ```bash
   ./opencode/packages/opencode/dist/opencode makabaka --port 4096
   curl http://localhost:4096/doc  # Should show OpenAPI docs
   ```

3. **Test from Godot:**
   - Enable GodotAI plugin
   - AI dock should show "Connected"
   - Send prompt: "Create a Sprite2D named Player"
   - Verify node created in scene tree

4. **Test module loading:**
   - Prompt: "Add player movement to the character"
   - Should load PlayerMovement module interface
   - Generate appropriate code

## Key OpenCode Changes Summary

| Area | Change |
|------|--------|
| CLI | Add `makabaka` command |
| Skills | Add `godot.*` tools (scene, script, resource, editor, project) |
| Routes | Add `/godot/*` endpoints |
| Agent | Add "godot" agent with game dev system prompt |
| Config | Support `makabaka.json` for engine settings |

## Dependencies

- Bun 1.3+ (for building OpenCode)
- Node.js 18+ (optional, for running without Bun)
- Git (for subtree management)

---

## Open Source Infrastructure

### GitHub Actions CI/CD

#### `.github/workflows/build.yml`
```yaml
name: Build
on: [push, pull_request]
jobs:
  build-opencode:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v1
      - run: cd opencode && bun install && bun run build
      - uses: actions/upload-artifact@v4
        with:
          name: makabaka-${{ matrix.os }}
          path: opencode/packages/opencode/dist/
```

#### `.github/workflows/release.yml`
Auto-release on tag push with binaries for all platforms.

### README.md Structure

```markdown
# 🎮 Makabaka Engine

AI-powered game creation engine built on Godot.

[![Build](badge)](link) [![License: MIT](badge)](link) [![Discord](badge)](link)

## ✨ Features
- 🗣️ Create games with natural language
- 🧩 Modular architecture with 20+ pre-built modules
- 📦 10+ game templates (platformer, RPG, tower defense...)
- 🤖 Multi-provider AI (Claude, GPT-4, local models)

## 🚀 Quick Start
[One-command installation]

## 📖 Documentation
[Link to docs site]

## 🤝 Contributing
We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md)

### Easy ways to contribute:
- 🎨 Create a game template
- 🧩 Build a reusable module
- 📝 Improve documentation
- 🌍 Translate to your language

## 📜 License
MIT License
```

### CONTRIBUTING.md Sections

1. **Code of Conduct** - Link to CODE_OF_CONDUCT.md
2. **Getting Started** - Dev environment setup
3. **Types of Contributions**
   - Templates (easiest)
   - Modules (easy)
   - Documentation (easy)
   - Bug fixes (medium)
   - Features (discuss first)
4. **Pull Request Process**
5. **Style Guides** - GDScript, TypeScript
6. **Community** - Discord, Discussions

### Module Contribution Guide (`docs/contributing/modules.md`)

```markdown
# Creating a Community Module

## Module Structure
modules/
└── your_module/
    ├── interface.json    # Required: LLM-readable interface
    ├── your_module.gd    # Main script
    ├── README.md         # Documentation
    └── examples/         # Usage examples

## interface.json Schema
{
  "module_id": "your_module",
  "name": "Your Module",
  "description": "What it does (for LLM context)",
  "inputs": { ... },
  "outputs": { ... },
  "signals": { ... }
}

## Submission Checklist
- [ ] interface.json is complete and accurate
- [ ] README.md with usage instructions
- [ ] At least one example
- [ ] Works with latest Godot 4.x
- [ ] MIT licensed
```

### Template Contribution Guide (`docs/contributing/templates.md`)

```markdown
# Creating a Game Template

Templates help users start new games quickly.

## Template Structure
templates/
└── your_template/
    ├── template.json         # Manifest
    ├── project/              # Complete Godot project
    ├── customization.json    # What AI can modify
    ├── README.md
    └── preview.png           # Gallery thumbnail

## Submission Checklist
- [ ] Fully playable demo
- [ ] Clear customization points
- [ ] Preview image (800x600)
- [ ] Documentation
- [ ] MIT licensed
```

### Issue Templates

#### Bug Report (`.github/ISSUE_TEMPLATE/bug_report.md`)
```markdown
**Describe the bug**

**To Reproduce**
1.
2.

**Expected behavior**

**Screenshots**

**Environment:**
- OS:
- Godot version:
- Makabaka version:
```

#### Module Proposal (`.github/ISSUE_TEMPLATE/module_proposal.md`)
```markdown
**Module Name**

**Description**
What does this module do?

**Use Cases**
- Game type 1
- Game type 2

**Interface Draft**
```json
{
  "inputs": {},
  "outputs": {},
  "signals": {}
}
```

**Would you like to implement this?**
- [ ] Yes, I'll submit a PR
- [ ] No, hoping someone else will
```

---

## Revised Implementation Order (Open Source Focus)

| Phase | Step | Description |
|-------|------|-------------|
| **Setup** | 1 | Create new repo `makabaka-engine` |
| | 2 | Add LICENSE (MIT), CODE_OF_CONDUCT.md |
| | 3 | Git subtree add OpenCode |
| | 4 | Setup GitHub Actions CI |
| **Core** | 5 | Update service_manager.gd for OpenCode |
| | 6 | Convert bridge.gd to HTTP/SSE |
| | 7 | Add Godot skills to OpenCode |
| | 8 | Add `/godot/*` routes |
| **Community** | 9 | Create module system + 3 starter modules |
| | 10 | Create template system + 2 starter templates |
| | 11 | Write CONTRIBUTING.md + guides |
| | 12 | Write README.md + quick start |
| **Launch** | 13 | Setup GitHub Releases with binaries |
| | 14 | Create documentation site |
| | 15 | Delete ai_service/, tag v0.1.0 |

---

## Community Building

### Launch Checklist
- [ ] README with clear value proposition
- [ ] One-command install/setup
- [ ] 3+ working templates to demo
- [ ] Video demo / GIF in README
- [ ] Discord server or GitHub Discussions
- [ ] "Good First Issue" labels on 5+ issues
- [ ] Documentation site (Docusaurus/VitePress)

### Growth Strategy
1. **Templates** - Easy contribution path brings in game developers
2. **Modules** - GDScript devs can contribute without learning TS
3. **Translations** - Global community involvement
4. **Showcase** - Gallery of games made with Makabaka
