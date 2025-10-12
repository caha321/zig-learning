const vec3 = @import("vec3.zig");
const Ray = @import("Ray.zig");
const HitRecord = @import("HitRecord.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;

center: Point3,
radius: f64,

pub fn init(center: Point3, radius: f64) @This() {
    return @This(){ .center = center, .radius = @max(0, radius) };
}

pub fn hit(self: *const @This(), ray: *const Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool {
    const oc = self.center.minus(&ray.origin);
    const a = ray.direction.len_squared();
    const h = Vec3.dot(&ray.direction, &oc);
    const c = oc.len_squared() - (self.radius * self.radius);

    const discriminant = h * h - a * c;
    if (discriminant < 0) {
        return false;
    }

    const sqrtd = @sqrt(discriminant);

    // Find the nearest root that lies in the acceptable range.
    var root = (h - sqrtd) / a;
    if (root <= ray_tmin or ray_tmax <= root) {
        root = (h + sqrtd) / a;
        if (root <= ray_tmin or ray_tmax <= root) return false;
    }

    rec.t = root;
    rec.p = ray.at(rec.t);
    const outward_normal = rec.p.minus(&self.center).div_scalar(self.radius);
    rec.setFaceNormal(ray, &outward_normal);
    return true;
}
