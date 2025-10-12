const std = @import("std");

pub fn main() !void {
    const progess = std.Progress.start(.{
        .root_name = "Ray Tracer",
    });
    var buffer: [1024]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &writer.interface;
    defer stdout.flush() catch {};

    const image_width = 256;
    const image_height = 256;

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    progess.setEstimatedTotalItems(image_height);
    for (0..image_height) |j| {
        progess.completeOne();
        for (0..image_width) |i| {
            const r: f64 = @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(image_width - 1));
            const g: f64 = @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(image_height - 1));
            const b: f64 = 0.0;

            const ir: usize = @intFromFloat(255.999 * r);
            const ig: usize = @intFromFloat(255.999 * g);
            const ib: usize = @intFromFloat(255.999 * b);

            try stdout.print("{} {} {}\n", .{ ir, ig, ib });
        }
    }
}
