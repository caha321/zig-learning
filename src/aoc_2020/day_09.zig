const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const common = @import("common.zig");

const input = @embedFile("day_09_input.txt");

// https://adventofcode.com/2020/day/9

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var list = try common.parseIntData(allocator, input);
    defer list.deinit(allocator);

    //print("First number: {}\n", .{try findFirstNumber(list.items, 25)});
    print("Solution Part 2: {}\n", .{try findWeakness(list.items, 25)});
}

const Error = error{NumberNotFound};

pub fn isValid(data: []const isize, target: isize) bool {
    for (data) |first| {
        for (data) |second| {
            if (first != second and first + second == target) {
                return true;
            }
        }
    }

    return false;
}

fn findWeakness(data: []const isize, preamble_size: usize) !isize {
    const target = try findFirstNumber(data, preamble_size);
    print("Looking for weakness based on {}...\n", .{target});

    for (0..data.len) |start_index| {
        var sum: isize = 0;
        var min: isize = std.math.maxInt(isize);
        var max: isize = 0;
        for (data[start_index..]) |number| {
            sum += number;
            if (number < min) {
                min = number;
            }
            if (number > max) {
                max = number;
            }
            if (sum == target) {
                return min + max;
            }
        }
    }

    return Error.NumberNotFound;
}

fn findFirstNumber(data: []const isize, preamble_size: usize) !isize {
    var it = std.mem.window(isize, data, preamble_size + 1, 1);
    while (it.next()) |window| {
        const number_to_check = window[preamble_size];
        if (!isValid(window[0..preamble_size], number_to_check)) {
            return number_to_check;
        }
    }

    return Error.NumberNotFound;
}

test "example" {
    const data =
        \\35
        \\20
        \\15
        \\25
        \\47
        \\40
        \\62
        \\55
        \\65
        \\95
        \\102
        \\117
        \\150
        \\182
        \\127
        \\219
        \\299
        \\277
        \\309
        \\576
    ;

    const allocator = std.testing.allocator;
    var list = try common.parseIntData(allocator, data);
    defer list.deinit(allocator);

    try std.testing.expectEqual(127, try findFirstNumber(list.items, 5));
    try std.testing.expectEqual(62, try findWeakness(list.items, 5));
}
