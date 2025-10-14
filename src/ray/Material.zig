const std = @import("std");
const Color = @import("color.zig").Color;
const HitRecord = @import("HitRecord.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");
const util = @import("util.zig");

const Material = @This();

const MaterialType = enum { lambertian, metal };

const MaterialError = error{UnknownMaterialType};

/// type definition for JSON parsing
pub const MaterialJson = struct {
    name: []u8,
    type_: []u8,
    albedo: [3]f64,
    fuzz: ?f64 = null,
};

albedo: Color,
fuzz: f64,
material_type: MaterialType,

pub fn fromJson(mat_json: MaterialJson) !Material {
    const material_type = std.meta.stringToEnum(MaterialType, mat_json.type_) orelse return MaterialError.UnknownMaterialType;
    const albedo = Color.init(mat_json.albedo[0], mat_json.albedo[1], mat_json.albedo[2]);
    return Material{
        .material_type = material_type,
        .albedo = albedo,
        .fuzz = mat_json.fuzz orelse 0.0,
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

pub fn parseMaterialsJson(allocator: std.mem.Allocator, materials: *std.StringArrayHashMap(Material)) !void {
    // Open the JSON file
    const buffer = try util.parseFile(allocator, "data/materials.json");
    defer allocator.free(buffer);

    const parsed = try std.json.parseFromSlice([]Material.MaterialJson, allocator, buffer, .{});
    defer parsed.deinit();

    const json_materials: []Material.MaterialJson = parsed.value;
    for (json_materials) |entry| {
        // copy name so we can use it as a key
        const name = try allocator.alloc(u8, entry.name.len);
        @memcpy(name, entry.name);

        const mat = try Material.fromJson(entry);
        try materials.put(name, mat);
        std.log.info("Added material '{s}'", .{entry.name});
    }
}
