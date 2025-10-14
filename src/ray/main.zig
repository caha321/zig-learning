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

    // Materials

    var materials = std.StringArrayHashMap(Material).init(allocator);
    try Material.parseMaterialsJson(allocator, &materials);
    materials.lockPointers();

    // World

    var world = try HittableList.init(allocator);

    var spheres = std.StringArrayHashMap(Sphere).init(allocator);
    try spheres.put("ground", Sphere.init(Vec3.init(0.0, -100.5, -1.0), 100.0, materials.getPtr("ground").?));
    try spheres.put("center", Sphere.init(Vec3.init(0.0, 0, -1.2), 0.5, materials.getPtr("center").?));
    try spheres.put("left", Sphere.init(Vec3.init(-1.0, 0, -1.0), 0.5, materials.getPtr("left").?));
    try spheres.put("bubble", Sphere.init(Vec3.init(-1.0, 0, -1.0), 0.4, materials.getPtr("bubble").?));
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

    var timer = try std.time.Timer.start();
    try cam.render(allocator, &image, &world);
    const elapsed: f64 = @floatFromInt(timer.read());
    std.log.info("Rendering took {d:.3}ms", .{elapsed / std.time.ns_per_ms});

    try image.write(stdout);
}
