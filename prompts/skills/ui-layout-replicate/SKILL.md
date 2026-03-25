---
name: ui-layout-replicate
description: Replicate a UI layout from a cornerstone reference image into a pixel-perfect .tscn scene. Use when user says "replicate UI layout", "build layout from reference", "1:1 UI copy", or has a cornerstone UI image to turn into a scene.
auto_detect: replicate.*layout|layout.*from.*reference|1:1.*UI|copy.*UI.*layout|build.*layout.*scene|layout.*from.*cornerstone
---

# UI Layout 1:1 Replication

Replicate a cornerstone UI reference image into a pixel-perfect Godot `.tscn` scene.

**Core principle: Measure → Calculate proportions → Scale to target resolution → Use `custom_minimum_size` with fixed pixel values.**

---

## Step 1: Gather Parameters

**Actions:**
1. Read `project.godot` to get viewport dimensions:
   - `display/window/size/viewport_width`
   - `display/window/size/viewport_height`
2. Read the reference image to get its pixel dimensions (use `read` tool on the image file — you can see its resolution)
3. Compute scale factor:
   ```
   scale_factor = viewport_height / reference_height
   ```
4. Present parameters to user for confirmation:

| Parameter | Value |
|-----------|-------|
| Viewport | {width} × {height} |
| Reference image | {path} |
| Reference resolution | {ref_width} × {ref_height} |
| Scale factor | {scale_factor}× |

**STOP and confirm with user before proceeding.**

---

## Step 2: Measure Reference Image (Tool-Assisted)

**Actions:**
1. Call `godot_ui_measure` with:
   - `reference_image`: path to the cornerstone reference image
   - `viewport_width`: from Step 1
   - `viewport_height`: from Step 1
   - `panel_description`: brief description of the UI panel (e.g. "shop panel", "main menu")
   - `font_name`: project font name if known (e.g. "PressStart2P.ttf (pixel font, monospaced)")
2. The tool sends the image to a separate LLM for detailed measurement analysis
3. It returns:
   - Top-level layout structure and region measurements
   - Per-element measurements (position, size, colors, font sizes, corner radii)
   - Spacing patterns
   - Color palette
   - All values scaled to the target viewport resolution
   - Space budget verification (must balance to 0)
   - Final summary table of ALL nodes for the .tscn file
   - The reference image as an attachment for your verification

4. **Trust the measurement output — do NOT re-examine the image yourself.** The vision model has already done pixel-precise analysis. Just:
   - Verify the space budget adds up (difference should be 0)
   - Use the **Final Summary Table** directly when writing the .tscn in Step 3

**Ask user via `question` tool:**
- header: "UI Measurements"
- question: "The measurement tool analyzed the reference image. Do these measurements look accurate?"
- options: "Measurements look correct", "Re-measure with adjustments"

---

## Step 3: Write the .tscn File

**CRITICAL RULES (non-negotiable):**

### Section Heights — `custom_minimum_size` ONLY
```
[node name="BlindBar" type="PanelContainer"]
custom_minimum_size = Vector2(0, 138)
layout_mode = 2
```
**NEVER use `size_flags_vertical = 3` (expand) or `stretch_ratio`.** Fixed viewport = fixed pixel values.

### Internal Elements — Scale by factor
ALL values inside sections must be computed, never guessed:
```
target_value = round(reference_value × scale_factor)
```

| Element Type | Example |
|-------------|---------|
| font_size | `round(12 × 1.875) = 22` |
| separation | `round(8 × 1.875) = 15` |
| icon size | `round(24 × 1.875) = 45` |
| custom_minimum_size | `round(80 × 1.875) = 150` |

### StyleBox Sub-resources — Scale ALL 4 categories
Every StyleBoxFlat must have ALL properties scaled:
- `content_margin_left/top/right/bottom`
- `border_width_left/top/right/bottom`
- `corner_radius_top_left/top_right/bottom_right/bottom_left`
- `shadow_size` (if present)

**Special:** Circular elements need `corner_radius >= size / 2`.

### Font Selection (MANDATORY — never use default Godot font)
Before writing the .tscn, you MUST find and download fonts that match the reference image:
1. Check `res://assets/fonts/` for existing project fonts
2. If no matching fonts exist:
   - Study the typography in the measurement output (serif vs sans-serif, weight, pixel/retro style, decorative features)
   - Search for matching free fonts on Google Fonts using `web_search` (e.g. "free pixel font google fonts", "free serif display font")
   - Try multiple search queries — match the visual character: weight (bold/light), style (geometric, handwritten, pixel, slab-serif), and mood (playful, elegant, gritty)
   - Download `.ttf`/`.otf` files to `res://assets/fonts/` using `web_fetch`
3. You may need MULTIPLE fonts — one for headings/titles and one for body text is common
4. Reference fonts via `[ext_resource type="FontFile" path="res://assets/fonts/..."]`
5. Apply via `theme_override_fonts/font` on Label/Button nodes — the default Godot font is NEVER acceptable

### Node Rules
- ALL nodes defined STATICALLY in the .tscn — no scripts, no `_ready()`, no runtime creation
- Text: `Label` nodes with placeholder text and project font applied
- Buttons: `Button` nodes with text and project font applied (no scripts)
- Do NOT attach any `.gd` scripts

### Texture Placeholders — Use Real Files, Not ColorRect
Elements that will need a texture in the final UI (icons, backgrounds, decorative images, avatar frames, etc.) must use **placeholder texture files** instead of `ColorRect`:

1. **Identify texture elements** during measurement analysis — any element that is clearly an image/icon/graphic rather than a solid-color panel background
2. **Create placeholder textures** by calling `godot_asset_create_placeholder` for each:
   - `type`: `"texture"`
   - `destination`: `res://assets/ui/[screen]/[element_name].png`
   - `prompt`: Describe what the final texture should look like (e.g. "golden coin icon with shine effect, pixel art style")
   - `category`: `"ui"`
   - `usage`:
     - `scene`: the .tscn path being created
     - `node_path`: Godot node path (e.g. `"Root/Header/CoinIcon"`)
     - `role`: what this texture represents (e.g. `"currency icon"`)
     - `width` / `height`: scaled pixel dimensions from measurements
     - `transparent_bg`: `true` for icons/overlays, `false` for full backgrounds
3. **Use `TextureRect`** in the .tscn referencing the placeholder PNG:
   ```
   [node name="CoinIcon" type="TextureRect" parent="Header"]
   texture = ExtResource("coin_icon_png")
   custom_minimum_size = Vector2(45, 45)
   stretch_mode = 6
   ```
4. Elements that are simple solid-color backgrounds (panel fills, dividers) should still use `StyleBoxFlat` on containers — do NOT create placeholder textures for these

This ensures:
- The scene is immediately renderable with colored placeholder PNGs
- Each placeholder carries metadata (`prompt`, `usage`, dimensions) for later `godot_asset_pipeline` generation
- Asset generation (Step 4 in ui-production) can auto-discover all placeholders and batch-generate real textures
- No manual bookkeeping — the metadata IS the generation spec

**Actions:**
1. Identify all texture elements from the measurement output
2. Call `godot_asset_create_placeholder` for each texture element
3. Write the `.tscn` file to `res://scenes/ui/[screen_name]_layout.tscn`, referencing placeholder PNGs via `ExtResource`
4. Call `godot_editor_command` with action `scan_filesystem`
5. Ask user to open the scene in editor

---

## Step 4: Verify

**Actions:**
1. Take `godot_screenshot` of the layout scene
2. Compare side-by-side with the reference image
3. Check:
   - Section proportions match the reference
   - Text sizes are proportional
   - Spacing and padding are consistent
   - Overall visual weight matches

**Ask user via `question` tool:**
- header: "Layout Verification"
- question: "Here is the replicated layout vs the reference. Does the layout match?"
- options: "Layout matches — done", "Adjust specific sections", "Remeasure and redo"

---

## Anti-Patterns (FORBIDDEN)

### 1. No stretch_ratio
```
# WRONG — unpredictable, depends on sibling min_sizes
size_flags_vertical = 3
size_flags_stretch_ratio = 2.5

# CORRECT — fixed pixel value, precise and controllable
custom_minimum_size = Vector2(0, 299)
```

### 2. No guessing pixel values
```
# WRONG — "looks about right"
font_size = 40

# CORRECT — measured from reference then calculated
# Reference: 38px → 38 × 1.875 = 71
font_size = 71
```

### 3. No ignoring consumed space
When calculating available space, you MUST deduct:
- MarginContainer margins
- PanelContainer StyleBox border_width
- PanelContainer StyleBox content_margin
- VBoxContainer / HBoxContainer separation × (child_count - 1)

### 4. No mixing fixed and elastic
All sibling sections in a VBox must use the same strategy — either ALL fixed heights or ALL elastic. Never mix.

### 5. No partial StyleBox scaling
Every StyleBox has 4 categories that ALL need scaling. Missing any one causes visual inconsistency.
