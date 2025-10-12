const std = @import("std");
const Camera = @import("Camera.zig");
const Vec3 = @import("Vec3.zig");
const Hittable = @import("Hittable.zig");
const HittableList = @import("HittableList.zig");
const Sphere = @import("Sphere.zig");
const Point3 = Vec3.Point3;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var buffer: [1024]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &writer.interface;
    defer stdout.flush() catch {};

    // World

    var world = try HittableList.init(allocator);
    const sphere1 = Sphere.init(Point3.init(0, 0, -1), 0.5);
    const sphere2 = Sphere.init(Point3.init(0, -100.5, -1), 100);
    try world.add(Hittable.implBy(&sphere1));
    try world.add(Hittable.implBy(&sphere2));

    // Camera

    const cam = Camera.init(.{});

    try cam.render(stdout, &world);
}
