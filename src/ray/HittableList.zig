const std = @import("std");
const HitRecord = @import("HitRecord.zig");
const Hittable = @import("Hittable.zig");
const Ray = @import("Ray.zig");

const HittableList = @This();

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
            rec.* = temp_rec;
        }
    }

    return hit_anything;
}
