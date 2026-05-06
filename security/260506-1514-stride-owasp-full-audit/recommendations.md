# Security Recommendations

## Priority 1 — Critical (Fix Immediately)

### 1. Add Factorial Input Upper Bound
**Finding:** [Factorial Denial of Service](./findings.md#critical-finding-1-factorial-denial-of-service--no-upper-bound)
**Effort:** 2 minutes
**Fix:**
```zig
// calculator.zig:278-282 — add upper bound
if (val < 0 or val != @as(f64, @floatFromInt(@as(i64, @intFromFloat(val))))) {
    self.error_msg = "domain";
    return;
}
const int_val: u64 = @intFromFloat(val);
if (int_val > 170) {  // 171! exceeds f64 representable range
    self.error_msg = "overflow";
    return;
}
result = @as(f64, @floatFromInt(parallel.factorialParallel(int_val)));
```

---

## Priority 2 — High (Fix This Sprint)

### 2. Fix getDisplayText Progressive Buffer Corruption
**Finding:** [getDisplayText Buffer Corruption](./findings.md#high-finding-2-getdisplaytext-progressive-buffer-corruption)
**Effort:** 5 minutes
**Fix:** Add a separate display_op buffer for formatted text with pending operator:
```zig
// In Calculator struct, add:
display_op: []u8,

// In getDisplayText():
if (self.pending_op) |_| {
    const op_str = switch (self.pending_op.?) {
        .add => " + ", .sub => " - ", .mul => " × ",
        .div => " ÷ ", .pow => " ^ ",
    };
    const cur_len = std.mem.len(self.display);
    if (cur_len + op_str.len < 63) {
        @memcpy(self.display_op[0..cur_len], self.display[0..cur_len]);
        @memcpy(self.display_op[cur_len .. cur_len + op_str.len], op_str);
        self.display_op[cur_len + op_str.len] = 0;
        return self.display_op;
    }
    return self.display;
}
```

### 3. Add Minimum Button Width on Resize
**Finding:** [Negative Button Dimensions](./findings.md#high-finding-3-negative-button-dimensions-on-extreme-window-resize)
**Effort:** 1 minute
**Fix:**
```zig
// ui.zig:43 — clamp button width
const btn_w_raw = (sw - margin * @as(f32, @floatFromInt(cols + 1))
    - gap * @as(f32, @floatFromInt(cols - 1))) / @as(f32, @floatFromInt(cols));
const btn_w = @max(btn_w_raw, 20.0);
```

### 4. Signal Factorial Overflow as Error
**Finding:** [Silent Factorial Overflow](./findings.md#high-finding-4-silent-factorial-overflow-corruption)
**Effort:** 10 minutes
**Fix:** Change `factorialParallel` to return `!u64` and handle error in calculator:
```zig
// parallel.zig — return error union
pub fn factorialParallel(n: u64) !u64 {
    // ... existing code ...
    if (final > std.math.maxInt(u64)) {
        return error.Overflow;
    }
    return @intCast(final);
}

// calculator.zig — handle error
const fact_result = parallel.factorialParallel(int_val) catch {
    self.error_msg = "overflow";
    return;
};
result = @as(f64, @floatFromInt(fact_result));
```

---

## Priority 3 — Medium (Plan for Next Sprint)

### 5. Add NaN/Inf Check to compute()
**Finding:** [NaN/Inf Propagation](./findings.md#medium-finding-6-naninf-propagation-through-binary-operations)
**Effort:** 3 minutes
**Fix:**
```zig
fn compute(self: *Calculator, op: Calculator.Operator, a: f64, b: f64) f64 {
    const result = switch (op) {
        .add => a + b, .sub => a - b, .mul => a * b,
        .div => { if (b == 0) { self.error_msg = "div_zero"; return 0; } return a / b; },
        .pow => math.pow(f64, a, b),
    };
    if (math.isNan(result) or math.isInf(result)) {
        self.error_msg = "overflow";
    }
    return result;
}
```

### 6. Add Thread Synchronization for Partials
**Finding:** [Thread Data Race](./findings.md#medium-finding-5-thread-data-race-on-weakly-ordered-architectures)
**Effort:** 15 minutes
**Fix:** Use atomic operations for partials array.

### 7. Fix Float Precision in formatResult
**Finding:** [Floating Point Precision Loss](./findings.md#medium-finding-8-floating-point-precision-loss-in-formatresult)
**Effort:** 5 minutes
**Fix:** Add range check before i64 conversion.

### 8. Add NaN Check in setOperator()
**Finding:** [Chained Operator NaN](./findings.md#medium-finding-7-chained-operator-nan-propagation)
**Effort:** 2 minutes

### 9. Fix Calculator State After Errors
**Finding:** [State Inconsistency](./findings.md#medium-finding-9-calculator-state-inconsistency-after-errors)
**Effort:** 5 minutes

---

## Priority 4 — Low (Backlog)

### 10. Fix Memory Leak on OOM — calculator.zig:28-29
### 11. Report Result Truncation — calculator.zig:311,313
### 12. Enable Leak Detection — main.zig:14
### 13. Preserve State on evaluate() Error — calculator.zig:195-207
