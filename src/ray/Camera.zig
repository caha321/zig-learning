const std = @import("std");
const lib = @import("lib.zig");
const Point3 = lib.Point3;
const Vec3 = lib.Vec3;
const Ray = lib.Ray;
const Color = lib.Color;

const Camera = @This();

/// Ratio of image width over height
aspect_ratio: f64 = 16.0 / 9.0,
/// Rendered image width in pixel count
image_width: usize = 400,
/// Count of random samples for each pixel
samples_per_pixel: usize = 10,
/// Maximum number of ray bounces into scene
max_depth: isize = 10,

/// Vertical view angle (field of view)
vfov: f64 = 90,
/// Point camera is looking from
look_from: Point3 = Point3.init(0, 0, 0),
/// Point camera is looking at
look_at: Point3 = Point3.init(0, 0, -1),
/// Camera-relative "up" direction
v_up: Vec3 = Vec3.init(0, 1, 0),
/// Variation angle of rays through each pixel
defocus_angle: f64 = 0.0,
/// Distance from camera lookfrom point to plane of perfect focus
focus_dist: f64 = 10.0,

/////////////////////////////////////
// set via initialize()

/// Rendered image height
image_height: usize = undefined,
/// Camera center
center: Point3 = undefined,
/// Location of pixel 0, 0
pixel00_loc: Point3 = undefined,
/// Offset to pixel to the right
pixel_delta_u: Vec3 = undefined,
/// Offset to pixel below
pixel_delta_v: Vec3 = undefined,
/// Color scale factor for a sum of pixel samples
pixel_samples_scale: f64 = undefined,
/// Defocus disk horizontal radius
defocus_disk_u: Vec3 = undefined,
/// Defocus disk vertical radius
defocus_disk_v: Vec3 = undefined,

pub fn init(self: *Camera) void {
    self.image_height = @max(1, @as(usize, @intFromFloat(@as(f64, @floatFromInt(self.image_width)) / self.aspect_ratio)));
    self.pixel_samples_scale = 1.0 / @as(f64, @floatFromInt(self.samples_per_pixel));

    self.center = self.look_from;

    // Determine viewport dimensions.
    const theta = std.math.degreesToRadians(self.vfov);
    const h = @tan(theta / 2);
    const viewport_height = 2 * h * self.focus_dist;
    const viewport_width = viewport_height * ((@as(f64, @floatFromInt(self.image_width)) / @as(f64, @floatFromInt(self.image_height))));

    // Calculate the u,v,w unit basis vectors for the camera coordinate frame.
    const w = self.look_from.sub(self.look_at).unitVector();
    const u = Vec3.cross(&self.v_up, &w).unitVector();
    const v = Vec3.cross(&w, &u);

    // Calculate the vectors across the horizontal and down the vertical viewport edges.
    const viewport_u = u.mul(viewport_width); // Vector across viewport horizontal edge
    const viewport_v = v.inv().mul(viewport_height); // Vector down viewport vertical edge

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    self.pixel_delta_u = viewport_u.div(self.image_width);
    self.pixel_delta_v = viewport_v.div(self.image_height);

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = self.center.sub(w.mul(self.focus_dist)).sub(viewport_u.div(2)).sub(viewport_v.div(2));
    self.pixel00_loc = viewport_upper_left.add((self.pixel_delta_u.add(self.pixel_delta_v)).mul(0.5));

    // Calculate the camera defocus disk basis vectors.
    const defocus_radius = self.focus_dist * @tan(std.math.degreesToRadians(self.defocus_angle / 2));
    self.defocus_disk_u = u.mul(defocus_radius);
    self.defocus_disk_v = v.mul(defocus_radius);
}

fn renderRow(
    self: *const Camera,
    y: usize,
    image: *const lib.Image,
    world: *const lib.HittableList,
    progress: std.Progress.Node,
) void {
    var buf: [32]u8 = undefined;
    const name = std.fmt.bufPrint(&buf, "Row {d}", .{y}) catch "Row ??";
    const progress_row = progress.start(name, self.image_width);
    for (0..self.image_width) |x| {
        var pixel_color = Color.zero;
        for (0..self.samples_per_pixel) |_| {
            const ray = self.getRay(x, y);
            pixel_color = pixel_color.add(rayColor(&ray, self.max_depth, world));
        }

        image.data[y * self.image_width + x] = lib.Pixel.fromColor(pixel_color.mul(self.pixel_samples_scale));
        progress_row.completeOne();
    }
    progress_row.end();
}

pub fn render(
    self: *const Camera,
    allocator: std.mem.Allocator,
    image: *const lib.Image,
    world: *const lib.HittableList,
) !void {
    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = allocator });
    defer pool.deinit();

    const progress = std.Progress.start(.{
        .root_name = "Ray Tracer",
        .estimated_total_items = self.image_height,
    });

    // queue a thread for each row
    for (0..self.image_height) |y| {
        try pool.spawn(renderRow, .{ self, y, image, world, progress });
    }

    var wait_group: std.Thread.WaitGroup = undefined;
    wait_group.reset();
    pool.waitAndWork(&wait_group);
}

/// Construct a camera ray originating from the defocus disk and directed at
/// randomly sampled point around the pixel location i, j.
fn getRay(self: *const Camera, i: usize, j: usize) Ray {
    const offset = sampleSquare();
    const pixel_sample = self.pixel00_loc
        .add(self.pixel_delta_u.mul(offset.x() + (@as(f64, @floatFromInt(i))))
        .add(self.pixel_delta_v.mul(offset.y() + @as(f64, @floatFromInt(j)))));
    return Ray{
        .origin = if (self.defocus_angle <= 0) self.center else self.defocusDiskSample(),
        .direction = pixel_sample.sub(self.center),
    };
}

/// Returns the vector to a random point in the [-.5,-.5]-[+.5,+.5] unit square.
fn sampleSquare() Vec3 {
    return Vec3.init(
        std.Random.float(lib.util.rnd, f64) - 0.5,
        std.Random.float(lib.util.rnd, f64) - 0.5,
        0,
    );
}

/// Returns a random point in the camera defocus disk.
fn defocusDiskSample(self: *const Camera) Vec3 {
    const p = Vec3.randomUnitDisk();
    return self.center.add(self.defocus_disk_u.mul(p.x())).add(self.defocus_disk_v.mul(p.y()));
}

fn rayColor(ray: *const Ray, depth: isize, world: *const lib.HittableList) Color {
    // If we've exceeded the ray bounce limit, no more light is gathered.
    if (depth <= 0) return Color.zero;

    var rec = lib.HitRecord{};
    // min of 0.001 to fix the "shadow acne" problem
    if (world.hit(ray, lib.Interval{ .min = 0.001, .max = std.math.inf(f64) }, &rec)) {
        // return rec.normal.add(Color.one).mul(0.5);
        var scattered = Ray{};
        var attenuation = Color.zero;
        if (rec.mat.scatter(ray, &rec, &attenuation, &scattered))
            return attenuation.mul(rayColor(&scattered, depth - 1, world));
        return Color.zero;
    }

    // background
    return lib.color.lerp(
        0.5 * (ray.direction.unitVector().y() + 1.0),
        Color.one,
        Color.init(0.5, 0.7, 1.0),
    );
}
