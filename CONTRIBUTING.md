# Contributing

Thank you for your interest in contributing to Calctron!

## Getting Started

1. Ensure you have Zig >= 0.16.0 installed
2. Clone the repository
3. Run `./install.sh` to set up dependencies
4. Build and test: `zig build && zig build test`

## Development Workflow

```bash
# Build
zig build

# Run
zig build run

# Run tests
zig build test

# Run fuzz tests
zig build fuzz

# Format code
zig build fmt

# Check formatting
zig build fmt-check

# Check AST validity
zig build ast-check

# Generate platform icons
zig build icon

# Cross-compile
zig build build-windows   # Windows (x86_64)
zig build build-macos     # macOS (aarch64)
zig build build-linux-native  # Linux (x86_64, static)
```

## Pull Requests

- Create a feature branch from `main`
- Keep PRs focused on a single change
- Update CHANGELOG.md under `[Unreleased]`
- Run tests before submitting
- Follow Zig naming conventions (`snake_case` for functions/variables, `PascalCase` for types)

## Code Style

- Run `zig fmt` before committing
- Keep functions under 50 lines where possible
- Document public API functions with doc comments
- No `@panic` in library code — use error unions

## Reporting Issues

Include:
- OS and architecture
- Zig version
- Steps to reproduce
- Expected vs actual behavior

## Security

If you discover a security issue, please report privately rather than opening a public issue.
See the [security audit report](security/) for details on past findings.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
