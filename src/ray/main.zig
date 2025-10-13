const std = @import("std");
const Camera = @import("Camera.zig");
const Vec3 = @import("Vec3.zig");
const Hittable = @import("Hittable.zig");
const HittableList = @import("HittableList.zig");
const Sphere = @import("Sphere.zig");
const Point3 = Vec3.Point3;
const Material = @import("Material.zig");
const Image = @import("Image.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var buffer: [1024]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &writer.interface;
    defer stdout.flush() catch {};

    // World

    var world = try HittableList.init(allocator);

    const material_ground = Material.initLambertian(Vec3.init(0.8, 0.8, 0));
    const material_center = Material.initLambertian(Vec3.init(0.1, 0.2, 0.5));
    const material_left = Material.initMetal(Vec3.init(0.8, 0.8, 0.8), 0.3);
    const material_right = Material.initMetal(Vec3.init(0.8, 0.6, 0.2), 1);

    const sphere_ground = Sphere.init(Vec3.init(0.0, -100.5, -1.0), 100.0, material_ground);
    const sphere_center = Sphere.init(Vec3.init(0.0, 0, -1.2), 0.5, material_center);
    const sphere_left = Sphere.init(Vec3.init(-1.0, 0, -1.0), 0.5, material_left);
    const sphere_right = Sphere.init(Vec3.init(1.0, 0, -1.0), 0.5, material_right);

    try world.add(Hittable.implBy(&sphere_ground));
    try world.add(Hittable.implBy(&sphere_center));
    try world.add(Hittable.implBy(&sphere_left));
    try world.add(Hittable.implBy(&sphere_right));

    // Camera

    const cam = Camera.init(.{});
    const image = try Image.init(allocator, cam.image_width, cam.image_height);

    try cam.render(&image, &world);

    try image.write(stdout);
}
