const std = @import("std");

pub fn parseIntData(allocator: std.mem.Allocator, data: []const u8) !std.ArrayList(isize) {
    var list = try std.ArrayList(isize).initCapacity(allocator, 256);
    var it = std.mem.tokenizeScalar(u8, data, '\n');
    while (it.next()) |token| {
        const parsed = try std.fmt.parseInt(isize, token, 10);
        try list.append(allocator, parsed);
    }
    return list;
}
