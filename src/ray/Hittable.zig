const std = @import("std");
const Ray = @import("Ray.zig");
const HitRecord = @import("HitRecord.zig");

// Interface from https://williamw520.github.io/2025/07/13/zig-interface-revisited.html
// + https://williamw520.github.io/2025/07/17/memory-efficient-zig-interface.html

impl: *anyopaque, // (1) pointer to the implementation
vtable: *const VTable,

// (2) implementation function pointers.
const VTable = struct {
    v_hit: *const fn (*anyopaque, ray: *const Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool,
};

// (3) Link up the implementation pointer and vtable functions
pub fn implBy(impl_obj: anytype) @This() {
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

pub fn hit(self: @This(), ray: *const Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool {
    return self.vtable.v_hit(self.impl, ray, ray_tmin, ray_tmax, rec);
}

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
