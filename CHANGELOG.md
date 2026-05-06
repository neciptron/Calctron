# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Security Fixes
- Factorial overflow now returns proper error instead of silent corruption
- Buffer corruption in `getDisplayText` fixed with separate display_op buffer
- Button dimension clamping prevents negative width on resize
- Factorial upper bound (170) prevents denial of service

### Bug Fixes
- Thread argument use-after-scope race condition fixed in `factorialParallel`
- `math.log` API compatibility corrected to `math.ln` for natural logarithm
- Button array overflow fixed (`[25]` → `[40]`) in scientific mode
- `R` key conflict resolved: now theme toggle only (sqrt moved to `V`)
- `getDisplayText` now correctly returns operator-prefixed display
- Number key mapping uses explicit enum values instead of `@enumFromInt(48+i)`
- Dead variable removed from `parallel.zig`
- `reciprocal` label fixed to show correct operation (was mapped to negate)
- Display text capacity bug fixed (`current_input.len` → null-terminated length)

### Features
- Fuzz testing suite (`src/fuzz.zig`) with 5 randomized test scenarios
- Icon generation from SVG at 8 sizes (16px–1024px) via `zig build icon`
- Code quality build steps: `fmt`, `fmt-check`, `ast-check`
- Pre-commit hook for automated formatting, AST, and test checks
- Adaptive precision formatting for display values

### Documentation
- Added comprehensive security audit (STRIDE + OWASP)
- Added bug hunt report with findings and fixes
- Added design iteration log for logo development
- Updated README.md with full keyboard shortcuts and build commands
- Added CONTRIBUTING.md with development workflow
- Added CHANGELOG.md
- Added LICENSE (MIT)

## [0.1.0] - 2026-05-06

### Added
- Scientific calculator with sin, cos, tan, sqrt, log, ln, power, factorial
- Light/dark theme toggle (R key)
- 5-language support: EN, TR, ES, FR, DE
- Cross-platform build: Windows, macOS, Linux
- Parallel factorial computation using `std.Thread`
- Installation script (`install.sh`)
- Keyboard and mouse controls
- Help overlay (H key)
- Status bar with language and theme indicator
