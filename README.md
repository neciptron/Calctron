# Calctron

A cross-platform scientific calculator built with Zig and raylib. Features light/dark themes, 5-language support, and parallel computation.

![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)
![Zig](https://img.shields.io/badge/zig-0.16.0-orange.svg)
![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![Security](https://img.shields.io/badge/security-audited-green)

## Features

- **Scientific Mode**: sin, cos, tan, sqrt, log, ln, power, factorial, constants (π, e)
- **Basic Mode**: Standard arithmetic operations (+, -, ×, ÷)
- **Light/Dark Themes**: Press `R` to toggle
- **5 Languages**: English, Turkish, Spanish, French, German (press `1`-`5`)
- **Cross-Platform**: Windows, macOS, Linux with native raylib GUI
- **Parallel Computation**: Zig `std.Thread` for factorial calculations
- **Security Audited**: Full STRIDE + OWASP audit, all Critical/High findings resolved

## Requirements

- Zig >= 0.16.0
- raylib system libraries (Linux only, installed automatically via `install.sh`)
- C compiler for raylib build (gcc/clang)

## Quick Start

```bash
# Clone and install
git clone https://github.com/calctron-org/calctron.git
cd calctron
chmod +x install.sh
./install.sh

# Build
zig build

# Run
zig build run

# Run tests
zig build test
```

## Manual Installation

### 1. Install Zig

```bash
# Linux x86_64
wget https://ziglang.org/download/0.16.0/zig-linux-x86_64-0.16.0.tar.xz
tar -xf zig-linux-x86_64-0.16.0.tar.xz
export PATH="$(pwd)/zig-linux-x86_64-0.16.0:$PATH"

# macOS Apple Silicon
wget https://ziglang.org/download/0.16.0/zig-macos-aarch64-0.16.0.tar.xz
tar -xf zig-macos-aarch64-0.16.0.tar.xz
export PATH="$(pwd)/zig-macos-aarch64-0.16.0:$PATH"
```

Or use your package manager:
```bash
# Homebrew (macOS/Linux)
brew install zig

# Debian/Ubuntu (via snap)
sudo snap install zig --classic --beta
```

### 2. Install raylib Dependencies

```bash
# Debian/Ubuntu
sudo apt-get install libgl1-mesa-dev libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libxext-dev

# Fedora
sudo dnf install mesa-libGL-devel libX11-devel libXrandr-devel libXinerama-devel libXcursor-devel libXi-devel libXext-devel

# macOS - no extra dependencies needed
```

### 3. Fetch Dependencies and Build

```bash
zig fetch --save "https://github.com/raylib-zig/raylib-zig/archive/refs/tags/v5.6-dev.tar.gz"
zig build
zig build run
```

## Keyboard Controls

| Key | Action |
|-----|--------|
| `0-9` | Digits |
| `+`, `-`, `*`, `/` | Operators |
| `Enter` | Equals |
| `C` / `Esc` | Clear |
| `Backspace` | Delete last digit |
| `R` | Toggle theme |
| `H` | Toggle help |
| `1-5` | Switch language (EN/TR/ES/FR/DE) |
| `S` | Sin |
| `O` | Cos |
| `T` | Tan |
| `V` | Square root |
| `L` | Log (base 10) |
| `N` | Natural log (ln) |
| `Q` | Square (x²) |
| `B` | Cube (x³) |
| `W` | Power (xʸ) |
| `P` | Pi (π) |
| `A` | Euler's number (e) |
| `F` | Factorial (n!) |
| `U` | Percent (%) |
| `I` | Inverse/Negate (±) |
| `.` | Decimal point |

## Mouse Controls

Click calculator buttons on screen. Hover highlights buttons. Works with both basic and scientific layouts.

## Build Commands

| Command | Description |
|---------|-------------|
| `zig build` | Build and install |
| `zig build run` | Run the calculator |
| `zig build test` | Run unit tests |
| `zig build fuzz` | Run fuzz tests |
| `zig build fmt` | Format code |
| `zig build fmt-check` | Check formatting |
| `zig build ast-check` | Check AST validity |
| `zig build icon` | Generate platform icons |
| `zig build build-windows` | Cross-compile for Windows |
| `zig build build-macos` | Cross-compile for macOS |
| `zig build build-linux-native` | Cross-compile for Linux (static) |

## Project Structure

```
calctron/
├── build.zig                  # Build configuration and cross-compile targets
├── build.zig.zon              # Package manifest (v0.1.0)
├── install.sh                 # Automated installation script
├── README.md                  # This file
├── LICENSE                    # MIT License
├── CHANGELOG.md               # Version history
├── CONTRIBUTING.md            # Contribution guidelines
├── scripts/
│   └── generate_icons.sh      # SVG to PNG icon generator
├── logo/
│   ├── calctron-logo.svg      # Application logo (SVG)
│   └── design-results.tsv     # Logo design iteration log
├── src/
│   ├── main.zig               # Entry point, raylib window and event loop
│   ├── calculator.zig         # Core calculator engine with math operations
│   ├── parallel.zig           # Parallel factorial computation using std.Thread
│   ├── fuzz.zig               # Fuzz testing for edge cases
│   ├── i18n.zig               # Internationalization (EN, TR, ES, FR, DE)
│   ├── theme.zig              # Light and dark theme color palettes
│   └── ui.zig                 # Button rendering, layout, and input handling
├── security/                  # Security audit reports (STRIDE + OWASP)
└── debug/                     # Bug hunt findings and fixes
```

## Security

This project underwent a comprehensive STRIDE + OWASP security audit. All Critical and High findings are resolved.

| Metric | Status |
|--------|--------|
| Critical | ✅ 0 (1 found, fixed) |
| High | ✅ 0 (3 found, fixed) |
| Medium | ⚠️ 5 remaining (backlog) |
| OWASP coverage | 6/8 applicable categories |
| STRIDE coverage | 5/6 categories |

Full audit report: [security/](security/)

## Troubleshooting

### Build fails with "dependency not found"
Run `./install.sh` or manually fetch raylib-zig:
```bash
zig fetch --save "https://github.com/raylib-zig/raylib-zig/archive/refs/tags/v5.6-dev.tar.gz"
```

### Zig not found
Download from [ziglang.org/download](https://ziglang.org/download/) and add to PATH.

### Calculator shows "OVERFLOW" for factorial
Factorial is capped at 170! — larger values exceed f64 precision. This is intentional.

### "Division by zero" or "DOMAIN" error
Expected for invalid operations (÷0, √negative, log≤0). Press `C` or `Esc` to clear.

### Window too small / buttons overlap
Minimum button width is enforced (20px). Resize wider for better layout.

## Cross-Platform Compilation

Zig can cross-compile for all three platforms from any host:

```bash
# Build for Windows (from Linux/macOS)
zig build -Dtarget=x86_64-windows

# Build for macOS (from Linux/Windows)
zig build -Dtarget=aarch64-macos

# Build for Linux (from any platform)
zig build -Dtarget=x86_64-linux
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow, code style, and pull request guidelines.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

MIT — see [LICENSE](LICENSE) for details.
