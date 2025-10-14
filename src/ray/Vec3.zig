//! A vector with 3 elements. Used for directions, points, colors etc.
const std = @import("std");
const util = @import("util.zig");

const Vector3 = @Vector(3, f64);

const Vec3 = @This();

e: Vector3,

pub const zero: Vec3 = .{ .e = Vector3{ 0, 0, 0 } };
pub const one: Vec3 = .{ .e = Vector3{ 1, 1, 1 } };

pub fn init(x_: f64, y_: f64, z_: f64) Vec3 {
    return Vec3{ .e = .{ x_, y_, z_ } };
}

pub fn x(self: *const Vec3) f64 {
    return self.e[0];
}

pub fn y(self: *const Vec3) f64 {
    return self.e[1];
}

pub fn z(self: *const Vec3) f64 {
    return self.e[2];
}

pub fn inv(self: *const Vec3) Vec3 {
    return Vec3{ .e = -self.e };
}

fn getOther(other: anytype) Vector3 {
    return switch (@typeInfo(@TypeOf(other))) {
        .float, .comptime_float => @as(Vector3, @splat(other)),
        .int, .comptime_int => @as(Vector3, @splat(@floatFromInt(other))),
        else => other.e,
    };
}

/// Element-wise division. Accepts other vectors and scalars.
pub fn div(self: *const Vec3, other: anytype) Vec3 {
    return Vec3{ .e = self.e / getOther(other) };
}

/// Element-wise subtraction. Accepts other vectors and scalars.
pub fn sub(self: *const Vec3, other: anytype) Vec3 {
    return Vec3{ .e = self.e - getOther(other) };
}

/// Element-wise multiplication. Accepts other vectors and scalars.
pub fn mul(self: *const Vec3, other: anytype) Vec3 {
    return Vec3{ .e = self.e * getOther(other) };
}

/// Element-wise addition. Accepts other vectors and scalars.
pub fn add(self: *const Vec3, other: anytype) Vec3 {
    return Vec3{ .e = self.e + getOther(other) };
}

pub fn len(self: *const Vec3) f64 {
    return @sqrt(self.lenSquared());
}

pub fn lenSquared(self: *const Vec3) f64 {
    return self.e[0] * self.e[0] + self.e[1] * self.e[1] + self.e[2] * self.e[2];
}

pub fn dot(self: *const Vec3, other: *const Vec3) f64 {
    return self.e[0] * other.e[0] + self.e[1] * other.e[1] + self.e[2] * other.e[2];
}

pub fn cross(self: *const Vec3, other: *const Vec3) Vec3 {
    return Vec3{ .e = .{
        self.e[1] * other.e[2] - self.e[2] * other.e[1],
        self.e[2] * other.e[0] - self.e[0] * other.e[2],
        self.e[0] * other.e[1] - self.e[1] * other.e[0],
    } };
}

pub fn unitVector(self: *const Vec3) Vec3 {
    return Vec3{ .e = self.e / @as(Vector3, @splat(self.len())) };
}

/// Returns a random vector where each element is in [0,1)
pub fn random() Vec3 {
    return Vec3{ .e = .{
        util.rnd.float(f64),
        util.rnd.float(f64),
        util.rnd.float(f64),
    } };
}

/// Returns a random vector where each element is in [min,max)
pub fn randomMinMax(min: f64, max: f64) Vec3 {
    return Vec3{ .e = .{
        util.randomFloatMinMax(f64, min, max),
        util.randomFloatMinMax(f64, min, max),
        util.randomFloatMinMax(f64, min, max),
    } };
}

/// Return a random vector inside the unit sphere using a rejection method.
pub fn randomUnitVector() Vec3 {
    while (true) {
        const p = Vec3.randomMinMax(-1, 1);
        const lensq = p.lenSquared();
        if (1e-160 < lensq and lensq <= 1) return p.div(@sqrt(lensq));
    }
}

pub fn randomOnHemisphere(normal: Vec3) Vec3 {
    const on_unit_sphere = randomUnitVector();
    if (dot(&on_unit_sphere, &normal) > 0.0) { // In the same hemisphere as the normal
        return on_unit_sphere;
    } else {
        return on_unit_sphere.inv();
    }
}

pub fn reflect(self: *const Vec3, normal: *const Vec3) Vec3 {
    return self.sub(normal.mul(2.0 * self.dot(normal)));
}

pub fn refract(self: *const Vec3, normal: *const Vec3, etai_over_estat: f64) Vec3 {
    const cos_theta: f64 = @min(self.inv().dot(normal), 1.0);
    const r_out_perp = self.add(normal.mul(cos_theta)).mul(etai_over_estat);
    const r_out_parallel = normal.mul(-@sqrt(@abs(1.0 - r_out_perp.lenSquared())));
    return r_out_perp.add(r_out_parallel);
}

pub fn nearZero(self: *const Vec3) bool {
    return @reduce(.And, @abs(self.e) < @as(Vector3, @splat(1e-8)));
}

pub const Point3 = Vec3;

fn expectApproxEqRel(expected: Vec3, actual: Vec3) !void {
    try std.testing.expectApproxEqRel(expected.e[0], actual.e[0], std.math.floatEpsAt(f64, expected.e[0]));
    try std.testing.expectApproxEqRel(expected.e[1], actual.e[1], std.math.floatEpsAt(f64, expected.e[1]));
    try std.testing.expectApproxEqRel(expected.e[2], actual.e[2], std.math.floatEpsAt(f64, expected.e[2]));
}

test "div" {
    const v1 = Vec3.init(1, 2, 3);
    try expectApproxEqRel(Vec3.init(0.5, 1, 1.5), v1.div(2));
    try expectApproxEqRel(Vec3.init(0.5, 1, 1.5), v1.div(2.0));
    try expectApproxEqRel(v1, v1.div(&Vec3.one));
}

test "unit" {
    const v1 = Vec3.init(1, 2, 3);
    try std.testing.expectApproxEqRel(1, v1.unitVector().len(), std.math.floatEpsAt(f64, 1));
}

test "near zero" {
    try std.testing.expect(nearZero(&Vec3.zero));
    try std.testing.expect(!nearZero(&Vec3.one));
}

test "cross" {
    const a = Vec3.init(2, 3, 4);
    const b = Vec3.init(5, 6, 7);
    const expected = Vec3.init(-3, 6, -3);

    try expectApproxEqRel(expected, a.cross(&b));
    try expectApproxEqRel(expected.inv(), b.cross(&a));
}
