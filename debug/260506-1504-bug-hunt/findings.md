# Debug Findings — Calctron Bug Hunt

**Date:** 2026-05-06
**Scope:** Entire codebase (6 files)
**Technique:** Static analysis / direct inspection
**Total Bugs Found:** 7 (3 Critical, 2 High, 1 Medium, 1 Low)

---

## [CRITICAL] Thread Args Use-After-Scope Race Condition

- **Location:** `src/parallel.zig:28-32`
- **Hypothesis:** Stack-allocated `ThreadArgs` passed to `std.Thread.spawn` via pointer, but goes out of scope at end of for-loop iteration
- **Evidence:**
  ```zig
  for (0..num_threads) |i| {
      var args = ThreadArgs{ ... };          // stack-allocated in loop body
      threads[i] = std.Thread.spawn(.{}, compute, .{&args}); // pointer to stack
  }  // args goes out of scope here, but threads haven't been joined yet
  ```
- **Root cause:** `std.Thread.spawn` copies the argument tuple to heap, but the tuple contains a pointer (`&args`) to stack memory. When the loop iterates, the stack slot is reused, corrupting the data other threads are reading.
- **Impact:** Undefined behavior — threads may read corrupted start/end values, producing incorrect factorial results or crashes
- **Suggested fix:** Move `args` array outside the loop:
  ```zig
  var args_array: [4]ThreadArgs = undefined;
  for (0..num_threads) |i| {
      args_array[i] = ThreadArgs{ ... };
      threads[i] = std.Thread.spawn(.{}, compute, .{&args_array[i]});
  }
  ```

---

## [CRITICAL] `std.math.log` API Incorrect — Compile Error

- **Location:** `src/calculator.zig:260`
- **Hypothesis:** `math.log(val)` uses wrong API for natural logarithm
- **Evidence:** In Zig 0.14+, `std.math.log` signature is `log(comptime T: type, base: T, x: T) T`. Single-argument call will not compile.
- **Root cause:** Confusion between `std.math.log` (arbitrary base) and `std.math.ln` (natural log)
- **Impact:** Project will not compile
- **Suggested fix:** Change `math.log(val)` to `math.ln(val)`

---

## [CRITICAL] Button Array Too Small — Index Out of Bounds

- **Location:** `src/ui.zig:143`
- **Hypothesis:** `[25]Button` array cannot hold all buttons in scientific mode
- **Evidence:**
  - Scientific buttons: 3 rows × 5 cols = 15 buttons (idx 0-14)
  - Basic buttons: 20 buttons (idx 15-34)
  - Array size: 25 → overflow at idx 25
- **Root cause:** Array sized for basic mode only (20 buttons) + small margin, but scientific mode adds 15 more
- **Impact:** Runtime crash or memory corruption when scientific mode is enabled (default)
- **Suggested fix:** Change to `[40]Button` or use `std.ArrayList(Button)`

---

## [HIGH] R Key Theme Toggle — Dead Code

- **Location:** `src/main.zig:34`
- **Hypothesis:** R key for theme toggle is never reached
- **Evidence:** Main loop calls `calculator.handleInput()` (line 31) before checking `isKeyPressed(.keyboard_r)` (line 34). `handleInput()` at `calculator.zig:140` handles R key for sqrt and returns early, preventing the theme toggle from ever executing.
- **Root cause:** Input handling priority conflict — calculator consumes R before main loop can check it
- **Impact:** Users cannot toggle theme with R key. Must use other mechanism.
- **Suggested fix:** Change sqrt shortcut to a different key (e.g., `v` for √) or handle theme toggle inside `handleInput`

---

## [HIGH] `getDisplayText` Returns Wrong Value When Operator Pending

- **Location:** `src/calculator.zig:332-338`
- **Hypothesis:** Operator suffix never shown to user
- **Evidence:**
  ```zig
  const buf = std.fmt.allocPrint(self.allocator, "{s}{s}", .{
      self.display, op_str,
  }) catch return self.display;
  defer self.allocator.free(buf);
  // Return static display for simplicity
  return self.display;  // ← Should be: return buf
  ```
- **Root cause:** Code was written but never finished — comment says "for simplicity" but the allocated string is immediately freed and the wrong value returned
- **Impact:** When user presses an operator, the display does NOT show the operator symbol (e.g., "5 + "). Shows only the operand value.
- **Suggested fix:** Return `buf` instead of `self.display`, and remove the `defer free` (caller must manage lifetime), or use a fixed-size buffer to avoid allocation

---

## [MEDIUM] Number Key Enum Mapping Fragile

- **Location:** `src/calculator.zig:66`
- **Hypothesis:** `@enumFromInt(48+i)` assumes raylib KeyboardKey enum values match ASCII codes
- **Evidence:** Raylib C defines `KEY_ZERO = 48` through `KEY_NINE = 57`, matching ASCII. But raylib-zig may use different enum representation.
- **Root cause:** Hardcoded dependency on enum implementation details rather than using named variants (`.keyboard_0` through `.keyboard_9`)
- **Impact:** If raylib-zig enum values differ, number keys silently don't respond — primary input broken
- **Suggested fix:** Use named enum variants or verify mapping at compile time:
  ```zig
  const digit_keys = [_]raylib.KeyboardKey{
      .keyboard_0, .keyboard_1, .keyboard_2, .keyboard_3, .keyboard_4,
      .keyboard_5, .keyboard_6, .keyboard_7, .keyboard_8, .keyboard_9,
  };
  ```

---

## [LOW] Dead Variable — Unused `result` in `factorialParallel`

- **Location:** `src/parallel.zig:9`
- **Hypothesis:** `var result: u64 = 1` is never read
- **Evidence:** Variable declared at line 9, never referenced again in the function
- **Root cause:** Leftover from initial implementation before parallel logic was added
- **Impact:** Zig compiler treats unused local variables as errors — will prevent compilation
- **Suggested fix:** Remove line 9

---

## Eliminated Hypotheses

| # | Hypothesis | Result | Reason |
|---|-----------|--------|--------|
| 9 | `setOperator` null-byte clear broken | Disproven | `current_input[0] = 0` correctly clears C-string buffer via `std.mem.len` |
| 10 | `evaluate` error handling buggy | Disproven | Error path properly gates result update and preserves state |
| 11 | `reset` doesn't clear all state | Disproven | `reset()` clears all 7 fields including `has_result`, `pending_op`, `error_msg` |
