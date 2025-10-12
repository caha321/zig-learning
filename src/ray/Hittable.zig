//! Interface for anything that can be hit with rays.
// Based on https://ziggit.dev/t/zig-interface-revisited/11013/13

const std = @import("std");
const Ray = @import("Ray.zig");
const HitRecord = @import("HitRecord.zig");
const Interval = @import("Interval.zig");

const Hittable = @This();

/// pointer to the implementation
impl: *anyopaque,
/// pointer to the vtable
vtable: *const VTable,

const VTable = struct {
    v_hit: *const fn (*anyopaque, ray: *const Ray, ray_t: Interval, rec: *HitRecord) bool,
};

// Link up the implementation pointer and vtable functions
pub fn implBy(impl: anytype) Hittable {
    const T = std.meta.Child(@TypeOf(impl));
    return .{
        .impl = @constCast(impl), // I had to add this @constCast here to fix compile error
        .vtable = &.{
            .v_hit = @ptrCast(&@field(T, "hit")),
        },
    };
}

// Public methods of the interface

pub fn hit(self: Hittable, ray: *const Ray, ray_t: Interval, rec: *HitRecord) bool {
    return self.vtable.v_hit(self.impl, ray, ray_t, rec);
}
