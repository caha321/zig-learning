const Color = @import("color.zig").Color;
const HitRecord = @import("HitRecord.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Material = @This();

const MaterialType = enum { lambertian, metal };

albedo: Color,
fuzz: f64,
material_type: MaterialType,

pub fn initLambertian(albedo: Color) Material {
    return Material{
        .material_type = .lambertian,
        .albedo = albedo,
        .fuzz = 0,
    };
}

pub fn initMetal(albedo: Color, fuzz: f64) Material {
    return Material{
        .material_type = .metal,
        .albedo = albedo,
        .fuzz = if (fuzz < 1) fuzz else 1,
    };
}

pub fn scatter(self: *const Material, ray: *const Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
    switch (self.material_type) {
        .lambertian => {
            var scatter_direction = rec.normal.add(Vec3.randomUnitVector());

            // Catch degenerate scatter direction
            if (scatter_direction.nearZero())
                scatter_direction = rec.normal;

            scattered.* = Ray{
                .origin = rec.p,
                .direction = scatter_direction,
            };
            attenuation.* = self.albedo;
            return true;
        },
        .metal => {
            const reflected = ray.direction.reflect(&rec.normal).add(Vec3.randomUnitVector().mul(self.fuzz));
            scattered.* = Ray{
                .origin = rec.p,
                .direction = reflected,
            };
            attenuation.* = self.albedo;
            return scattered.direction.dot(&rec.normal) > 0;
        },
    }
}
