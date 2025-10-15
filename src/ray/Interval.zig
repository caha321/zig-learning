const std = @import("std");
const math = std.math;

const T = @import("Vec3.zig").T;

const Interval = @This();

min: T,
max: T,

pub const empty = Interval{ .min = math.inf(T), .max = -math.inf(T) };
pub const universe = Interval{ .min = -math.inf(T), .max = math.inf(T) };

pub fn size(self: Interval) T {
    return self.max - self.min;
}

pub fn contains(self: Interval, x: T) bool {
    return self.min <= x and x <= self.max;
}

pub fn surrounds(self: Interval, x: T) bool {
    return self.min < x and x < self.max;
}

pub fn clamp(self: Interval, x: T) T {
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
