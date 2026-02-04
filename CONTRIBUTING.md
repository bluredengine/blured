# Contributing to Makabaka Engine

Thank you for your interest in contributing to Makabaka Engine! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Types of Contributions](#types-of-contributions)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guides](#style-guides)
- [Community](#community)

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/makabaka-engine.git`
3. Set up the development environment (see below)
4. Create a branch for your changes: `git checkout -b feature/your-feature`

## Types of Contributions

### Game Templates (Easiest)
Create new game templates that help users start projects quickly.

**Good for:** Game designers, GDScript beginners

See [docs/contributing/templates.md](docs/contributing/templates.md)

### Game Modules (Easy-Medium)
Create reusable game modules like player movement, inventory systems, or AI behaviors.

**Good for:** GDScript developers

See [docs/contributing/modules.md](docs/contributing/modules.md)

### Documentation (Easy)
Improve documentation, write tutorials, or translate to other languages.

**Good for:** Writers, educators, translators

### Bug Fixes (Medium)
Fix bugs in the core engine or addon.

**Good for:** Developers familiar with Godot/GDScript

### Features (Discuss First)
Add new features to the AI system or editor integration.

**Good for:** Experienced developers

Please open an issue to discuss major features before starting work.

## Development Setup

### Prerequisites

- Godot 4.x
- Bun 1.3+ (for OpenCode)
- Git

### Setup Steps

```bash
# Clone the repository
git clone https://github.com/makabaka-engine/makabaka-engine.git
cd makabaka-engine

# Install OpenCode dependencies
cd opencode
bun install

# Build OpenCode
bun run build
cd ..

# Open Godot project
cd godot
# Open with Godot editor
```

### Running Tests

```bash
# OpenCode tests
cd opencode
bun test

# Godot tests (if using GUT)
# Run from Godot editor
```

## Pull Request Process

1. **Create an issue first** for significant changes
2. **Fork and branch** from `main`
3. **Make your changes** following the style guides
4. **Test your changes** thoroughly
5. **Update documentation** if needed
6. **Submit a PR** with a clear description

### PR Checklist

- [ ] Code follows the style guide
- [ ] Tests pass (if applicable)
- [ ] Documentation updated
- [ ] Commit messages are clear
- [ ] PR description explains the changes

### Commit Message Format

```
<type>: <short description>

<longer description if needed>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Example:
```
feat: add slow tower module

Adds a new tower type that slows enemies in range.
Includes interface.json and tower_slow.gd.

Closes #123
```

## Style Guides

### GDScript Style Guide

Follow the [official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) with these additions:

```gdscript
# Use class_name for reusable classes
class_name MyModule
extends Node

## Documentation comment for the class

# Signals first
signal my_signal(value: int)

# Then exports
@export var my_property: int = 10

# Then public variables
var public_var: String = ""

# Then private variables (prefixed with _)
var _private_var: int = 0


func _ready() -> void:
    pass


## Public method with documentation
func public_method() -> void:
    pass


func _private_method() -> void:
    pass
```

### TypeScript Style Guide (OpenCode)

- Use TypeScript strict mode
- Prefer `const` over `let`
- Use meaningful variable names
- Add JSDoc comments for public APIs

### JSON Style Guide

- 2-space indentation
- Use `snake_case` for keys
- Include descriptions for configuration options

## Community

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and ideas
- **Discord**: Real-time chat (coming soon)

## Recognition

Contributors are recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project README (major contributors)

## Questions?

Feel free to open an issue or start a discussion if you have questions about contributing!
