# Attack Surface Map

## Entry Points

### Keyboard Input (main.zig:30-71, calculator.zig:55-146)
| Key | Handler | Risk Category |
|-----|---------|---------------|
| 0-9, KP_0-9 | appendDigit() | Buffer overflow if unchecked, integer conversion |
| ., KP_DECIMAL | appendDot() | Format manipulation |
| =, KP_ENTER | evaluate() | Division by zero, overflow |
| +, -, *, / | setOperator() | Chained operation overflow |
| Backspace | backspace() | Buffer underflow |
| Esc, C | reset() | State manipulation |
| S, O, T, V | applyUnary(sin/cos/tan/sqrt) | Domain errors, NaN propagation |
| H | show_help | UI state toggle |
| R | toggle theme | UI state toggle |
| 1-5 | switch language | State toggle |

### Mouse Input (ui.zig:46-92)
| Component | Handler | Risk Category |
|-----------|---------|---------------|
| Button click | handleButtonAction() | Same risks as keyboard |
| Mouse position | getMousePosition() | Coordinate validation for hover |
| Window resize | window_resizable flag | Layout recalculation overflow |

### Thread Operations (parallel.zig:3-54)
| Operation | Risk Category |
|-----------|---------------|
| factorialParallel() spawn | Thread argument lifetime, race condition |
| factorialParallel() join | Thread synchronization, partial accumulation |
| factorial overflow | Return value truncation (u128→u64) |

## Data Flows

```
Keyboard/Mouse Input
    │
    ▼
main.zig event loop ──► calculator.handleInput()
                            │
    ┌───────────────────────┼───────────────────────┐
    ▼                       ▼                       ▼
appendDigit()          setOperator()            applyUnary()
    │                       │                       │
    ▼                       ▼                       ▼
current_input[64]     pending_op/value        math.sin/cos/tan/sqrt
    │                       │                       │
    │                       ▼                       ▼
    │                  compute()              factorialParallel()
    │                       │                       │
    │                       ▼                       ▼
    │               pending_op chain          std.Thread.spawn()
    │                       │                       │
    ▼                       ▼                       ▼
getDisplayText() ◄─── result/formatResult() ◄── merge partials
    │
    ▼
ui.drawDisplay() → raylib text rendering
```

## Abuse Paths

### AP-1: Buffer Overflow via Display Corruption
- **Path:** setOperator() → formatResult() → getDisplayText() → display buffer modification
- **Risk:** getDisplayText() appends operator string to display buffer in-place (calculator.zig:334-337), potentially corrupting adjacent memory if length calculation is off
- **Severity:** HIGH

### AP-2: Thread Argument Use-After-Scope (FIXED)
- **Path:** factorialParallel() → Thread.spawn with args_array references
- **Risk:** Thread arguments must outlive spawned threads; fixed by using `args_array` outside loop
- **Residual:** Partials array is shared across threads with no synchronization; relies on non-overlapping index writes
- **Severity:** MEDIUM (residual after fix)

### AP-3: Integer Overflow in Factorial
- **Path:** applyUnary("fact") → factorialParallel() → u64 return
- **Risk:** Factorial grows extremely fast; 21! exceeds u64.max. Code caps at maxInt(u64) but this silently corrupts calculations
- **Severity:** HIGH

### AP-4: Rapid Input Flooding
- **Path:** main loop polls keyboard every frame → handleInput() processes each keypress
- **Risk:** Rapid repeated keypresses can overflow buffers before guards check length (e.g., appendDigit checks len >= 63 but race with frame timing)
- **Severity:** LOW

### AP-5: NaN/Inf Propagation
- **Path:** applyUnary() → math operations → getDisplayText()
- **Risk:** Some math paths don't fully guard against NaN/Inf; code checks at line 289 but only after all ops complete
- **Severity:** MEDIUM

### AP-6: Memory Leak on OOM
- **Path:** Calculator.init() → allocator.alloc (line 28-29)
- **Risk:** If first alloc succeeds and second fails, first buffer is leaked (no cleanup before @panic)
- **Severity:** LOW

### AP-7: Supply Chain Risk via raylib
- **Path:** build.zig → b.dependency("raylib")
- **Risk:** No version pinning or integrity verification visible; dependency fetched from build.zig.zon
- **Severity:** MEDIUM

### AP-8: Missing Input Validation on Keyboard Scancodes
- **Path:** calculator.zig:64-85 — number key mapping assumes keyboard enum values match expected order
- **Risk:** If raylib.KeyboardKey enum changes, wrong digits could be appended
- **Severity:** LOW
