const std = @import("std");
const math = std.math;

const Interval = @This();

min: f64,
max: f64,

pub const empty = Interval{ .min = math.inf(f64), .max = -math.inf(f64) };
pub const universe = Interval{ .min = -math.inf(f64), .max = math.inf(f64) };

pub fn size(self: Interval) f64 {
    return self.max - self.min;
}

pub fn contains(self: Interval, x: f64) bool {
    return self.min <= x and x <= self.max;
}

pub fn surrounds(self: Interval, x: f64) bool {
    return self.min < x and x < self.max;
}

pub fn clamp(self: Interval, x: f64) f64 {
    if (x < self.min) return self.min;
    if (x > self.max) return self.max;
    return x;
}

test "clamp" {
    const interval = Interval{ .min = 1, .max = 10 };
    try std.testing.expectEqual(1, interval.clamp(0));
    try std.testing.expectEqual(10, interval.clamp(100));
    try std.testing.expectEqual(5, interval.clamp(5));
}
