const std = @import("std");
const rl = @import("raylib");
const Vec3 = @import("Vec3.zig");
const Interval = @import("Interval.zig");

const T = Vec3.T;

pub const Color = Vec3;
const intensity = Interval{ .min = 0, .max = 0.999 };

/// linear blend / interpolation
pub fn lerp(a: T, start: Color, end: Color) Color {
    return start.mul(1.0 - a).add(end.mul(a));
}

pub fn linearToGamma(linear_component: T) T {
    if (linear_component > 0) return @sqrt(linear_component);
    return 0.0;
}

pub const Pixel = packed struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub const black = Pixel{ .r = 0, .g = 0, .b = 0, .a = 255 };

    pub fn fromColor(color: Color) Pixel {
        // Apply a linear to gamma transform for gamma 2
        const r = linearToGamma(color.x());
        const g = linearToGamma(color.y());
        const b = linearToGamma(color.z());

        return Pixel{
            // Translate the [0,1] component values to the byte range [0,255].
            .r = @intFromFloat(256 * intensity.clamp(r)),
            .g = @intFromFloat(256 * intensity.clamp(g)),
            .b = @intFromFloat(256 * intensity.clamp(b)),
            .a = 255,
        };
    }

    pub fn write(self: Pixel, writer: *std.io.Writer) !void {
        try writer.print("{} {} {}\n", .{ self.r, self.g, self.b });
    }
};

pub fn toRlColor(color: Color) rl.Color {
    // Apply a linear to gamma transform for gamma 2
    const r = linearToGamma(color.x());
    const g = linearToGamma(color.y());
    const b = linearToGamma(color.z());

    return .{
        // Translate the [0,1] component values to the byte range [0,255].
        .r = @intFromFloat(256 * intensity.clamp(r)),
        .g = @intFromFloat(256 * intensity.clamp(g)),
        .b = @intFromFloat(256 * intensity.clamp(b)),
        .a = 255,
    };
}
