# STRIDE Threat Model

## Asset Inventory

| # | Asset | Type | Priority | Location |
|---|-------|------|----------|----------|
| 1 | Calculator state (result, display, pending_op) | Data store | High | calculator.zig:5-23 |
| 2 | Allocated display/current_input buffers | Memory | Critical | calculator.zig:28-29 |
| 3 | Parallel thread arguments & partials | Concurrency state | Critical | parallel.zig:12-14 |
| 4 | Thread join results | Concurrency state | Critical | parallel.zig:42-48 |
| 5 | Raylib window/input events | External input | High | main.zig:30-71 |
| 6 | Button definitions (buildButtons) | Memory | Medium | ui.zig:141-243 |
| 7 | i18n translation strings | Static data | Low | i18n.zig:64-302 |
| 8 | Theme color palettes | Static data | Low | theme.zig:23-61 |
| 9 | GeneralPurposeAllocator | Resource manager | High | main.zig:13-14 |
| 10 | Build dependencies (raylib) | Supply chain | Medium | build.zig:7-11 |

## Trust Boundaries

```
┌────────────────────────────────────────────────────────────┐
│  User Input (keyboard/mouse)                               │
│       │                                                    │
│       ▼                                                    │
│  ┌─────────────────┐    ┌──────────────────────────────┐  │
│  │  main.zig loop  │───►│  calculator.handleInput()    │  │
│  │  (untrusted)    │    │  (no validation on input len) │  │
│  └─────────────────┘    └──────────┬───────────────────┘  │
│                                    │                       │
│       ┌────────────────────────────┤                       │
│       ▼                            ▼                       │
│  ┌─────────────────┐    ┌──────────────────────────────┐  │
│  │  ui.drawButtons │    │  applyUnary/compute          │  │
│  │  (click handler)│    │  (math ops, domain checks)   │  │
│  └─────────────────┘    └──────────┬───────────────────┘  │
│                                    │                       │
│       ┌────────────────────────────┤                       │
│       ▼                            ▼                       │
│  ┌─────────────────┐    ┌──────────────────────────────┐  │
│  │  Display buffer │    │  factorialParallel()          │  │
│  │  (64-byte alloc)│    │  (thread spawn, join, merge) │  │
│  └─────────────────┘    └──────────────────────────────┘  │
│                                                            │
│  GeneralPurposeAllocator ──► Memory safety boundary        │
│  Thread spawn/join       ──► Concurrency safety boundary   │
└────────────────────────────────────────────────────────────┘
```

### Boundary Descriptions

| Boundary | From | To | Risk |
|----------|------|----|------|
| B1: Keyboard/Mouse → main loop | External untrusted input | Application state | Input injection, rapid event flooding |
| B2: main loop → handleInput() | Event dispatcher | Calculator state | Missing input validation, overflow |
| B3: handleInput() → applyUnary() | User-triggered operation | Math functions | Domain errors, overflow, NaN |
| B4: applyUnary("fact") → factorialParallel() | Math dispatch | Thread spawning | Thread argument lifetime, overflow |
| B5: main → display buffer | Computed results | 64-byte allocated buffer | Buffer overflow, string corruption |
| B6: build dependency → raylib | External C library | Native binary | Supply chain, ABI incompatibility |

## STRIDE Analysis

| # | Asset | Boundary | S | T | R | I | D | E | Risk |
|---|-------|----------|---|---|---|---|---|---|------|
| 1 | Display buffer | B5 | - | ✓ | - | ✓ | ✓ | - | High |
| 2 | current_input buffer | B2,B5 | - | ✓ | - | ✓ | ✓ | - | High |
| 3 | Thread args (parallel) | B4 | - | ✓ | - | - | ✓ | - | Critical |
| 4 | Thread partials | B4 | - | ✓ | - | - | ✓ | - | Critical |
| 5 | Calculator state | B2,B3 | - | ✓ | - | ✓ | - | ✓ | High |
| 6 | Factorial overflow | B4 | - | ✓ | - | ✓ | ✓ | - | High |
| 7 | Unary function dispatch | B3 | - | ✓ | - | ✓ | - | ✓ | Medium |
| 8 | Memory allocator | B1-B6 | - | - | - | - | ✓ | - | Medium |
| 9 | Raylib dependency | B6 | ✓ | ✓ | - | - | - | - | Medium |
| 10 | Build configuration | B6 | ✓ | ✓ | - | - | - | - | Low |
