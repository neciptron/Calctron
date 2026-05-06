const std = @import("std");

const ThreadArgs = struct {
    start: u64,
    end: u64,
    result: *u128,
};

pub fn factorialParallel(n: u64) !u64 {
    if (n <= 1) return 1;
    if (n > 20) return error.Overflow;
    if (n <= 4) return factorialSeq(n);

    const num_threads: u64 = if (n >= 12) 4 else 2;
    const items_per_thread = n / num_threads;

    var threads: [4]std.Thread = undefined;
    var partials: [4]u128 = undefined;
    var args: [4]ThreadArgs = undefined;

    for (0..num_threads) |i| {
        partials[i] = 0;
        const start = i * items_per_thread + 1;
        const end = if (i == num_threads - 1) n else (i + 1) * items_per_thread;

        args[i] = .{
            .start = @intCast(start),
            .end = @intCast(end),
            .result = &partials[i],
        };

        threads[i] = std.Thread.spawn(.{}, threadCompute, .{&args[i]}) catch {
            return factorialSeq(n);
        };
    }

    for (0..num_threads) |i| {
        threads[i].join();
    }

    var final: u128 = 1;
    for (0..num_threads) |i| {
        final *= partials[i];
    }

    if (final > std.math.maxInt(u64)) {
        return error.Overflow;
    }
    return @intCast(final);
}

fn threadCompute(a: *ThreadArgs) callconv(.c) void {
    var r: u128 = 1;
    var j = a.start;
    while (j <= a.end) : (j += 1) {
        r *|= @as(u128, @intCast(j));
    }
    a.result.* = r;
}

fn factorialSeq(n: u64) u64 {
    var result: u64 = 1;
    var i: u64 = 2;
    while (i <= n) : (i += 1) {
        const r = @mulWithOverflow(result, i);
        if (r[1] != 0) return std.math.maxInt(u64);
        result = r[0];
    }
    return result;
}

test "factorial parallel" {
    try std.testing.expectEqual(@as(u64, 1), try factorialParallel(0));
    try std.testing.expectEqual(@as(u64, 1), try factorialParallel(1));
    try std.testing.expectEqual(@as(u64, 2), try factorialParallel(2));
    try std.testing.expectEqual(@as(u64, 6), try factorialParallel(3));
    try std.testing.expectEqual(@as(u64, 120), try factorialParallel(5));
    try std.testing.expectEqual(@as(u64, 3628800), try factorialParallel(10));
}

test "factorial parallel matches sequential" {
    var i: u64 = 0;
    while (i <= 15) : (i += 1) {
        const parallel_result = try factorialParallel(i);
        const seq_result = factorialSeq(i);
        try std.testing.expectEqual(seq_result, parallel_result);
    }
}

test "factorial parallel returns overflow for large input" {
    try std.testing.expectError(error.Overflow, factorialParallel(200));
}
