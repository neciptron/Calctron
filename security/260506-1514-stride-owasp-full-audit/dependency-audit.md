# Dependency Audit

## Dependencies

| Dependency | Version | Type | Status |
|------------|---------|------|--------|
| raylib | Pinned in build.zig.zon | C library (graphics/input) | ✅ No known CVEs in current usage |
| Zig stdlib | 0.14.x (host) | Language runtime | ✅ Current |

## Analysis

### raylib
- **Type:** C library for graphics, input, and audio
- **Usage:** Window management, drawing, keyboard/mouse input
- **Attack Surface:** Font rendering, image loading, audio playback
- **Risk Assessment:** **LOW** — The calculator only uses:
  - Window creation and event loop
  - Rectangle drawing and text rendering
  - Keyboard and mouse input polling
  - Screen dimension queries
  - Does NOT load external fonts, images, or audio files
- **Known CVEs:** No CVEs affecting the specific raylib functions used by this application
- **Supply Chain Risk:** Dependency pinned in build.zig.zon; integrity verified by Zig's package manager

### Zig Standard Library
- **Type:** Language standard library
- **Usage:** Memory allocation, math functions, threading, formatting
- **Risk Assessment:** **LOW** — Official Zig stdlib, no third-party components
- **Notable:** Uses `std.heap.GeneralPurposeAllocator` with leak detection (disabled by discarding return value)

## Conclusion

No known vulnerabilities in dependencies. The offline desktop nature of the application significantly reduces the attack surface from third-party libraries.
