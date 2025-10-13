const std = @import("std");

var prng = std.Random.DefaultPrng.init(42);
pub const rnd = prng.random();

/// Returns a random float in [min,max)
pub fn randomFloatMinMax(comptime T: type, min: T, max: T) T {
    return min + (max - min) * rnd.float(T);
}
