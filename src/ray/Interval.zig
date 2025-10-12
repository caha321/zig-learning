const math = @import("std").math;

min: f64,
max: f64,

pub const empty = @This(){ .min = math.inf(f64), .max = -math.inf(f64) };
pub const universe = @This(){ .min = -math.inf(f64), .max = math.inf(f64) };

pub fn size(self: @This()) f64 {
    return self.max - self.min;
}

pub fn contains(self: @This(), x: f64) bool {
    return self.min <= x and x <= self.max;
}

pub fn surrounds(self: @This(), x: f64) bool {
    return self.min < x and x < self.max;
}
