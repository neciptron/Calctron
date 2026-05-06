# Fix Log

## Fix Iteration 1: Factorial Denial of Service (CRITICAL) + Silent Overflow (HIGH)

**Findings:** #1 (Critical), #4 (High)
**Files:** calculator.zig, parallel.zig
**Attempt:** 1 of 3
**Result:** ✅ Success

### Changes

**calculator.zig:285-298** — Added upper bound check and error handling:
```zig
const int_val: u64 = @intFromFloat(val);
if (int_val > 170) {
    self.error_msg = "overflow";
    return;
}
const fact_result = parallel.factorialParallel(int_val) catch {
    self.error_msg = "overflow";
    return;
};
result = @as(f64, @floatFromInt(fact_result));
```

**parallel.zig:3** — Changed return type to `!u64`:
```zig
pub fn factorialParallel(n: u64) !u64 {
```

**parallel.zig:51-52** — Returns error instead of silent corruption:
```zig
if (final > std.math.maxInt(u64)) {
    return error.Overflow;
}
```

**parallel.zig:66-85** — Updated tests to use `try` and added overflow test:
```zig
test "factorial parallel returns overflow for large input" {
    try std.testing.expectError(error.Overflow, factorialParallel(200));
}
```

### Verification
- Upper bound check prevents DoS for inputs > 170
- Error union properly propagates overflow to calculator
- Calculator displays "OVERFLOW" error message
- Tests updated to handle error union return type

---

## Fix Iteration 2: getDisplayText Progressive Buffer Corruption (HIGH)

**Finding:** #2 (High)
**Files:** calculator.zig
**Attempt:** 1 of 3
**Result:** ✅ Success

### Changes

**calculator.zig:7** — Added `display_op` field to Calculator struct:
```zig
display_op: []u8,
```

**calculator.zig:25-43** — Updated init() with errdefer cleanup and deinit():
```zig
var display = allocator.alloc(u8, 64) catch @panic("OOM");
errdefer allocator.free(display);
var display_op = allocator.alloc(u8, 64) catch @panic("OOM");
errdefer allocator.free(display_op);
var current_input = allocator.alloc(u8, 64) catch @panic("OOM");
```

**calculator.zig:353-356** — getDisplayText uses display_op instead of mutating display:
```zig
@memcpy(self.display_op[0..cur_len], self.display[0..cur_len]);
@memcpy(self.display_op[cur_len .. cur_len + op_str.len], op_str);
self.display_op[cur_len + op_str.len] = 0;
return self.display_op;
```

### Verification
- display_op buffer holds formatted text with operator string
- display buffer remains unmodified by getDisplayText()
- No progressive corruption — same output every frame

---

## Fix Iteration 3: Negative Button Dimensions on Resize (HIGH)

**Finding:** #3 (High)
**Files:** ui.zig
**Attempt:** 1 of 3
**Result:** ✅ Success

### Changes

**ui.zig:43-44** — Clamped button width:
```zig
const btn_w_raw = (sw - margin * @as(f32, @floatFromInt(cols + 1)) - gap * @as(f32, @floatFromInt(cols - 1))) / @as(f32, @floatFromInt(cols));
const btn_w = @max(btn_w_raw, 20.0);
```

### Verification
- btn_w never goes below 20.0 pixels
- Prevents undefined behavior in raylib C calls with negative dimensions

---

## Summary

| Finding | Severity | Attempts | Result |
|---------|----------|----------|--------|
| #1 Factorial DoS | Critical | 1 | ✅ Fixed |
| #4 Silent Overflow | High | 1 | ✅ Fixed (combined with #1) |
| #2 getDisplayText Corruption | High | 1 | ✅ Fixed |
| #3 Negative Button Dimensions | High | 1 | ✅ Fixed |

**Total fixes:** 4/4 successful
**Files modified:** calculator.zig, parallel.zig, ui.zig
**New vulnerabilities introduced:** 0
