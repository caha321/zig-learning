const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");
const Material = @import("Material.zig");
const Point3 = Vec3.Point3;

p: Point3 = undefined,
normal: Vec3 = undefined,
mat: *const Material = undefined,
t: f64 = undefined,
frontFace: bool = undefined,

pub fn setFaceNormal(self: *@This(), ray: *const Ray, outward_normal: *const Vec3) void {
    // Sets the hit record normal vector.
    // NOTE: the parameter `outward_normal` is assumed to have unit length.

    self.frontFace = Vec3.dot(&ray.direction, outward_normal) < 0;
    self.normal = if (self.frontFace) outward_normal.* else outward_normal.inv();
}
