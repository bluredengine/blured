---
name: analyze-screenshot
description: Analyze game screenshots for visual design issues, UI problems, and art consistency. Automatically triggers when a screenshot is attached.
auto_detect: analyze.*screenshot|check.*ui|review.*screenshot|what.*wrong.*screen|visual.*feedback
auto_detect_attachment: image
---

# Game Screenshot Visual Analysis

Perform a systematic visual design review of the attached game screenshot using the checklist below. Cover **every category** — do not skip sections even if they seem fine. Call out both problems and things that work well.

## Analysis Checklist

### 1. Typography & Text
- [ ] Font style matches game's visual theme (pixel font for pixel art, etc.)
- [ ] Font sizes create clear hierarchy (title > body > caption)
- [ ] Text is readable against its background (contrast ratio)
- [ ] Consistent capitalization and punctuation
- [ ] Numbers and units have proper spacing (e.g., `45 Damage` not `45damage`)
- [ ] No text overflow or clipping
- [ ] Localization-safe layout (text boxes have room to expand)

### 2. Color & Contrast
- [ ] UI elements have sufficient contrast against the game background
- [ ] Color used consistently to communicate meaning (red=danger, green=health, gold=rare)
- [ ] No two similar colors used for different meanings
- [ ] Text meets minimum contrast ratio (~4.5:1 for normal text)
- [ ] Rarity/tier colors are distinct and recognizable

### 3. Visual Hierarchy & Layout
- [ ] Most important info (health, current action) is most prominent
- [ ] Related elements are grouped visually
- [ ] Spacing is consistent between similar elements
- [ ] Alignment is consistent (left-aligned text, centered icons, etc.)
- [ ] No crowding or excessive empty space

### 4. HUD (Heads-Up Display)
- [ ] Health/resource bars are clearly visible and readable
- [ ] Player stats (level, score, timer) are quick to scan
- [ ] HUD doesn't obscure important gameplay area
- [ ] Experience bar present if leveling system exists
- [ ] Minimap or positional info if needed

### 5. Popup / Modal UI (if present)
- [ ] Background dimmed/blurred to focus attention on popup
- [ ] Popup has clear visual boundary (border, shadow, background panel)
- [ ] Number of options feels sufficient and meaningful for the game's design
- [ ] Hover/selected state visually distinct
- [ ] Close/confirm actions clearly indicated

### 6. Feedback & Game Feel
- [ ] State changes are visually communicated (selection, activation, completion, failure)
- [ ] Interactive elements look interactable (buttons look clickable, etc.)
- [ ] Important game objects are visually distinct from background/environment
- [ ] Effects and animations (if visible) are readable and not cluttered
- [ ] Numeric feedback (if present) is differentiated by type (e.g., crit vs normal)

### 7. Art Style Consistency
- [ ] UI elements match the game's art style (pixel art UI for pixel art game)
- [ ] Icon style is consistent across all icons
- [ ] No mixed resolution assets (blurry low-res next to sharp high-res)
- [ ] Background/terrain has texture or detail (not flat black)

### 8. Information Density
- [ ] Screen is not overcrowded with numbers/icons
- [ ] Critical information visible at a glance without hunting
- [ ] Secondary info accessible but not distracting

## Output Format

Structure the analysis as follows:

```
## Game Screenshot Analysis

### Summary
[1-2 sentences describing the overall state of the UI]

### Issues Found

#### Critical (breaks readability or usability)
- [Issue]: [Why it's a problem] → [Specific fix]

#### Minor (degrades polish or feel)
- [Issue]: [Why it's a problem] → [Specific fix]

#### Nitpicks (small improvements)
- [Issue] → [Fix]

### What Works Well
- [Element]: [Why it's effective]

### Top 3 Priority Fixes
1. [Highest impact fix]
2. [Second priority]
3. [Third priority]
```

## Rules

- **Be specific** — cite exact elements ("the damage number font" not "text")
- **Give actionable fixes** — not just "improve contrast" but "add a dark drop shadow behind damage numbers"
- **Never skip typography** — always review font style, size hierarchy, spacing, and theme match
- **Check every popup element** — modals and dialogs get full scrutiny (background dim, option count, hover states, text formatting)
- **Prioritize ruthlessly** — end with a clear top 3 action list
