const std = @import("std");
const print = std.debug.print;

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

pub fn mulThree(data: []const i64, target: i64) !i64 {
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
    var list = try std.ArrayList(i64).initCapacity(allocator, 1024);
    defer list.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |token| {
        const parsed = try std.fmt.parseInt(i64, token, 10);
        try list.append(allocator, parsed);
    }

    print("mul 2 = {}\n", .{try mulTwo(i64, list.items, 2020)});
    print("mul 3 = {}\n", .{try mulThree(list.items, 2020)});
}

test "two entries" {
    const items = [_]i64{ 1721, 979, 366, 299, 675, 1456 };
    const result = try mulTwo(i64, &items, 2020);

    try std.testing.expect(result == 514579);
}

test "two entries failing" {
    const items = [_]i64{ 123, 442 };
    const result = mulTwo(i64, &items, 2020);

    try std.testing.expect(result == error.NoSolution);
}

test "three entries" {
    const items = [_]i64{ 1721, 979, 366, 299, 675, 1456 };
    const result = try mulThree(&items, 2020);

    try std.testing.expect(result == 241861950);
}
