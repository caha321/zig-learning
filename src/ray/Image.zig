const std = @import("std");

const color = @import("color.zig");
const Pixel = color.Pixel;

const Image = @This();

data: []Pixel,
width: usize,
height: usize,

pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Image {
    return Image{
        .data = try allocator.alloc(Pixel, width * height),
        .width = width,
        .height = height,
    };
}

pub fn write(self: *const Image, writer: *std.io.Writer) !void {
    // write header
    try writer.print("P3\n{} {}\n255\n", .{ self.width, self.height });

    // write all pixels
    for (self.data) |pixel| {
        try pixel.write(writer);
    }
}
