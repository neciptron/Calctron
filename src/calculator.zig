const std = @import("std");
const math = std.math;
const parallel = @import("parallel.zig");

pub const Calculator = struct {
    allocator: std.mem.Allocator,
    display: []u8,
    display_op: []u8,
    current_input: []u8,
    result: f64,
    has_result: bool,
    error_msg: ?[]const u8,
    use_degrees: bool,
    scientific_mode: bool,
    pending_op: ?Operator,
    pending_value: f64,

    pub const Operator = enum {
        add,
        sub,
        mul,
        div,
        pow,
    };

    pub fn init(allocator: std.mem.Allocator) Calculator {
        const display = allocator.alloc(u8, 64) catch @panic("OOM");
        errdefer allocator.free(display);
        const display_op = allocator.alloc(u8, 64) catch @panic("OOM");
        errdefer allocator.free(display_op);
        const current_input = allocator.alloc(u8, 64) catch @panic("OOM");
        errdefer allocator.free(current_input);
        @memset(display, 0);
        @memset(display_op, 0);
        @memset(current_input, 0);
        return .{
            .allocator = allocator,
            .display = display,
            .display_op = display_op,
            .current_input = current_input,
            .result = 0,
            .has_result = false,
            .error_msg = null,
            .use_degrees = false,
            .scientific_mode = true,
            .pending_op = null,
            .pending_value = 0,
        };
    }

    pub fn deinit(self: *Calculator) void {
        self.allocator.free(self.display);
        self.allocator.free(self.display_op);
        self.allocator.free(self.current_input);
    }

    pub fn reset(self: *Calculator) void {
        self.display[0] = 0;
        self.current_input[0] = 0;
        self.result = 0;
        self.has_result = false;
        self.error_msg = null;
        self.pending_op = null;
        self.pending_value = 0;
    }

    pub fn strLen(buf: []const u8) usize {
        return std.mem.indexOfScalar(u8, buf, 0) orelse buf.len;
    }

    pub fn handleInput(self: *Calculator) void {
        const raylib = @import("raylib");

        if (raylib.isKeyPressed(.escape)) {
            self.reset();
            return;
        }

        // Number keys 0-9
        const digit_keys = [_]raylib.KeyboardKey{
            .zero, .one, .two,   .three, .four,
            .five, .six, .seven, .eight, .nine,
        };
        for (digit_keys, 0..) |key, idx| {
            if (raylib.isKeyPressed(key)) {
                self.appendDigit(@intCast(idx));
                return;
            }
        }

        // Keypad numbers
        const kp_keys = [_]raylib.KeyboardKey{
            .kp_0, .kp_1, .kp_2, .kp_3, .kp_4,
            .kp_5, .kp_6, .kp_7, .kp_8, .kp_9,
        };
        for (kp_keys, 0..) |key, idx| {
            if (raylib.isKeyPressed(key)) {
                self.appendDigit(@intCast(idx));
                return;
            }
        }

        // Decimal point
        if (raylib.isKeyPressed(.period) or raylib.isKeyPressed(.kp_decimal)) {
            self.appendDot();
            return;
        }

        if (raylib.isKeyPressed(.enter) or raylib.isKeyPressed(.kp_enter)) {
            self.evaluate();
            return;
        }

        if (raylib.isKeyPressed(.c)) {
            self.reset();
            return;
        }

        if (raylib.isKeyPressed(.backspace)) {
            self.backspace();
            return;
        }

        if (raylib.isKeyPressed(.apostrophe) or raylib.isKeyPressed(.kp_multiply)) {
            self.setOperator(.mul);
            return;
        }

        if (raylib.isKeyPressed(.grave) or raylib.isKeyPressed(.kp_add)) {
            self.setOperator(.add);
            return;
        }

        if (raylib.isKeyPressed(.minus) or raylib.isKeyPressed(.kp_subtract)) {
            self.setOperator(.sub);
            return;
        }

        if (raylib.isKeyPressed(.slash) or raylib.isKeyPressed(.kp_divide)) {
            self.setOperator(.div);
            return;
        }

        if (raylib.isKeyPressed(.s)) {
            self.applyUnary("sin");
            return;
        }
        if (raylib.isKeyPressed(.o)) {
            self.applyUnary("cos");
            return;
        }
        if (raylib.isKeyPressed(.t)) {
            self.applyUnary("tan");
            return;
        }
        if (raylib.isKeyPressed(.v)) {
            self.applyUnary("sqrt");
            return;
        }
        if (raylib.isKeyPressed(.l)) {
            self.applyUnary("log");
            return;
        }
        if (raylib.isKeyPressed(.n)) {
            self.applyUnary("ln");
            return;
        }
        if (raylib.isKeyPressed(.q)) {
            self.applyUnary("square");
            return;
        }
        if (raylib.isKeyPressed(.b)) {
            self.applyUnary("cube");
            return;
        }
        if (raylib.isKeyPressed(.i)) {
            self.applyUnary("inv");
            return;
        }
        if (raylib.isKeyPressed(.p)) {
            self.applyUnary("percent");
            return;
        }
        if (raylib.isKeyPressed(.f)) {
            self.applyUnary("fact");
            return;
        }
        if (raylib.isKeyPressed(.u)) {
            self.applyUnary("pi");
            return;
        }
        if (raylib.isKeyPressed(.w)) {
            self.applyUnary("e");
            return;
        }
        if (raylib.isKeyPressed(.a)) {
            self.applyUnary("negate");
            return;
        }
        if (raylib.isKeyPressed(.x)) {
            self.scientific_mode = !self.scientific_mode;
            return;
        }
    }

    pub fn appendDigit(self: *Calculator, digit: u8) void {
        self.error_msg = null;
        const len = Calculator.strLen(self.current_input);
        if (len >= 63) return;
        self.current_input[len] = '0' + digit;
        self.current_input[len + 1] = 0;

        if (self.has_result and self.pending_op == null) {
            self.current_input[0] = '0' + digit;
            self.current_input[1] = 0;
            self.has_result = false;
        }
    }

    pub fn appendDot(self: *Calculator) void {
        self.error_msg = null;
        if (Calculator.strLen(self.current_input) == 0) {
            self.current_input[0] = '0';
            self.current_input[1] = '.';
            self.current_input[2] = 0;
        } else if (!std.mem.containsAtLeast(u8, self.current_input, 1, ".")) {
            const len = Calculator.strLen(self.current_input);
            if (len < 63) {
                self.current_input[len] = '.';
                self.current_input[len + 1] = 0;
            }
        }
        self.has_result = false;
    }

    pub fn setOperator(self: *Calculator, op: Calculator.Operator) void {
        self.error_msg = null;
        const val = self.getCurrentValue();
        if (self.pending_op) |pending| {
            const result = self.compute(pending, self.pending_value, val);
            if (self.error_msg) |_| return;
            self.pending_value = result;
            self.result = result;
            self.has_result = true;
        } else {
            self.pending_value = val;
        }
        self.pending_op = op;
        self.current_input[0] = 0;
        self.formatResult(val);
    }

    pub fn evaluate(self: *Calculator) void {
        self.error_msg = null;
        const val = self.getCurrentValue();
        if (self.pending_op) |op| {
            const result = self.compute(op, self.pending_value, val);
            if (self.error_msg == null) {
                self.result = result;
                self.has_result = true;
                self.formatResult(result);
                self.current_input[0] = 0;
            }
            self.pending_op = null;
        }
    }

    pub fn getCurrentValue(self: *Calculator) f64 {
        const len = Calculator.strLen(self.current_input);
        if (len == 0) {
            return self.result;
        }
        return std.fmt.parseFloat(f64, self.current_input[0..len]) catch 0;
    }

    fn compute(self: *Calculator, op: Calculator.Operator, a: f64, b: f64) f64 {
        return switch (op) {
            .add => a + b,
            .sub => a - b,
            .mul => a * b,
            .div => {
                if (b == 0) {
                    self.error_msg = "div_zero";
                    return 0;
                }
                return a / b;
            },
            .pow => {
                const res = math.pow(f64, a, b);
                if (math.isNan(res)) {
                    self.error_msg = "domain";
                    return 0;
                }
                if (math.isInf(res)) {
                    self.error_msg = "overflow";
                    return 0;
                }
                return res;
            },
        };
    }

    pub fn applyUnary(self: *Calculator, func: []const u8) void {
        self.error_msg = null;
        const val = self.getCurrentValue();
        var result: f64 = 0;

        const angle = if (self.use_degrees) val * (math.pi / 180.0) else val;

        if (std.mem.eql(u8, func, "sin")) {
            result = math.sin(angle);
        } else if (std.mem.eql(u8, func, "cos")) {
            result = math.cos(angle);
        } else if (std.mem.eql(u8, func, "tan")) {
            result = math.tan(angle);
        } else if (std.mem.eql(u8, func, "sqrt")) {
            if (val < 0) {
                self.error_msg = "domain";
                return;
            }
            result = math.sqrt(val);
        } else if (std.mem.eql(u8, func, "log")) {
            if (val <= 0) {
                self.error_msg = "domain";
                return;
            }
            result = math.log10(val);
        } else if (std.mem.eql(u8, func, "ln")) {
            if (val <= 0) {
                self.error_msg = "domain";
                return;
            }
            result = math.log(f64, math.e, val);
        } else if (std.mem.eql(u8, func, "square")) {
            result = val * val;
        } else if (std.mem.eql(u8, func, "cube")) {
            result = val * val * val;
        } else if (std.mem.eql(u8, func, "inv")) {
            if (val == 0) {
                self.error_msg = "div_zero";
                return;
            }
            result = 1.0 / val;
        } else if (std.mem.eql(u8, func, "negate")) {
            result = -val;
        } else if (std.mem.eql(u8, func, "percent")) {
            result = val / 100.0;
        } else if (std.mem.eql(u8, func, "fact")) {
            if (val < 0) {
                self.error_msg = "domain";
                return;
            }
            const truncated: f64 = @trunc(val);
            if (val != truncated) {
                self.error_msg = "domain";
                return;
            }
            if (val > @as(f64, @floatFromInt(std.math.maxInt(u64)))) {
                self.error_msg = "overflow";
                return;
            }
            const int_val: u64 = @intFromFloat(val);
            const fact_result = parallel.factorialParallel(int_val) catch {
                self.error_msg = "overflow";
                return;
            };
            result = @as(f64, @floatFromInt(fact_result));
        } else if (std.mem.eql(u8, func, "pi")) {
            result = math.pi;
        } else if (std.mem.eql(u8, func, "e")) {
            result = math.e;
        }

        if (!math.isNan(result) and !math.isInf(result)) {
            self.result = result;
            self.has_result = true;
            self.formatResult(result);
            self.current_input[0] = 0;
        } else {
            self.error_msg = if (math.isNan(result)) "domain" else "overflow";
        }
    }

    pub fn backspace(self: *Calculator) void {
        self.error_msg = null;
        const len = Calculator.strLen(self.current_input);
        if (len > 0) {
            self.current_input[len - 1] = 0;
        }
    }

    fn formatResult(self: *Calculator, val: f64) void {
        self.display[0] = 0;
        var writer = std.Io.Writer.fixed(self.display);

        if (val == 0) {
            writer.print("0", .{}) catch {};
            return;
        }

        const abs_val = @abs(val);

        if (abs_val >= 1e15 or (abs_val < 1e-7 and abs_val != 0)) {
            writer.print("{e:.10}", .{val}) catch {};
            return;
        }

        const truncated = @trunc(val);
        if (val == truncated) {
            writer.print("{d:.0}", .{val}) catch {};
            return;
        }

        var buf: [64]u8 = undefined;
        const formatted = std.fmt.bufPrint(&buf, "{d:.15}", .{val}) catch "0";

        var end: usize = formatted.len;
        while (end > 0 and formatted[end - 1] == '0') : (end -= 1) {}
        if (end > 0 and formatted[end - 1] == '.') {
            end -= 1;
        }

        const trimmed = formatted[0..end];
        const copy_len = @min(trimmed.len, 63);
        @memcpy(self.display[0..copy_len], trimmed[0..copy_len]);
        self.display[copy_len] = 0;
    }

    pub fn getDisplayText(self: *Calculator) []const u8 {
        if (self.error_msg) |err| {
            if (std.mem.eql(u8, err, "div_zero")) return "DIV0";
            if (std.mem.eql(u8, err, "domain")) return "DOMAIN";
            if (std.mem.eql(u8, err, "overflow")) return "OVERFLOW";
            return "ERROR";
        }
        if (self.pending_op) |_| {
            const op_str = switch (self.pending_op.?) {
                .add => " + ",
                .sub => " - ",
                .mul => " × ",
                .div => " ÷ ",
                .pow => " ^ ",
            };
            const cur_len = Calculator.strLen(self.display);
            if (cur_len + op_str.len < 64) {
                @memcpy(self.display_op[0..cur_len], self.display[0..cur_len]);
                @memcpy(self.display_op[cur_len .. cur_len + op_str.len], op_str);
                self.display_op[cur_len + op_str.len] = 0;
                return self.display_op;
            }
            return self.display;
        }
        if (Calculator.strLen(self.current_input) > 0) {
            return self.current_input;
        }
        if (self.has_result) {
            return self.display;
        }
        return "0";
    }
};

test "basic arithmetic" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.appendDigit(5);
    calc.setOperator(.add);
    calc.appendDigit(3);
    calc.evaluate();

    try std.testing.expectEqual(@as(f64, 8.0), calc.result);
}

test "division by zero" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.appendDigit(5);
    calc.setOperator(.div);
    calc.appendDigit(0);
    calc.evaluate();

    try std.testing.expect(calc.error_msg != null);
}

test "precision: sqrt and square" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.applyUnary("pi");
    calc.applyUnary("square");
    const pi_sq = calc.result;
    try std.testing.expect(math.approxEqAbs(f64, pi_sq, math.pi * math.pi, 1e-10));

    calc.applyUnary("sqrt");
    try std.testing.expect(math.approxEqAbs(f64, calc.result, math.pi, 1e-10));
}

test "precision: log and ln" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.applyUnary("e");
    try std.testing.expect(math.approxEqAbs(f64, calc.result, math.e, 1e-10));

    calc.applyUnary("ln");
    try std.testing.expect(math.approxEqAbs(f64, calc.result, 1.0, 1e-10));
}

test "precision: large and small numbers" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.applyUnary("e");
    calc.applyUnary("square");
    try std.testing.expect(math.approxEqAbs(f64, calc.result, math.e * math.e, 1e-10));
}

test "precision: negate function" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.applyUnary("pi");
    const pi_val = calc.result;
    calc.applyUnary("negate");
    try std.testing.expect(math.approxEqAbs(f64, calc.result, -pi_val, 1e-10));
}

test "precision: percent function" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.applyUnary("pi");
    calc.applyUnary("percent");
    try std.testing.expect(math.approxEqAbs(f64, calc.result, math.pi / 100.0, 1e-10));
}

test "precision: inverse function" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.applyUnary("e");
    calc.applyUnary("inv");
    try std.testing.expect(math.approxEqAbs(f64, calc.result, 1.0 / math.e, 1e-10));
}

test "precision: cube function" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.applyUnary("pi");
    calc.applyUnary("cube");
    try std.testing.expect(math.approxEqAbs(f64, calc.result, math.pi * math.pi * math.pi, 1e-8));
}

test "precision: power operation" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.applyUnary("e");
    calc.setOperator(.pow);
    calc.applyUnary("ln");
    calc.evaluate();
    try std.testing.expect(math.approxEqAbs(f64, calc.result, math.e, 1e-10));
}

test "regression: evaluate clears current_input" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.appendDigit(5);
    calc.setOperator(.add);
    calc.appendDigit(3);
    calc.evaluate();

    try std.testing.expectEqual(@as(f64, 8.0), calc.result);
    const display = calc.getDisplayText();
    try std.testing.expect(!std.mem.eql(u8, display, "3"));
}

test "regression: pow returns error on NaN" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.applyUnary("negate");
    calc.result = -2.0;
    calc.has_result = true;
    calc.formatResult(-2.0);
    calc.setOperator(.pow);

    calc.appendDigit(5);
    calc.current_input[0] = '0';
    calc.current_input[1] = '.';
    calc.current_input[2] = '5';
    calc.current_input[3] = 0;
    calc.evaluate();

    try std.testing.expect(calc.error_msg != null);
}

test "regression: factorial domain error for negative" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.result = -5.0;
    calc.has_result = true;
    calc.applyUnary("fact");

    try std.testing.expect(calc.error_msg != null);
}

test "regression: factorial domain error for fractional" {
    var calc = Calculator.init(std.testing.allocator);
    defer calc.deinit();

    calc.appendDigit(5);
    calc.appendDot();
    calc.appendDigit(5);
    calc.applyUnary("fact");

    try std.testing.expect(calc.error_msg != null);
}
