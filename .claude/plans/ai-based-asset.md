# Plan: Refactor Godot Asset System for AI Generation

## Overview

Refactor the Godot asset system to support AI-generated assets with:
- **Configurable external services** per asset type (Meshy for 3D, Doubao for 2D, etc.)
- **Bundled asset support** (mesh + material + texture from single prompt)
- **Embedded prompts** for easy regeneration
- **Reproducibility** via seed values and version history

## Architecture: Service-Based Generation

```
┌─────────────────────────────────────────────────────────────────┐
│                     AI Asset Generation Flow                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  User Prompt ──► Asset Service Router ──► External Service API  │
│       │                   │                       │              │
│       │         ┌─────────┴─────────┐            │              │
│       │         │  Service Config   │            │              │
│       │         │  - 2D: Doubao     │            ▼              │
│       │         │  - 3D: Meshy      │     Raw Asset(s)          │
│       │         │  - Audio: Suno    │   (may be bundled)        │
│       │         │  - Font: Custom   │            │              │
│       │         └───────────────────┘            │              │
│       │                                          ▼              │
│       └──────────────────────────────► Godot Import System      │
│                                               │                  │
│                                    ┌──────────┴──────────┐      │
│                                    ▼                     ▼      │
│                              .import files         Resources    │
│                            (with AI metadata)                    │
└─────────────────────────────────────────────────────────────────┘
```

## Service Provider Configuration

Located in `opencode.jsonc` or `~/.opencode/config.jsonc`:

```jsonc
{
  "ai_asset_providers": {
    // 2D Image Generation
    "texture": {
      "provider": "doubao",
      "api": "https://api.doubao.com/v1",
      "env": ["DOUBAO_API_KEY"],
      "models": {
        "default": "doubao-xl",
        "pixel_art": "doubao-pixel"
      }
    },
    // 3D Model Generation (returns bundled: mesh + material + textures)
    "model": {
      "provider": "meshy",
      "api": "https://api.meshy.ai/v2",
      "env": ["MESHY_API_KEY"],
      "models": {
        "default": "meshy-4"
      },
      "output": {
        "format": "glb",
        "bundled": true  // mesh + material + textures together
      }
    },
    // Audio Generation
    "audio": {
      "provider": "suno",
      "api": "https://api.suno.ai/v1",
      "env": ["SUNO_API_KEY"]
    },
    // Fallback/Custom
    "custom": {
      "provider": "openai",
      "api": "https://api.openai.com/v1",
      "env": ["OPENAI_API_KEY"]
    }
  }
}
```

## AI Metadata Schema (Extended for Bundles)

```json
{
  "ai_generated": true,
  "prompt": "A medieval knight character with armor",
  "negative_prompt": "blurry, low poly",

  // Service info
  "provider": "meshy",
  "model": "meshy-4",
  "generation_id": "gen_abc123",

  // For bundled assets - links related resources
  "bundle": {
    "id": "bundle_xyz789",
    "role": "mesh",  // mesh|material|texture|animation
    "related": [
      "res://assets/knight/knight_material.tres",
      "res://assets/knight/knight_diffuse.png",
      "res://assets/knight/knight_normal.png"
    ]
  },

  // Generation parameters
  "seed": 12345,
  "parameters": {
    "style": "realistic",
    "polygon_count": "medium"
  },
  "generated_at": "2026-01-31T10:30:00Z",
  "version": 1
}
```

## Storage Strategy

**Primary**: Godot's `.import` file `metadata` field (native integration)
**Extended**: Optional `.ai.json` sidecar for version history and bundle manifests

---

## Implementation Steps

### Phase 1: Asset Provider System (OpenCode)

#### 1.1 Create Provider Interface
**New file**: `opencode/packages/opencode/src/provider/asset-provider.ts`

```typescript
// Provider interface for all asset generation services
export interface AssetProvider {
  id: string
  name: string
  supportedTypes: AssetType[]

  generate(request: GenerationRequest): Promise<GenerationResult>
  checkStatus(generationId: string): Promise<GenerationStatus>
  download(generationId: string): Promise<AssetBundle>
}

export interface GenerationRequest {
  type: AssetType
  prompt: string
  negativePrompt?: string
  parameters: Record<string, any>
}

export interface GenerationResult {
  generationId: string
  status: "pending" | "processing" | "completed" | "failed"
  estimatedTime?: number
}

export interface AssetBundle {
  // Single prompt may produce multiple related assets
  assets: Array<{
    type: AssetType
    role: "primary" | "material" | "texture" | "animation"
    data: Buffer
    filename: string
    metadata: Record<string, any>
  }>
  bundleId: string
}

export type AssetType =
  | "texture" | "sprite" | "cubemap"
  | "model" | "mesh" | "scene"
  | "audio_sfx" | "audio_music"
  | "shader" | "material"
  | "font"
```

#### 1.2 Implement Provider Adapters
**New files**:
- `opencode/packages/opencode/src/provider/asset/meshy.ts` - 3D models
- `opencode/packages/opencode/src/provider/asset/doubao.ts` - 2D images
- `opencode/packages/opencode/src/provider/asset/suno.ts` - Audio
- `opencode/packages/opencode/src/provider/asset/index.ts` - Registry

```typescript
// Example: Meshy provider for 3D
export class MeshyProvider implements AssetProvider {
  id = "meshy"
  name = "Meshy AI"
  supportedTypes = ["model", "mesh", "scene"]

  async generate(request: GenerationRequest): Promise<GenerationResult> {
    const response = await fetch(`${this.apiUrl}/text-to-3d`, {
      method: "POST",
      headers: { Authorization: `Bearer ${this.apiKey}` },
      body: JSON.stringify({
        prompt: request.prompt,
        negative_prompt: request.negativePrompt,
        art_style: request.parameters.style,
        topology: request.parameters.polygon_count
      })
    })
    return { generationId: response.result, status: "processing" }
  }

  async download(generationId: string): Promise<AssetBundle> {
    // Meshy returns bundled GLB with embedded materials/textures
    const glb = await this.fetchGLB(generationId)
    return {
      bundleId: generationId,
      assets: [
        { type: "model", role: "primary", data: glb, filename: "model.glb" },
        // Extract and return separate textures if needed
        ...this.extractTextures(glb)
      ]
    }
  }
}
```

### Phase 2: Core Metadata System (Godot Engine)

#### 2.1 Add AI Metadata Helper Class
**New file**: `godot/core/io/ai_asset_metadata.h/.cpp`

```cpp
class AIAssetMetadata : public Object {
    GDCLASS(AIAssetMetadata, Object);

public:
    // Metadata creation
    static Dictionary create_metadata(
        const String &prompt,
        const String &provider,
        const String &model,
        int seed = -1
    );

    // Bundle management
    static Dictionary create_bundle_metadata(
        const String &bundle_id,
        const String &role,
        const Vector<String> &related_paths
    );

    // Read/Write operations
    static bool is_ai_generated(const String &p_path);
    static Dictionary get_ai_metadata(const String &p_path);
    static Error set_ai_metadata(const String &p_path, const Dictionary &p_metadata);

    // Bundle operations
    static Vector<String> get_bundle_members(const String &p_path);
    static Error link_bundle_assets(const Vector<String> &p_paths, const String &bundle_id);

protected:
    static void _bind_methods();
};
```

#### 2.2 Modify ResourceFormatImporter
**File**: `godot/core/io/resource_importer.cpp`

Add methods to read/write AI metadata from `.import` files.

#### 2.3 Modify EditorFileSystem
**File**: `godot/editor/file_system/editor_file_system.cpp`

Extend `_reimport_file()` to preserve AI metadata during reimport operations.

---

### Phase 3: OpenCode Tool Integration

#### 3.1 Create AI Asset Tools
**New file**: `opencode/packages/opencode/src/tool/godot-ai-asset.ts`

```typescript
// godot_asset_generate - Generate any asset type via configured provider
export const GodotAssetGenerateTool = Tool.define("godot_asset_generate", {
  parameters: z.object({
    type: z.enum([
      // 2D Graphics
      "texture", "sprite", "cubemap", "texture_array",
      // 3D Models (often bundled output)
      "model", "mesh", "scene",
      // Audio
      "audio_sfx", "audio_music", "audio_voice",
      // Fonts & Shaders
      "font", "shader", "material"
    ]),
    prompt: z.string(),
    negative_prompt: z.string().optional(),
    destination: z.string(),  // e.g., "res://assets/knight/"
    provider: z.string().optional(),  // Override default provider
    parameters: z.record(z.any()).optional(),
  }),
  async execute(args, ctx) {
    // 1. Get provider for asset type
    const provider = getAssetProvider(args.type, args.provider)

    // 2. Start generation (async - may take minutes for 3D)
    const result = await provider.generate({
      type: args.type,
      prompt: args.prompt,
      negativePrompt: args.negative_prompt,
      parameters: args.parameters
    })

    // 3. Poll until complete, then download bundle
    const bundle = await pollAndDownload(provider, result.generationId)

    // 4. Import all assets in bundle to Godot
    for (const asset of bundle.assets) {
      await importAssetToGodot(asset, args.destination, {
        prompt: args.prompt,
        provider: provider.id,
        bundleId: bundle.bundleId,
        role: asset.role
      })
    }

    return {
      output: `Generated ${bundle.assets.length} asset(s) in ${args.destination}`,
      metadata: { bundleId: bundle.bundleId, assets: bundle.assets.map(a => a.filename) }
    }
  }
});

// godot_asset_regenerate - Regenerate bundle from stored prompt
// godot_asset_get_metadata - Read AI generation metadata
// godot_asset_list_bundles - List all AI asset bundles
// godot_asset_configure_provider - Set provider for asset type
```

#### 3.2 Add Server Routes
**New file**: `opencode/packages/opencode/src/server/routes/ai-assets.ts`

```
GET  /ai-assets                    - List all AI-generated assets
GET  /ai-assets/bundles            - List asset bundles
GET  /ai-assets/:path/metadata     - Get AI metadata for asset
PUT  /ai-assets/:path/metadata     - Update AI metadata
POST /ai-assets/generate           - Start async generation
GET  /ai-assets/jobs/:id           - Check generation job status
POST /ai-assets/:path/regenerate   - Regenerate from stored prompt

GET  /ai-assets/providers          - List configured providers
PUT  /ai-assets/providers/:type    - Configure provider for type
```

#### 3.3 Register Tools
**File**: `opencode/packages/opencode/src/tool/godot.ts`

Add new AI asset tools to `GodotTools` export array.

---

### Phase 4: Editor UI (Inspector Integration)

#### 4.1 AI Asset Inspector Plugin
**New file**: `godot/editor/inspector/ai_asset_inspector_plugin.h/.cpp`

Creates an `EditorInspectorPlugin` that:
- Detects AI-generated assets via `ai_generated` metadata flag
- Shows collapsible "AI Generation" section in Inspector
- Displays: prompt, provider, model, seed, generation date
- Shows bundle relationships (linked assets)
- Provides "Edit Prompt" and "Regenerate" buttons
- "Regenerate Bundle" option for bundled assets

#### 4.2 FileSystemDock Context Menu
**File**: `godot/editor/docks/filesystem_dock.cpp`

Add context menu items for AI assets:
- `FILE_MENU_AI_VIEW_PROMPT` - Show AI prompt in popup
- `FILE_MENU_AI_REGENERATE` - Regenerate from stored prompt
- `FILE_MENU_AI_REGENERATE_BUNDLE` - Regenerate entire bundle
- `FILE_MENU_AI_COPY_PROMPT` - Copy prompt to clipboard

#### 4.3 AI Provider Settings
**File**: `godot/editor/project_settings_editor.cpp` or new dock

Add settings UI for configuring asset providers:
- Provider selection per asset type
- API key management
- Default generation parameters

---

### Phase 5: Version History & Bundle Management

#### 5.1 Bundle Manifest Files
For bundled assets, create `.bundle.json` manifest:

```json
{
  "bundle_id": "bundle_xyz789",
  "prompt": "A medieval knight character with armor",
  "provider": "meshy",
  "generated_at": "2026-01-31T10:30:00Z",
  "assets": [
    {"path": "knight.glb", "role": "mesh", "type": "model"},
    {"path": "knight_diffuse.png", "role": "texture", "type": "texture"},
    {"path": "knight_normal.png", "role": "texture", "type": "texture"},
    {"path": "knight_material.tres", "role": "material", "type": "material"}
  ],
  "history": [
    {"version": 1, "prompt": "...", "timestamp": "..."},
    {"version": 2, "prompt": "...", "timestamp": "..."}
  ]
}
```

#### 5.2 History Viewer UI
Add "View History" button in Inspector that opens history dialog with:
- Version timeline
- Prompt diff between versions
- Revert to previous version option

---

## Files to Modify/Create

### OpenCode - Provider System (TypeScript)
| File | Purpose |
|------|---------|
| `opencode/src/provider/asset-provider.ts` | **NEW** - Provider interface & types |
| `opencode/src/provider/asset/index.ts` | **NEW** - Provider registry |
| `opencode/src/provider/asset/meshy.ts` | **NEW** - Meshy 3D provider |
| `opencode/src/provider/asset/doubao.ts` | **NEW** - Doubao 2D provider |
| `opencode/src/provider/asset/suno.ts` | **NEW** - Suno audio provider |
| `opencode/src/config/config.ts` | Add `ai_asset_providers` schema |

### OpenCode - Tools & Routes (TypeScript)
| File | Purpose |
|------|---------|
| `opencode/src/tool/godot-ai-asset.ts` | **NEW** - AI asset generation tools |
| `opencode/src/tool/godot.ts` | Export new tools |
| `opencode/src/server/routes/ai-assets.ts` | **NEW** - AI asset REST endpoints |
| `opencode/src/server/index.ts` | Register AI asset routes |

### Godot Engine (C++)
| File | Changes |
|------|---------|
| `godot/core/io/resource_importer.h` | Add AI metadata method declarations |
| `godot/core/io/resource_importer.cpp` | Implement AI metadata read/write |
| `godot/editor/file_system/editor_file_system.cpp` | Preserve AI metadata on reimport |
| `godot/editor/docks/filesystem_dock.h` | Add FILE_MENU_AI_* enum values |
| `godot/editor/docks/filesystem_dock.cpp` | Add context menu handlers |
| `godot/editor/editor_node.cpp` | Register AI inspector plugin |

### New Godot Files (C++)
| File | Purpose |
|------|---------|
| `godot/core/io/ai_asset_metadata.h/.cpp` | AI metadata & bundle utilities |
| `godot/editor/inspector/ai_asset_inspector_plugin.h/.cpp` | Inspector UI for AI assets |

---

## Verification Plan

1. **Provider Tests**:
   - Mock API responses for each provider (Meshy, Doubao, Suno)
   - Test bundle extraction from 3D model responses
   - Test async polling and timeout handling

2. **Integration Test**:
   - Generate 2D texture via Doubao provider
   - Generate 3D model via Meshy (verify bundled assets created)
   - Verify metadata stored in `.import` files
   - Verify `.bundle.json` created for bundled assets
   - Regenerate and verify version incremented

3. **Editor Test**:
   - Import AI-generated bundle
   - Check Inspector shows AI Generation section with bundle info
   - Test "Regenerate Bundle" regenerates all linked assets
   - Test context menu options

4. **End-to-End Test**:
   - Configure Meshy provider in settings
   - Use AI Assistant: "Generate a 3D sword model"
   - Verify GLB + textures + materials imported
   - Edit prompt and regenerate
   - Verify old bundle replaced with new version

---

## Comprehensive Asset Type Support

The AI metadata system will support **all** Godot asset types. Each category has specific generation parameters.

### 2D Graphics & Textures
| Type | Extensions | AI Generation Use Cases |
|------|------------|------------------------|
| Texture2D | .png, .jpg, .webp | Character sprites, backgrounds, UI elements |
| SVG | .svg | Vector icons, scalable graphics |
| BitMap | .png, .jpg | Masks, collision shapes |
| TextureAtlas | .png | Sprite sheets, tile sets |
| Cubemap | .png, .hdr, .exr | Environment maps, skyboxes |
| Texture2DArray | .png | Animation frames, terrain layers |
| Texture3D | .png | Volume textures, 3D noise |

### 3D Models & Scenes
| Type | Extensions | AI Generation Use Cases |
|------|------------|------------------------|
| PackedScene | .gltf, .glb | 3D characters, props, environments |
| Mesh | .obj | Simple geometry, procedural meshes |
| FBX | .fbx | Rigged characters, animations |
| Blend | .blend | Complex models (via Blender) |

### Audio
| Type | Extensions | AI Generation Use Cases |
|------|------------|------------------------|
| AudioStreamWAV | .wav | Sound effects, UI sounds |
| AudioStreamMP3 | .mp3 | Music, ambient loops |
| AudioStreamOggVorbis | .ogg | Compressed audio, voice lines |

### Fonts
| Type | Extensions | AI Generation Use Cases |
|------|------------|------------------------|
| FontFile | .ttf, .otf, .woff2 | Custom typography |
| ImageFont | .png | Pixel art fonts, stylized text |
| BMFont | .fnt | Bitmap fonts with effects |

### Shaders & Materials
| Type | Extensions | AI Generation Use Cases |
|------|------------|------------------------|
| Shader | .gdshader | Visual effects, post-processing |
| ShaderFile | .glsl | Compute shaders, custom rendering |
| Material | .tres | PBR materials, stylized looks |

### Data & Text
| Type | Extensions | AI Generation Use Cases |
|------|------------|------------------------|
| Translation | .csv | Localized text content |
| Script | .gd | Game logic (already supported) |

### Extended Metadata Schema by Asset Type

```json
{
  "ai_generated": true,
  "asset_type": "texture",  // texture|audio|model|shader|font|data
  "prompt": "A 2D pixel art knight character sprite",
  "negative_prompt": "blurry, low quality",
  "model": "stability-ai/sdxl",
  "seed": 12345,
  "generated_at": "2026-01-31T10:30:00Z",
  "version": 1,

  // Type-specific parameters
  "parameters": {
    // For textures:
    "style": "pixel_art",
    "size": "64x64",
    "color_palette": "limited_16",
    "transparency": true,

    // For audio:
    "duration_seconds": 2.5,
    "sample_rate": 44100,
    "audio_type": "sfx",  // sfx|music|voice|ambient

    // For 3D models:
    "polygon_count": "low",  // low|medium|high
    "texture_resolution": "1024",
    "rigged": false,

    // For shaders:
    "shader_type": "spatial",  // spatial|canvas_item|particles|sky
    "render_mode": "unshaded",

    // For fonts:
    "font_style": "display",  // display|body|mono
    "character_set": "latin"
  }
}
```

---

## Migration for Existing Assets

Provide utility to mark existing assets as AI-generated:
1. Right-click asset → "Set AI Metadata..."
2. Dialog to enter original prompt/model/seed
3. Stores metadata in `.import` file
