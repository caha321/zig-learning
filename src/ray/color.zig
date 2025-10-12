const std = @import("std");
const Vec3 = @import("Vec3.zig");

pub const Color = Vec3;

pub fn writeColor(writer: *std.io.Writer, pixel: Color) !void {
    // Translate the [0,1] component values to the byte range [0,255].
    const ir: u8 = @intFromFloat(255.999 * pixel.x());
    const ig: u8 = @intFromFloat(255.999 * pixel.y());
    const ib: u8 = @intFromFloat(255.999 * pixel.z());

    try writer.print("{} {} {}\n", .{ ir, ig, ib });
}
