const std = @import("std");

const Vector3 = @Vector(3, f64);

pub const Vec3 = struct {
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

    pub fn div(self: *const Vec3, other: *const Vec3) Vec3 {
        return Vec3{ .e = self.e / other.e };
    }

    pub fn div_scalar(self: *const Vec3, t: f64) Vec3 {
        return Vec3{ .e = self.e / @as(Vector3, @splat(t)) };
    }

    pub fn minus(self: *const Vec3, other: *const Vec3) Vec3 {
        return Vec3{ .e = self.e - other.e };
    }

    pub fn minus_scalar(self: *const Vec3, t: f64) Vec3 {
        return Vec3{ .e = self.e - @as(Vector3, @splat(t)) };
    }

    pub fn mul(self: *const Vec3, other: *const Vec3) Vec3 {
        return Vec3{ .e = self.e * other.e };
    }

    pub fn mul_scalar(self: *const Vec3, t: f64) Vec3 {
        return Vec3{ .e = self.e * @as(Vector3, @splat(t)) };
    }

    pub fn plus(self: *const Vec3, other: *const Vec3) Vec3 {
        return Vec3{ .e = self.e + other.e };
    }

    pub fn plus_scalar(self: *const Vec3, t: f64) Vec3 {
        return Vec3{ .e = self.e + @as(Vector3, @splat(t)) };
    }

    pub fn len(self: *const Vec3) f64 {
        return @sqrt(self.len_squared());
    }

    pub fn len_squared(self: *const Vec3) f64 {
        return self.e[0] * self.e[0] + self.e[1] * self.e[1] + self.e[2] * self.e[2];
    }

    pub fn double_dot(self: *const Vec3, other: *const Vec3) f64 {
        return self.e[0] * other.e[0] + self.e[1] * other.e[1] + self.e[2] * other.e[2];
    }

    pub fn cross(self: *const Vec3, other: *const Vec3) Vec3 {
        return Vec3{ .e = .{
            self.e[1] * other.e[2] + self.e[2] * other.e[1],
            self.e[2] * other.e[0] + self.e[0] * other.e[2],
            self.e[0] * other.e[1] + self.e[1] * other.e[0],
        } };
    }

    pub fn unit_vector(self: *const Vec3) Vec3 {
        return Vec3{ .e = self.e / @as(Vector3, @splat(self.len())) };
    }
};

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
    try std.testing.expectApproxEqRel(1, v1.unit_vector().len(), std.math.floatEpsAt(f64, 1));
}
