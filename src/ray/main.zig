const std = @import("std");

const rl = @import("raylib");

const lib = @import("lib.zig");
const Vec3 = lib.Vec3;
const Point3 = lib.Point3;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var buffer: [1024]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &writer.interface;
    defer stdout.flush() catch {};

    // Materials

    var materials = std.StringArrayHashMap(lib.material.Material).init(allocator);
    try lib.material.parseMaterialsJson(allocator, &materials);
    materials.lockPointers();

    // World

    var world = try lib.HittableList.init(allocator);

    const Sphere = lib.Sphere;

    var spheres = std.StringArrayHashMap(Sphere).init(allocator);
    try spheres.put("ground", Sphere.init(Vec3.init(0.0, -100.5, -1.0), 100.0, materials.getPtr("ground").?));
    try spheres.put("center", Sphere.init(Vec3.init(0.0, 0, -1.2), 0.5, materials.getPtr("center").?));
    try spheres.put("left", Sphere.init(Vec3.init(-1.0, 0, -1.0), 0.5, materials.getPtr("left").?));
    try spheres.put("bubble", Sphere.init(Vec3.init(-1.0, 0, -1.0), 0.4, materials.getPtr("bubble").?));
    try spheres.put("right", Sphere.init(Vec3.init(1.0, 0, -1.0), 0.5, materials.getPtr("right").?));
    spheres.lockPointers();

    var it = spheres.iterator();
    while (it.next()) |entry| {
        try world.add(lib.Hittable.implBy(entry.value_ptr));
    }

    // Camera

    var cam = lib.Camera{
        .image_width = 1600,
        .max_depth = 10,
        .samples_per_pixel = 10,
        .vfov = 20,
        .look_from = Point3.init(-2, 2, 1),
    };
    cam.init();

    // Window stuff

    rl.initWindow(
        @intCast(cam.image_width),
        @intCast(cam.image_height),
        "Ray Tracing in One Weekend",
    );
    defer rl.closeWindow();

    rl.setTargetFPS(30);

    try cam.render(allocator, &world);
}
