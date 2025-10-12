const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Interval = @import("Interval.zig");

pub const Color = Vec3;
const intensity = Interval{ .min = 0, .max = 0.999 };

/// linear blend / interpolation
pub fn lerp(a: f64, start: Color, end: Color) Color {
    return start.mul(1.0 - a).add(end.mul(a));
}

pub fn writeColor(writer: *std.io.Writer, pixel: Color) !void {
    // Translate the [0,1] component values to the byte range [0,255].
    const ir: u8 = @intFromFloat(256 * intensity.clamp(pixel.x()));
    const ig: u8 = @intFromFloat(256 * intensity.clamp(pixel.y()));
    const ib: u8 = @intFromFloat(256 * intensity.clamp(pixel.z()));

    try writer.print("{} {} {}\n", .{ ir, ig, ib });
}
