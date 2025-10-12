const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;

origin: Vec3,
direction: Point3,

pub fn at(self: *const @This(), t: f64) Point3 {
    return self.origin.plus(&self.direction.mul_scalar(t));
}
