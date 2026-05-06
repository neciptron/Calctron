const std = @import("std");
const calc = @import("calculator.zig");
const parallel = @import("parallel.zig");
const math = std.math;

test "fuzz: arbitrary digit sequences" {
    var c = calc.Calculator.init(std.testing.allocator);
    defer c.deinit();

    var rng = std.Random.DefaultPrng.init(0);
    const rand = rng.random();
    var ops: usize = 0;
    while (ops < 100) : (ops += 1) {
        const action = rand.intRangeAtMost(u8, 0, 8);
        switch (action) {
            0 => {
                const digit = rand.intRangeAtMost(u8, 0, 9);
                c.appendDigit(digit);
            },
            1 => c.appendDot(),
            2 => {
                const op_idx = rand.intRangeAtMost(u8, 0, 3);
                const op: calc.Calculator.Operator = switch (op_idx) {
                    0 => .add,
                    1 => .sub,
                    2 => .mul,
                    else => .div,
                };
                c.setOperator(op);
            },
            3 => c.evaluate(),
            4 => c.reset(),
            5 => c.backspace(),
            6 => c.applyUnary("sin"),
            7 => c.applyUnary("sqrt"),
            8 => c.applyUnary("negate"),
            else => {},
        }
    }

    // After random operations, result should be finite
    if (c.error_msg == null) {
        try std.testing.expect(!math.isNan(c.result));
        try std.testing.expect(!math.isInf(c.result));
    }
}

test "fuzz: factorial edge cases" {
    var c = calc.Calculator.init(std.testing.allocator);
    defer c.deinit();

    // Test values near boundaries
    const test_values = [_]f64{ 0, 1, 2, 20, 21, 170, 171, 1e10, 1e19, -1, -5, 0.5, 3.7 };
    for (test_values) |v| {
        c.reset();
        c.result = v;
        c.has_result = true;
        c.applyUnary("fact");
        // Should either succeed with valid result or produce an error
        if (c.error_msg == null) {
            try std.testing.expect(!math.isNan(c.result));
            try std.testing.expect(!math.isInf(c.result));
            try std.testing.expect(c.result >= 0);
        }
    }
}

test "fuzz: trigonometric with arbitrary angles" {
    var c = calc.Calculator.init(std.testing.allocator);
    defer c.deinit();

    var rng = std.Random.DefaultPrng.init(42);
    const rand = rng.random();
    const funcs = [_][]const u8{ "sin", "cos", "tan" };

    var i: usize = 0;
    while (i < 50) : (i += 1) {
        // Random angle between -1e6 and 1e6
        const angle = rand.float(f64) * 2e6 - 1e6;
        c.reset();
        c.result = angle;
        c.has_result = true;

        for (funcs) |f| {
            c.applyUnary(f);
            if (c.error_msg == null) {
                try std.testing.expect(!math.isNan(c.result));
                // sin/cos should be in [-1, 1]
                if (std.mem.eql(u8, f, "sin") or std.mem.eql(u8, f, "cos")) {
                    try std.testing.expect(c.result >= -1.1);
                    try std.testing.expect(c.result <= 1.1);
                }
            }
        }
    }
}

test "fuzz: power operation edge cases" {
    var c = calc.Calculator.init(std.testing.allocator);
    defer c.deinit();

    // Test cases that could produce NaN or Inf
    const bases = [_]f64{ -2, -1, 0, 0.5, 1, 2, 10, 100, 1e15 };
    const exps = [_]f64{ -2, -1, 0, 0.5, 1, 2, 3, -0.5 };

    for (bases) |b| {
        for (exps) |e| {
            c.reset();
            c.result = b;
            c.has_result = true;
            c.setOperator(.pow);
            c.result = e;
            c.has_result = true;
            c.evaluate();

            // Should either succeed with valid result or produce a proper error
            if (c.error_msg == null) {
                try std.testing.expect(!math.isNan(c.result));
            } else {
                try std.testing.expect(c.error_msg != null);
            }
        }
    }
}

test "fuzz: division edge cases" {
    var c = calc.Calculator.init(std.testing.allocator);
    defer c.deinit();

    const values = [_]f64{ 0, 1, -1, 0.001, 1e15, -1e15, 1e-10 };
    for (values) |a| {
        for (values) |b| {
            c.reset();
            c.result = a;
            c.has_result = true;
            c.setOperator(.div);
            c.result = b;
            c.has_result = true;
            c.evaluate();

            if (c.error_msg == null) {
                try std.testing.expect(!math.isNan(c.result));
            }
        }
    }
}
