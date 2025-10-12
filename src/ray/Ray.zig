const Vec3 = @import("Vec3.zig");
const Point3 = Vec3.Point3;

origin: Vec3,
direction: Point3,

pub fn at(self: *const @This(), t: f64) Point3 {
    return self.origin.add(self.direction.mul(t));
}
