# Eliminated Hypotheses

These hypotheses were tested and disproven during investigation.

## 1. `setOperator` null-byte clear broken

**Hypothesis:** `self.current_input[0] = 0` does not properly clear the buffer

**Result:** Disproven

**Reason:** `current_input` is a `[]u8` used as a null-terminated C-string buffer. Setting the first byte to 0 makes `std.mem.len` return 0, effectively clearing the string. This is correct behavior.

## 2. `evaluate` error handling buggy

**Hypothesis:** `evaluate()` doesn't properly handle errors from `compute()`

**Result:** Disproven

**Reason:** `evaluate()` sets `error_msg = null` at entry, calls `compute()` which may set an error, then checks `if (self.error_msg == null)` before updating the result. If an error occurred, the result is not updated and `pending_op` is still cleared. This is correct — the error is displayed to the user and the calculator resets to a clean state.

## 3. `reset` doesn't clear all state

**Hypothesis:** `reset()` misses some fields, leaving stale state

**Result:** Disproven

**Reason:** `reset()` clears all 7 mutable fields: `display[0]`, `current_input[0]`, `result`, `has_result`, `error_msg`, `pending_op`, `pending_value`. No state is left stale.
