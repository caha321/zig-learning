const std = @import("std");
const HittableList = @import("HittableList.zig");
const HitRecord = @import("HitRecord.zig");
const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const color = @import("color.zig");
const Color = color.Color;
const Vec3 = @import("Vec3.zig");
const Point3 = Vec3.Point3;

const Camera = @This();

const Options = struct {
    aspect_ratio: f64 = 16.0 / 9.0,
    image_width: usize = 400,
};

/// Ratio of image width over height
aspect_ratio: f64,
/// Rendered image width in pixel count
image_width: usize,
/// Rendered image height
image_height: usize,
/// Camera center
center: Point3,
/// Location of pixel 0, 0
pixel00_loc: Point3,
/// Offset to pixel to the right
pixel_delta_u: Vec3,
/// Offset to pixel below
pixel_delta_v: Vec3,

pub fn init(options: Options) Camera {
    const image_height = @max(1, @as(usize, @intFromFloat(@as(f64, @floatFromInt(options.image_width)) / options.aspect_ratio)));
    const center = Point3.zero;

    // Determine viewport dimensions.
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * ((@as(f64, @floatFromInt(options.image_width)) / @as(f64, @floatFromInt(image_height))));

    // Calculate the vectors across the horizontal and down the vertical viewport edges.
    const viewport_u = Vec3.init(viewport_width, 0, 0);
    const viewport_v = Vec3.init(0, -viewport_height, 0);

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    const pixel_delta_u = viewport_u.div(@as(f64, @floatFromInt(options.image_width)));
    const pixel_delta_v = viewport_v.div(@as(f64, @floatFromInt(image_height)));

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = center.sub(Vec3.init(0, 0, focal_length)).sub(viewport_u.div(2)).sub(viewport_v.div(2));
    const pixel00_loc = viewport_upper_left.add((pixel_delta_u.add(pixel_delta_v)).mul(0.5));

    return Camera{
        .aspect_ratio = options.aspect_ratio,
        .image_width = options.image_width,
        .image_height = image_height,
        .center = center,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
    };
}

pub fn render(self: *const Camera, writer: *std.io.Writer, world: *const HittableList) !void {
    const progess = std.Progress.start(.{ .root_name = "Ray Tracer" });

    try writer.print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });

    progess.setEstimatedTotalItems(self.image_height);
    for (0..self.image_height) |j| {
        progess.completeOne();
        for (0..self.image_width) |i| {
            const pixel_center = self.pixel00_loc.add(self.pixel_delta_u.mul(@as(f64, @floatFromInt(i)))
                .add(self.pixel_delta_v.mul(@as(f64, @floatFromInt(j)))));
            const r = Ray{
                .origin = self.center,
                .direction = pixel_center.sub(self.center),
            };

            try color.writeColor(writer, rayColor(&r, world));
        }
    }
}

fn rayColor(r: *const Ray, world: *const HittableList) Color {
    var rec = HitRecord{};
    if (world.hit(r, Interval{ .min = 0, .max = std.math.inf(f64) }, &rec)) {
        return rec.normal.add(Color.one).mul(0.5);
    }

    const unit_direction = r.direction.unitVector();
    const a = 0.5 * (unit_direction.y() + 1.0);
    return color.lerp(a, Color.one, Color.init(0.5, 0.7, 1.0));
}
