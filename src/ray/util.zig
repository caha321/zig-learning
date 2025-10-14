const std = @import("std");

var prng = std.Random.DefaultPrng.init(42);
pub const rnd = prng.random();

/// Returns a random float in [min,max)
pub fn randomFloatMinMax(comptime T: type, min: T, max: T) T {
    return min + (max - min) * rnd.float(T);
}

pub fn parseFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    // Read the entire file into memory (N)
    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);

    _ = try file.readAll(buffer);

    return buffer;
}
