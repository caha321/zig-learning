const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
const HitRecord = @import("HitRecord.zig");
const Point3 = Vec3.Point3;
const Interval = @import("Interval.zig");

const Sphere = @This();

center: Point3,
radius: f64,

pub fn init(center: Point3, radius: f64) Sphere {
    return Sphere{ .center = center, .radius = @max(0, radius) };
}

// implements the Hittable interface
pub fn hit(self: *const Sphere, ray: *const Ray, ray_t: Interval, rec: *HitRecord) bool {
    const oc = self.center.sub(ray.origin);
    const a = ray.direction.lenSquared();
    const h = Vec3.dot(&ray.direction, &oc);
    const c = oc.lenSquared() - (self.radius * self.radius);

    const discriminant = h * h - a * c;
    if (discriminant < 0) {
        return false;
    }

    const sqrtd = @sqrt(discriminant);

    // Find the nearest root that lies in the acceptable range.
    var root = (h - sqrtd) / a;
    if (!ray_t.surrounds(root)) {
        root = (h + sqrtd) / a;
        if (!ray_t.surrounds(root)) return false;
    }

    rec.t = root;
    rec.p = ray.at(rec.t);
    const outward_normal = rec.p.sub(self.center).div(self.radius);
    rec.setFaceNormal(ray, &outward_normal);
    return true;
}
