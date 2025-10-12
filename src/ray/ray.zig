const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;

pub const Ray = struct {
    origin: Vec3,
    direction: Point3,

    pub fn at(self: *const Ray, t: f64) Point3 {
        return Point3{ .e = self.origin.e + t * self.direction.e };
    }
};
