pub const Vec3 = struct {
    e: @Vector(3, f64),

    const zero: Vec3 = .{ .e = @Vector(3, f64){ 0, 0, 0 } };

    pub fn x(self: *const Vec3) f64 {
        return self.e[0];
    }

    pub fn y(self: *const Vec3) f64 {
        return self.e[1];
    }

    pub fn z(self: *const Vec3) f64 {
        return self.e[2];
    }

    pub fn len(self: *const Vec3) f64 {
        @sqrt(self.len_squared());
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
        return self.e / self.len();
    }
};
