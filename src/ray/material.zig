const std = @import("std");
const Color = @import("color.zig").Color;
const HitRecord = @import("HitRecord.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");
const util = @import("util.zig");

const MaterialError = error{
    UnknownMaterialType,
    AlbedoMissing,
    RefractionIndexMissing,
};

/// type definition for JSON parsing
const MaterialJson = struct {
    name: []u8,
    type_: []u8,
    albedo: ?[3]f64 = null,
    fuzz: ?f64 = null,
    refraction_index: ?f64 = null,
};

const MaterialType = enum { lambertian, metal, dielectric };

pub const Material = union(MaterialType) {
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,

    pub fn fromJson(mat_json: MaterialJson) !Material {
        const material_type = std.meta.stringToEnum(MaterialType, mat_json.type_) orelse return MaterialError.UnknownMaterialType;

        return switch (material_type) {
            .dielectric => Material{ .dielectric = Dielectric{
                .refraction_index = mat_json.refraction_index orelse return MaterialError.RefractionIndexMissing,
            } },
            .lambertian => Material{ .lambertian = Lambertian{
                .albedo = try parseAlbedo(mat_json),
            } },
            .metal => Material{ .metal = Metal{
                .albedo = try parseAlbedo(mat_json),
                .fuzz = mat_json.fuzz orelse 0.0,
            } },
        };
    }

    pub fn scatter(self: *const Material, ray: *const Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
        switch (self.*) {
            .lambertian => |inner| {
                var scatter_direction = rec.normal.add(Vec3.randomUnitVector());

                // Catch degenerate scatter direction
                if (scatter_direction.nearZero())
                    scatter_direction = rec.normal;

                scattered.* = Ray{ .origin = rec.p, .direction = scatter_direction };
                attenuation.* = inner.albedo;
                return true;
            },
            .metal => |inner| {
                const reflected = ray.direction.reflect(&rec.normal).add(Vec3.randomUnitVector().mul(inner.fuzz));
                scattered.* = Ray{ .origin = rec.p, .direction = reflected };
                attenuation.* = inner.albedo;
                return scattered.direction.dot(&rec.normal) > 0;
            },
            .dielectric => |inner| {
                const ri = if (rec.frontFace) 1.0 / inner.refraction_index else inner.refraction_index;

                const unit_direction = ray.direction.unitVector();
                const cos_theta = @min(Vec3.dot(&unit_direction.inv(), &rec.normal), 1.0);
                const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);

                const cannot_refract = ri * sin_theta > 1.0;
                const direction = if (cannot_refract or relectance(cos_theta, ri) > util.rnd.float(f64))
                    unit_direction.reflect(&rec.normal)
                else
                    unit_direction.refract(&rec.normal, ri);

                scattered.* = Ray{ .origin = rec.p, .direction = direction };
                attenuation.* = Color.one;
                return true;
            },
        }
    }
};

const Lambertian = struct {
    albedo: Color,
};

const Metal = struct {
    albedo: Color,
    fuzz: f64,
};

const Dielectric = struct {
    /// Refractive index in vacuum or air, or the ratio of the material's refractive index over
    /// the refractive index of the enclosing media
    refraction_index: f64,
};

fn parseAlbedo(mat_json: MaterialJson) !Color {
    return if (mat_json.albedo) |albedo|
        Color.init(albedo[0], albedo[1], albedo[2])
    else
        MaterialError.AlbedoMissing;
}

fn relectance(cosine: f64, refraction_index: f64) f64 {
    // Use Schlick's approximation for reflectance.
    var r0 = (1 - refraction_index) / (1 + refraction_index);
    r0 = r0 * r0;
    return r0 + (1 - r0) * std.math.pow(f64, 1 - cosine, 5);
}

pub fn parseMaterialsJson(allocator: std.mem.Allocator, materials: *std.StringArrayHashMap(Material)) !void {
    // Open the JSON file
    const buffer = try util.parseFile(allocator, "data/materials.json");
    defer allocator.free(buffer);

    const parsed = try std.json.parseFromSlice([]MaterialJson, allocator, buffer, .{});
    defer parsed.deinit();

    const json_materials: []MaterialJson = parsed.value;
    for (json_materials) |entry| {
        // copy name so we can use it as a key
        const name = try allocator.alloc(u8, entry.name.len);
        @memcpy(name, entry.name);

        const mat = try Material.fromJson(entry);
        try materials.put(name, mat);
        std.log.info("Added material '{s}'", .{entry.name});
    }
}
