const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");

const input = @embedFile("day_01_input.txt"); // tip from https://kristoff.it/blog/advent-of-code-zig/

// https://adventofcode.com/2020/day/1

const CalculationError = error{NoSolution};

pub fn mulTwo(comptime T: type, data: []const T, target: T) !T {
    for (data, 0..) |outer_value, outer_index| {
        for (data, 0..) |inner_value, inner_index| {
            if ((outer_index != inner_index) and (outer_value + inner_value == target)) {
                return inner_value * outer_value;
            }
        }
    }

    return CalculationError.NoSolution;
}

pub fn mulThree(data: []const isize, target: isize) !isize {
    for (data) |outer_value| {
        for (data) |inner_value| {
            for (data) |most_inner_value| {
                if (outer_value + inner_value + most_inner_value == target) {
                    return inner_value * outer_value * most_inner_value;
                }
            }
        }
    }

    return CalculationError.NoSolution;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var list = try common.parseIntData(allocator, input);
    defer list.deinit(allocator);

    print("mul 2 = {}\n", .{try mulTwo(isize, list.items, 2020)});
    print("mul 3 = {}\n", .{try mulThree(list.items, 2020)});
}

test "two entries" {
    const items = [_]isize{ 1721, 979, 366, 299, 675, 1456 };
    try std.testing.expectEqual(
        514579,
        try mulTwo(isize, &items, 2020),
    );
}

test "two entries failing" {
    const items = [_]isize{ 123, 442 };

    try std.testing.expectError(
        error.NoSolution,
        mulTwo(isize, &items, 2020),
    );
}

test "three entries" {
    const items = [_]isize{ 1721, 979, 366, 299, 675, 1456 };

    try std.testing.expectEqual(
        241861950,
        try mulThree(&items, 2020),
    );
}
