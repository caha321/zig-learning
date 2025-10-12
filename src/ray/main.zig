const std = @import("std");
const color = @import("color.zig");
const vec3 = @import("vec3.zig");
const ray = @import("ray.zig");
const hittable = @import("hittable.zig");
const Color = color.Color;
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Ray = ray.Ray;

/// linear blend / interpolation
fn lerp(a: f64, start: Color, end: Color) Color {
    return start.mul_scalar(1.0 - a).plus(&end.mul_scalar(a));
}

fn rayColor(r: *const Ray, world: *const hittable.HittableList) Color {
    var rec = hittable.HitRecord{};
    if (world.hit(r, 0, std.math.inf(f64), &rec)) {
        return rec.normal.plus(&Color.one).mul_scalar(0.5);
    }

    const unit_direction = r.direction.unit_vector();
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

    var world = try hittable.HittableList.init(allocator);
    const sphere1 = hittable.Sphere.init(Point3.init(0, 0, -1), 0.5);
    const sphere2 = hittable.Sphere.init(Point3.init(0, -100.5, -1), 100);
    try world.add(hittable.Hittable.implBy(&sphere1));
    try world.add(hittable.Hittable.implBy(&sphere2));

    // Camera

    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * ((@as(comptime_float, @floatFromInt(image_width)) / @as(comptime_float, @floatFromInt(image_height))));
    const camera_center = Point3.zero;

    // Calculate the vectors across the horizontal and down the vertical viewport edges.
    const viewport_u = Vec3.init(viewport_width, 0, 0);
    const viewport_v = Vec3.init(0, -viewport_height, 0);

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    const pixel_delta_u = viewport_u.div_scalar(@floatFromInt(image_width));
    const pixel_delta_v = viewport_v.div_scalar(@floatFromInt(image_height));

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = camera_center.minus(&Vec3.init(0, 0, focal_length)).minus(&viewport_u.div_scalar(2)).minus(&viewport_v.div_scalar(2));

    const pixel00_loc = viewport_upper_left.plus(&(pixel_delta_u.plus(&pixel_delta_v)).mul_scalar(0.5));

    // Render

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    progess.setEstimatedTotalItems(image_height);
    for (0..image_height) |j| {
        progess.completeOne();
        for (0..image_width) |i| {
            const pixel_center = pixel00_loc.plus(&pixel_delta_u.mul_scalar(@floatFromInt(i))
                .plus(&pixel_delta_v.mul_scalar(@floatFromInt(j))));
            const r = Ray{
                .origin = camera_center,
                .direction = pixel_center.minus(&camera_center),
            };

            try color.writeColor(stdout, rayColor(&r, &world));
        }
    }
}
