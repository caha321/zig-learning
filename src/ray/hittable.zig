const std = @import("std");
const Ray = @import("ray.zig").Ray;
const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;

const Error = error{NoHit};

// Interface from https://williamw520.github.io/2025/07/13/zig-interface-revisited.html
// + https://williamw520.github.io/2025/07/17/memory-efficient-zig-interface.html

/// Interface for any hittables
pub const Hittable = struct {
    impl: *anyopaque, // (1) pointer to the implementation
    vtable: *const VTable,

    // (2) implementation function pointers.
    const VTable = struct {
        v_hit: *const fn (*anyopaque, ray: *const Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool,
    };

    // (3) Link up the implementation pointer and vtable functions
    pub fn implBy(impl_obj: anytype) Hittable {
        const delegate = HittableDelegate(impl_obj);
        const vtable = VTable{
            .v_hit = delegate.hit,
        };
        return .{
            .impl = @constCast(impl_obj), // I had to add this @constCast here to fix compile error
            .vtable = &vtable,
        };
    }

    // (4) Public methods of the interface

    pub fn hit(self: Hittable, ray: *const Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool {
        return self.vtable.v_hit(self.impl, ray, ray_tmin, ray_tmax, rec);
    }
};

// (5) Delegate to turn the opaque pointer back to the implementation.
inline fn HittableDelegate(impl_obj: anytype) type {
    return struct {
        fn hit(impl: *anyopaque, ray: *const Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool {
            return TPtr(@TypeOf(impl_obj), impl).hit(ray, ray_tmin, ray_tmax, rec);
        }
    };
}

fn TPtr(T: type, opaque_ptr: *anyopaque) T {
    return @as(T, @ptrCast(@alignCast(opaque_ptr)));
}

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
    hittables: std.ArrayList(Hittable),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !HittableList {
        return HittableList{
            .hittables = try std.ArrayList(Hittable).initCapacity(allocator, 8),
            .allocator = allocator,
        };
    }

    pub fn add(self: *HittableList, obj: Hittable) !void {
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
