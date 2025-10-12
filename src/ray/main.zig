const std = @import("std");
const color = @import("color.zig");
const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
const Hittable = @import("Hittable.zig");
const HittableList = @import("HittableList.zig");
const HitRecord = @import("HitRecord.zig");
const Sphere = @import("Sphere.zig");
const Color = color.Color;
const Point3 = Vec3.Point3;

/// linear blend / interpolation
fn lerp(a: f64, start: Color, end: Color) Color {
    return start.mul(1.0 - a).add(end.mul(a));
}

fn rayColor(r: *const Ray, world: *const HittableList) Color {
    var rec = HitRecord{};
    if (world.hit(r, 0, std.math.inf(f64), &rec)) {
        return rec.normal.add(Color.one).mul(0.5);
    }

    const unit_direction = r.direction.unitVector();
    const a = 0.5 * (unit_direction.y() + 1.0);
    return lerp(a, Color.one, Color.init(0.5, 0.7, 1.0));
}

pub fn main() !void {
    const progess = std.Progress.start(.{
        .root_name = "Ray Tracer",
    });
    const allocator = std.heap.page_allocator;

    var buffer: [1024]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &writer.interface;
    defer stdout.flush() catch {};

    // Image

    const aspect_ratio = 16.0 / 9.0;
    const image_width = 400;

    // Calculate the image height, and ensure that it's at least 1.
    const image_height: usize =
        @max(1, @as(usize, @intFromFloat(@as(comptime_float, @floatFromInt(image_width)) / aspect_ratio)));

    // World

    var world = try HittableList.init(allocator);
    const sphere1 = Sphere.init(Point3.init(0, 0, -1), 0.5);
    const sphere2 = Sphere.init(Point3.init(0, -100.5, -1), 100);
    try world.add(Hittable.implBy(&sphere1));
    try world.add(Hittable.implBy(&sphere2));

    // Camera

    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * ((@as(comptime_float, @floatFromInt(image_width)) / @as(comptime_float, @floatFromInt(image_height))));
    const camera_center = Point3.zero;

    // Calculate the vectors across the horizontal and down the vertical viewport edges.
    const viewport_u = Vec3.init(viewport_width, 0, 0);
    const viewport_v = Vec3.init(0, -viewport_height, 0);

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    const pixel_delta_u = viewport_u.div(@as(f64, @floatFromInt(image_width)));
    const pixel_delta_v = viewport_v.div(@as(f64, @floatFromInt(image_height)));

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = camera_center.sub(Vec3.init(0, 0, focal_length)).sub(viewport_u.div(2)).sub(viewport_v.div(2));

    const pixel00_loc = viewport_upper_left.add((pixel_delta_u.add(pixel_delta_v)).mul(0.5));

    // Render

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    progess.setEstimatedTotalItems(image_height);
    for (0..image_height) |j| {
        progess.completeOne();
        for (0..image_width) |i| {
            const pixel_center = pixel00_loc.add(pixel_delta_u.mul(@as(f64, @floatFromInt(i)))
                .add(pixel_delta_v.mul(@as(f64, @floatFromInt(j)))));
            const r = Ray{
                .origin = camera_center,
                .direction = pixel_center.sub(camera_center),
            };

            try color.writeColor(stdout, rayColor(&r, &world));
        }
    }
}
