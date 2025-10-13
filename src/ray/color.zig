const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Interval = @import("Interval.zig");

pub const Color = Vec3;
const intensity = Interval{ .min = 0, .max = 0.999 };

/// linear blend / interpolation
pub fn lerp(a: f64, start: Color, end: Color) Color {
    return start.mul(1.0 - a).add(end.mul(a));
}

pub fn linearToGamma(linear_component: f64) f64 {
    if (linear_component > 0) return @sqrt(linear_component);
    return 0.0;
}

pub fn writeColor(writer: *std.io.Writer, pixel: Color) !void {

    // Apply a linear to gamma transform for gamma 2
    const r = linearToGamma(pixel.x());
    const g = linearToGamma(pixel.y());
    const b = linearToGamma(pixel.z());

    // Translate the [0,1] component values to the byte range [0,255].
    const ir: u8 = @intFromFloat(256 * intensity.clamp(r));
    const ig: u8 = @intFromFloat(256 * intensity.clamp(g));
    const ib: u8 = @intFromFloat(256 * intensity.clamp(b));

    try writer.print("{} {} {}\n", .{ ir, ig, ib });
}
