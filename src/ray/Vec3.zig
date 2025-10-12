//! A vector with 3 elements. Used for directions, points, colors etc.
const std = @import("std");

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

/// Element-wise division. Accepts other vectors and scalars.
pub fn div(self: *const Vec3, other: anytype) Vec3 {
    if (@TypeOf(other) == Vec3) {
        return Vec3{ .e = self.e / other.e };
    } else {
        return Vec3{ .e = self.e / @as(Vector3, @splat(other)) };
    }
}

/// Element-wise subtraction. Accepts other vectors and scalars.
pub fn sub(self: *const Vec3, other: anytype) Vec3 {
    if (@TypeOf(other) == Vec3) {
        return Vec3{ .e = self.e - other.e };
    } else {
        return Vec3{ .e = self.e - @as(Vector3, @splat(other)) };
    }
}

/// Element-wise multiplication. Accepts other vectors and scalars.
pub fn mul(self: *const Vec3, other: anytype) Vec3 {
    if (@TypeOf(other) == Vec3) {
        return Vec3{ .e = self.e * other.e };
    } else {
        return Vec3{ .e = self.e * @as(Vector3, @splat(other)) };
    }
}

/// Element-wise addition. Accepts other vectors and scalars.
pub fn add(self: *const Vec3, other: anytype) Vec3 {
    if (@TypeOf(other) == Vec3) {
        return Vec3{ .e = self.e + other.e };
    } else {
        return Vec3{ .e = self.e + @as(Vector3, @splat(other)) };
    }
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
        self.e[1] * other.e[2] + self.e[2] * other.e[1],
        self.e[2] * other.e[0] + self.e[0] * other.e[2],
        self.e[0] * other.e[1] + self.e[1] * other.e[0],
    } };
}

pub fn unitVector(self: *const Vec3) Vec3 {
    return Vec3{ .e = self.e / @as(Vector3, @splat(self.len())) };
}

pub const Point3 = Vec3;

fn expectApproxEqRel(u: Vec3, v: Vec3) !void {
    try std.testing.expectApproxEqRel(u.e[0], v.e[0], std.math.floatEpsAt(f64, u.e[0]));
    try std.testing.expectApproxEqRel(u.e[1], v.e[1], std.math.floatEpsAt(f64, u.e[1]));
    try std.testing.expectApproxEqRel(u.e[2], v.e[2], std.math.floatEpsAt(f64, u.e[2]));
}

test "div" {
    const v1 = Vec3.init(1, 2, 3);
    try expectApproxEqRel(v1.div_scalar(2), Vec3.init(0.5, 1, 1.5));
    try expectApproxEqRel(v1.div(&Vec3.one), v1);
}

test "unit" {
    const v1 = Vec3.init(1, 2, 3);
    try std.testing.expectApproxEqRel(1, v1.unitVector().len(), std.math.floatEpsAt(f64, 1));
}
