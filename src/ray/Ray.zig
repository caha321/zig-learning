const Vec3 = @import("Vec3.zig");
const Point3 = Vec3.Point3;

origin: Vec3 = undefined,
direction: Point3 = undefined,

pub fn at(self: *const @This(), t: Point3.T) Point3 {
    return self.origin.add(self.direction.mul(t));
}
