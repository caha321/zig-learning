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
    var materials = std.StringArrayHashMap(Material).init(allocator);
    try materials.put("ground", Material.initLambertian(Vec3.init(0.8, 0.8, 0)));
    try materials.put("center", Material.initLambertian(Vec3.init(0.1, 0.2, 0.5)));
    try materials.put("left", Material.initMetal(Vec3.init(0.8, 0.8, 0.8), 0.3));
    try materials.put("right", Material.initMetal(Vec3.init(0.8, 0.6, 0.2), 1));
    materials.lockPointers();

    var spheres = std.StringArrayHashMap(Sphere).init(allocator);
    try spheres.put("ground", Sphere.init(Vec3.init(0.0, -100.5, -1.0), 100.0, materials.getPtr("ground").?));
    try spheres.put("center", Sphere.init(Vec3.init(0.0, 0, -1.2), 0.5, materials.getPtr("center").?));
    try spheres.put("left", Sphere.init(Vec3.init(-1.0, 0, -1.0), 0.5, materials.getPtr("left").?));
    try spheres.put("right", Sphere.init(Vec3.init(1.0, 0, -1.0), 0.5, materials.getPtr("right").?));
    spheres.lockPointers();

    var it = spheres.iterator();
    while (it.next()) |entry| {
        try world.add(Hittable.implBy(entry.value_ptr));
    }

    // Camera

    const cam = Camera.init(.{
        .image_width = 400,
        .max_depth = 10,
        .samples_per_pixel = 10,
    });
    const image = try Image.init(allocator, cam.image_width, cam.image_height);

    try cam.render(allocator, &image, &world);

    try image.write(stdout);
}
