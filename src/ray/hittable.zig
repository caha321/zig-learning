const std = @import("std");
const Ray = @import("ray.zig").Ray;
const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;

const Error = error{NoHit};

// const no_of_hittables = 8;
// pub const hittables: [no_of_hittables]Sphere = [_]Sphere{.{}} ** 8;

pub const HitRecord = struct {
    p: Point3 = undefined,
    normal: Vec3 = undefined,
    t: f64 = undefined,
    frontFace: bool = undefined,

    pub fn setFaceNormal(self: *HitRecord, ray: *const Ray, outward_normal: *const Vec3) void {
        // Sets the hit record normal vector.
        // NOTE: the parameter `outward_normal` is assumed to have unit length.

        self.frontFace = Vec3.dot(&ray.direction, outward_normal) < 0;
        self.normal = if (self.frontFace) outward_normal.* else outward_normal.inv();
    }
};

pub const HittableList = struct {
    hittables: std.ArrayList(Sphere),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !HittableList {
        return HittableList{
            .hittables = try std.ArrayList(Sphere).initCapacity(allocator, 8),
            .allocator = allocator,
        };
    }

    pub fn add(self: *HittableList, obj: Sphere) !void {
        try self.hittables.append(self.allocator, obj);
    }

    pub fn hit(self: *const HittableList, ray: *const Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool {
        var temp_rec = HitRecord{};
        var hit_anything = false;
        var closest_so_far = ray_tmax;

        for (self.hittables.items) |*obj| {
            if (obj.hit(ray, ray_tmin, closest_so_far, &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec.* = temp_rec; // does this work?
            }
        }

        return hit_anything;
    }
};

pub const Sphere = struct {
    center: Point3,
    radius: f64,

    pub fn init(center: Point3, radius: f64) Sphere {
        return Sphere{ .center = center, .radius = @max(0, radius) };
    }

    pub fn hit(self: *const Sphere, ray: *const Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool {
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
};
