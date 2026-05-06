# Security Findings

## Summary

**Total Findings:** 14 (1 Critical, 3 High, 5 Medium, 4 Low, 1 Info)
**Clean Checks:** 16
**Fixed:** 4 (1 Critical, 3 High)

---

### [CRITICAL] ~~Finding 1: Factorial Denial of Service — No Upper Bound~~ ✅ Fixed

- **Status:** Fixed
- **OWASP:** A04 — Insecure Design
- **STRIDE:** Denial of Service
- **Location:** `calculator.zig:285-298`, `parallel.zig:3-55`
- **Confidence:** Confirmed
- **Fix Applied:** Added upper bound check (`int_val > 170`) in calculator.zig; changed `factorialParallel` to return `!u64` with `error.Overflow` on overflow; caller handles error and displays "OVERFLOW"
- **Description:** The factorial function accepts any non-negative integer that fits in u64 (up to 18,446,744,073,709,551,615). Computing factorial of a large value like 1,000,000 would require millions of multiplications, effectively hanging the application. For values exceeding i64.max, `@intFromFloat` triggers undefined behavior.
- **Attack Scenario:**
  1. User enters "1000000" in the calculator
  2. User presses the factorial button (n!)
  3. `applyUnary("fact")` at calculator.zig:278 passes the integer check
  4. `factorialParallel(1000000)` spawns 4 threads, each computing ~250,000 multiplications
  5. Application becomes unresponsive for an extended period (or indefinitely for larger inputs)
  6. For input > 9.2e18, `@intFromFloat(val)` as i64 is undefined behavior — possible crash
- **Code Evidence:**
  ```zig
  // calculator.zig:278-282 — no upper bound check
  if (val < 0 or val != @as(f64, @floatFromInt(@as(i64, @intFromFloat(val))))) {
      self.error_msg = "domain";
      return;
  }
  result = @as(f64, @floatFromInt(parallel.factorialParallel(
      @as(u64, @intFromFloat(val)))));  // val can be up to u64.max
  ```
- **Mitigation:**
  ```zig
  // Add upper bound check before calling factorialParallel
  const int_val: u64 = @intFromFloat(val);
  if (int_val > 170) {  // 171! overflows f64; cap at reasonable limit
      self.error_msg = "overflow";
      return;
  }
  result = @as(f64, @floatFromInt(parallel.factorialParallel(int_val)));
  ```
- **References:** CWE-400 (Uncontrolled Resource Consumption), CWE-674 (Uncontrolled Recursion)

---

### [HIGH] ~~Finding 2: getDisplayText Progressive Buffer Corruption~~ ✅ Fixed

- **Status:** Fixed
- **OWASP:** A03 — Injection
- **STRIDE:** Tampering
- **Location:** `calculator.zig:343-358`
- **Confidence:** Confirmed
- **Fix Applied:** Added `display_op` buffer to Calculator struct; `getDisplayText()` now copies display + op_str to display_op instead of mutating display in-place
- **Description:** `getDisplayText()` mutates `self.display` in-place by appending the operator string. Since this method is called every frame (60 FPS) from `ui.drawDisplay()`, the operator string accumulates repeatedly: "5 + " → "5 +  + " → "5 +  +  + " etc. Eventually the buffer fills (64 bytes) and the guard prevents further writes, leaving a corrupted display.
- **Attack Scenario:**
  1. User enters "5", presses "+"
  2. `setDisplayText()` called 60 times per second
  3. Each call appends " + " (3 bytes) to display
  4. After ~20 frames (0.33 seconds), display = "5 +  +  +  +  +  +  +  +  + "
  5. After 64 bytes, the `< 63` guard stops appending, showing garbage
- **Code Evidence:**
  ```zig
  // calculator.zig:326-339 — getter mutates state
  pub fn getDisplayText(self: *Calculator) []const u8 {
      // ...
      if (self.pending_op) |_| {
          const op_str = switch (self.pending_op.?) {
              .add => " + ",  // 3 bytes
              // ...
          };
          const cur_len = std.mem.len(self.display);
          if (cur_len + op_str.len < 63) {
              @memcpy(self.display[cur_len .. cur_len + op_str.len], op_str);
              self.display[cur_len + op_str.len] = 0;
          }
          return self.display;
      }
  }
  ```
- **Mitigation:** Use a temporary buffer or format the display text without mutating state:
  ```zig
  pub fn getDisplayText(self: *Calculator) []const u8 {
      // ...
      if (self.pending_op) |_| {
          const op_str = switch (self.pending_op.?) {
              .add => " + ",
              .sub => " - ",
              .mul => " × ",
              .div => " ÷ ",
              .pow => " ^ ",
          };
          // Store formatted text in a separate display_op buffer
          const cur_len = std.mem.len(self.display);
          if (cur_len + op_str.len < 63) {
              @memcpy(self.display_op[cur_len .. cur_len + op_str.len], op_str);
              @memcpy(self.display_op[0..cur_len], self.display[0..cur_len]);
              self.display_op[cur_len + op_str.len] = 0;
              return self.display_op;
          }
          return self.display;
      }
  }
  ```
- **References:** CWE-682 (Incorrect Calculation)

---

### [HIGH] ~~Finding 3: Negative Button Dimensions on Extreme Window Resize~~ ✅ Fixed

- **Status:** Fixed
- **OWASP:** A04 — Insecure Design
- **STRIDE:** Denial of Service
- **Location:** `ui.zig:43-44`
- **Confidence:** Likely
- **Fix Applied:** Added `@max(btn_w_raw, 20.0)` clamp to prevent negative button widths
- **Description:** When the window is resized very narrow (e.g., < 100px), the button width calculation `btn_w = (sw - margin*(cols+1) - gap*(cols-1)) / cols` produces a negative value. This negative width is passed to `raylib.drawRectangleRounded()` which invokes C library code with invalid dimensions, potentially causing undefined behavior or crash.
- **Attack Scenario:**
  1. User resizes calculator window to very small width (50px)
  2. `btn_w` becomes negative: (50 - 10*5 - 6*3) / 4 = (50 - 68) / 4 = -4.5
  3. `drawRectangleRounded` called with width = -4.5
  4. C library processes invalid dimensions — undefined behavior
- **Code Evidence:**
  ```zig
  // ui.zig:43 — no minimum width check
  const btn_w = (sw - margin * @as(f32, @floatFromInt(cols + 1))
      - gap * @as(f32, @floatFromInt(cols - 1))) / @as(f32, @floatFromInt(cols));
  ```
- **Mitigation:**
  ```zig
  const btn_w_calc = (sw - margin * @as(f32, @floatFromInt(cols + 1))
      - gap * @as(f32, @floatFromInt(cols - 1))) / @as(f32, @floatFromInt(cols));
  const btn_w = @max(btn_w_calc, 20.0);  // Minimum 20px button width
  ```
- **References:** CWE-20 (Improper Input Validation)

---

### [HIGH] ~~Finding 4: Silent Factorial Overflow Corruption~~ ✅ Fixed

- **Status:** Fixed
- **OWASP:** A04 — Insecure Design
- **STRIDE:** Tampering
- **Location:** `parallel.zig:3-55`, `calculator.zig:285-298`
- **Confidence:** Confirmed
- **Fix Applied:** Changed `factorialParallel` return type from `u64` to `!u64`; returns `error.Overflow` instead of `maxInt(u64)`; calculator catches error and displays "OVERFLOW"; added test for overflow case
- **Description:** When factorial computation overflows u64, the function silently returns `std.math.maxInt(u64)` (18446744073709551615) without signaling an error to the user. The calculator displays this incorrect value as if it were the correct result. 21! already exceeds u64.max.
- **Attack Scenario:**
  1. User enters "25", presses factorial (n!)
  2. `factorialParallel(25)` detects overflow at line 51
  3. Returns `std.math.maxInt(u64)` = 18446744073709551615
  4. User sees this number displayed — actual 25! = 15,511,210,043,330,985,984,000,000
  5. User receives silently wrong answer with no indication of overflow
- **Code Evidence:**
  ```zig
  // parallel.zig:51-54
  if (final > std.math.maxInt(u64)) {
      return std.math.maxInt(u64);  // Silent corruption
  }
  // parallel.zig:61
  result = @mulWithOverflow(result, i) catch return std.math.maxInt(u64);
  ```
- **Mitigation:**
  ```zig
  // Return an error union or Option type
  pub fn factorialParallel(n: u64) !u64 {
      // ... existing code ...
      if (final > std.math.maxInt(u64)) {
          return error.Overflow;
      }
      return @intCast(final);
  }
  // In calculator.zig:
  const fact_result = parallel.factorialParallel(int_val) catch {
      self.error_msg = "overflow";
      return;
  };
  ```
- **References:** CWE-190 (Integer Overflow or Wraparound)

---

### [MEDIUM] Finding 5: Thread Data Race on Weakly-Ordered Architectures

- **OWASP:** A08 — Software and Data Integrity Failures
- **STRIDE:** Tampering
- **Location:** `parallel.zig:13,25,35`
- **Confidence:** Likely
- **Description:** The `partials` array is written by multiple threads without synchronization. While each thread writes to a different index (disjoint memory), Zig's memory model doesn't guarantee visibility of writes across threads without atomics. On x86 (strong memory ordering) this works, but on ARM/RISC-V (weak memory ordering) a thread's write to `partials[i]` may not be visible to the main thread after `join()`.
- **Mitigation:** Use `std.atomic.Value(u128)` for partials or add `std.atomic.order.release`/`acquire` fences.
- **References:** CWE-362 (Concurrent Execution Using Shared Resource)

---

### [MEDIUM] Finding 6: NaN/Inf Propagation Through Binary Operations

- **OWASP:** A04 — Insecure Design
- **STRIDE:** Information Disclosure
- **Location:** `calculator.zig:216-230`
- **Confidence:** Confirmed
- **Description:** The `compute()` function for binary operations (add, sub, mul, div, pow) does not check for NaN or Inf results. If a previous unary operation produced NaN/Inf and the result was stored, chained binary operations will propagate the corrupted value.
- **Code Evidence:**
  ```zig
  // calculator.zig:216-230 — no NaN/Inf check after binary ops
  fn compute(self: *Calculator, op: Calculator.Operator, a: f64, b: f64) f64 {
      return switch (op) {
          .add => a + b,   // NaN + x = NaN
          .sub => a - b,
          .mul => a * b,
          // ...
      };
  }
  ```
- **Mitigation:** Add NaN/Inf check in `compute()` before returning.

---

### [MEDIUM] Finding 7: Chained Operator NaN Propagation

- **OWASP:** A04 — Insecure Design
- **STRIDE:** Tampering
- **Location:** `calculator.zig:182`
- **Confidence:** Confirmed
- **Description:** In `setOperator()`, when chaining operators, `compute()` result is stored in `pending_value` without NaN/Inf validation. A user who triggers a domain error then chains another operation will have NaN silently propagated.
- **Mitigation:** Validate result of `compute()` in `setOperator()` before storing.

---

### [MEDIUM] Finding 8: Floating Point Precision Loss in formatResult

- **OWASP:** A02 — Cryptographic Failures
- **STRIDE:** Tampering
- **Location:** `calculator.zig:310`
- **Confidence:** Likely
- **Description:** The check `val == @as(f64, @floatFromInt(@as(i64, @intFromFloat(val))))` loses precision for floats > 2^53 and triggers undefined behavior for values outside i64 range (-9.2e18 to 9.2e18).
- **Mitigation:** Use `@as(f64, @floatFromInt(@as(u64, @intFromFloat(@abs(val)))))` with range check first.

---

### [MEDIUM] Finding 9: Calculator State Inconsistency After Errors

- **OWASP:** A04 — Insecure Design
- **STRIDE:** Tampering
- **Location:** `calculator.zig:278-282`
- **Confidence:** Confirmed
- **Description:** No upper bound on factorial input means the function accepts values up to u64.max. For very large values, the computation hangs. Additionally, `@intFromFloat` for floats exceeding i64.max is undefined behavior.
- **Mitigation:** Add `if (val > 170)` upper bound check (171! overflows f64).

---

### [LOW] Finding 10: Memory Leak on Partial OOM

- **OWASP:** A05 — Security Misconfiguration
- **STRIDE:** Denial of Service
- **Location:** `calculator.zig:28-29`
- **Confidence:** Confirmed
- **Description:** If `display` allocation succeeds but `current_input` fails, the display buffer is leaked before `@panic("OOM")` terminates the process.
- **Mitigation:** Use defer cleanup or allocate both before assigning.

---

### [LOW] Finding 11: Silent Result Truncation

- **OWASP:** A04 — Insecure Design
- **STRIDE:** Information Disclosure
- **Location:** `calculator.zig:311,313`
- **Confidence:** Confirmed
- **Description:** `formatResult` uses fixedBufferStream which silently truncates long results. User sees incomplete number with no indication.
- **Mitigation:** Check writer return value and set error_msg on truncation.

---

### [LOW] Finding 12: Leak Detection Disabled

- **OWASP:** A09 — Security Logging and Monitoring Failures
- **STRIDE:** Repudiation
- **Location:** `main.zig:14`
- **Confidence:** Confirmed
- **Description:** `defer _ = gpa.deinit()` discards the leak detection result, suppressing reports of memory leaks in debug mode.
- **Mitigation:** Use `defer if (gpa.deinit() == .leak) std.log.err("Memory leak detected", .{});`

---

### [LOW] Finding 13: evaluate() Silently Discards Failed Operations

- **OWASP:** A05 — Security Misconfiguration
- **STRIDE:** Denial of Service
- **Location:** `calculator.zig:195-207`
- **Confidence:** Confirmed
- **Description:** On compute error, `pending_op` is cleared but error_msg is set. The failed operation is consumed and user cannot retry.
- **Mitigation:** Only clear pending_op if computation succeeded.

---

### [INFO] Finding 14: @panic in Calculator.init()

- **OWASP:** A05 — Security Misconfiguration
- **STRIDE:** Denial of Service
- **Location:** `calculator.zig:28-29`
- **Confidence:** Confirmed
- **Description:** Uses `@panic("OOM")` instead of returning an error. For a desktop calculator this is acceptable but not ideal.
- **Mitigation:** Return `!Calculator` error union.
