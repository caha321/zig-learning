const std = @import("std");
const print = std.debug.print;

const input = @embedFile("day_03_input.txt");

// https://adventofcode.com/2020/day/3

const TreeCountOptions = struct {
    right: usize = 3,
    down: usize = 1,
    start_pos_horizontal: usize = 0,
};

pub fn count_trees(data: []const u8, options: TreeCountOptions) u64 {
    var it = std.mem.tokenizeScalar(u8, data, '\n');
    var tree_count: u64 = 0;
    var pos_horizontal: usize = options.start_pos_horizontal;
    var pos_vertical: usize = 0;

    while (it.next()) |line| {
        if (pos_vertical % options.down == 0) {
            const cur = line[pos_horizontal % line.len];
            tree_count += if (cur == '#') 1 else 0;
            pos_horizontal += options.right;
        }
        pos_vertical += 1;
    }

    return tree_count;
}

pub fn main() !void {
    var tree_count = count_trees(input, .{});
    tree_count *= count_trees(input, .{ .right = 1 });
    tree_count *= count_trees(input, .{ .right = 5 });
    tree_count *= count_trees(input, .{ .right = 7 });
    tree_count *= count_trees(input, .{ .right = 1, .down = 2 });

    print("Answer = {}\n", .{tree_count});
}

test "example input" {
    const test_input =
        \\..##.......
        \\#...#...#..
        \\.#....#..#.
        \\..#.#...#.#
        \\.#...##..#.
        \\..#.##.....
        \\.#.#.#....#
        \\.#........#
        \\#.##...#...
        \\#...##....#
        \\.#..#...#.#
    ;

    try std.testing.expectEqual(
        2,
        count_trees(test_input, .{ .right = 1 }),
    );

    try std.testing.expectEqual(
        7,
        count_trees(test_input, .{}),
    );

    try std.testing.expectEqual(
        3,
        count_trees(test_input, .{ .right = 5 }),
    );

    try std.testing.expectEqual(
        4,
        count_trees(test_input, .{ .right = 7 }),
    );

    try std.testing.expectEqual(
        2,
        count_trees(test_input, .{ .right = 1, .down = 2 }),
    );
}
