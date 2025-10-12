const std = @import("std");
const assert = std.debug.assert;
const time = std.time;
const Timer = time.Timer;
const print = std.debug.print;
const common = @import("common.zig");

const input = @embedFile("day_11_input.txt");

// https://adventofcode.com/2020/day/11

pub fn main() !void {
    var grid = Grid{};
    grid.load(input);

    var timer = try Timer.start();
    while (grid.stepRuleFirst()) {
        print("1 - it {}\r", .{grid.iteration});
    }

    const elapsed1: f64 = @floatFromInt(timer.read());
    print(
        "Occupied seats (Rule 1): {} after {} iterations in {d:.3}ms\n",
        .{ grid.totalOccupied(), grid.iteration, elapsed1 / time.ns_per_ms },
    );

    grid.reset();
    timer.reset();
    while (grid.stepRuleSecond()) {
        print("2 - it {}\r", .{grid.iteration});
    }
    const elapsed2: f64 = @floatFromInt(timer.read());
    print(
        "Occupied seats (Rule 2): {} after {} iterations in {d:.3}ms\n",
        .{ grid.totalOccupied(), grid.iteration, elapsed2 / time.ns_per_ms },
    );
}

const Error = error{ InvalidXPosition, InvalidYPosition, NotFound };

const GridElement = enum(u8) { floor = '.', empty = 'L', occupied = '#' };
const Position = struct { x: isize, y: isize };

const grid_size = 128;

const Grid = struct {
    state: [grid_size][grid_size]GridElement = .{.{.floor} ** grid_size} ** grid_size,
    iteration: usize = 0,

    fn reset(self: *Grid) void {
        self.iteration = 0;
        for (0..grid_size) |y| {
            for (0..grid_size) |x| {
                if (self.state[y][x] == .occupied) self.state[y][x] = .empty;
            }
        }
    }

    fn load(self: *Grid, data: []const u8) void {
        var it_row = std.mem.tokenizeScalar(u8, data, '\n');
        var y: usize = 0;
        while (it_row.next()) |row| {
            for (row, 0..) |element, x| {
                self.state[y][x] = @enumFromInt(element);
            }
            y += 1;
        }
    }

    fn get(self: *const Grid, x: isize, y: isize) !GridElement {
        if (x < 0 or x >= self.state.len) return Error.InvalidXPosition;
        if (y < 0 or y >= self.state.len) return Error.InvalidYPosition;

        return self.state[@as(usize, @abs(y))][@as(usize, @abs(x))];
    }

    fn findFirst(self: *const Grid, element: GridElement) !Position {
        for (0..grid_size) |y| {
            for (0..grid_size) |x| {
                if (self.state[y][x] == element)
                    return .{ .x = @intCast(x), .y = @intCast(y) };
            }
        }
        return Error.NotFound;
    }

    fn isOccupied(self: *const Grid, x: isize, y: isize) bool {
        const element = self.get(x, y) catch return false;
        return switch (element) {
            .occupied => true,
            else => false,
        };
    }

    fn isOccupiedRay(self: *const Grid, x_start: isize, y_start: isize, x_direction: isize, y_direction: isize) bool {
        var x: isize = x_start;
        var y: isize = y_start;
        while (true) {
            x += x_direction;
            y += y_direction;
            const element = self.get(x, y) catch return false;
            if (element == .occupied) return true;
            if (element == .empty) return false;
        }
    }

    fn noOfOccupiedRay(self: *const Grid, x: isize, y: isize) usize {
        var sum: usize = 0;
        const directions = [_]isize{ -1, 0, 1 };
        // for loop over range -1..2 does not work, captured values are of type usize
        for (directions) |x_direction| {
            for (directions) |y_direction| {
                if (x_direction == 0 and y_direction == 0) continue;
                const result = self.isOccupiedRay(x, y, x_direction, y_direction);
                sum += if (result) 1 else 0;
            }
        }

        return sum;
    }

    fn noOfOccupiedImmediate(self: *const Grid, x: isize, y: isize) usize {
        var sum: usize = 0;
        const offsets = [_]isize{ -1, 0, 1 };
        // for loop over range -1..2 does not work, captured values are of type usize
        for (offsets) |x_offset| {
            for (offsets) |y_offset| {
                if (x_offset == 0 and y_offset == 0) continue;
                const result = self.isOccupied(x - x_offset, y - y_offset);
                sum += if (result) 1 else 0;
            }
        }

        return sum;
    }

    fn totalOccupied(self: *const Grid) usize {
        var total: usize = 0;
        for (0..grid_size) |y| {
            for (0..grid_size) |x| {
                if (self.state[y][x] == .occupied) total += 1;
            }
        }
        return total;
    }

    fn stepRuleFirst(self: *Grid) bool {
        var new_state: [grid_size][grid_size]GridElement = .{.{.floor} ** grid_size} ** grid_size;
        var changed = false;

        for (self.state, 0..) |row, y| {
            for (row, 0..) |element, x| {
                if (element == .floor) continue;

                const occ = self.noOfOccupiedImmediate(@intCast(x), @intCast(y));
                new_state[y][x] = blk: {
                    if (element == .empty and occ == 0) {
                        changed = true;
                        break :blk GridElement.occupied;
                    } else if (element == .occupied and occ >= 4) {
                        changed = true;
                        break :blk GridElement.empty;
                    } else {
                        break :blk element; // no change
                    }
                };
            }
        }

        self.state = new_state;
        self.iteration += 1;

        return changed;
    }

    fn stepRuleSecond(self: *Grid) bool {
        var new_state: [grid_size][grid_size]GridElement = .{.{.floor} ** grid_size} ** grid_size;
        var changed = false;

        for (self.state, 0..) |row, y| {
            for (row, 0..) |element, x| {
                if (element == .floor) continue;

                const occ = self.noOfOccupiedRay(@intCast(x), @intCast(y));
                new_state[y][x] = blk: {
                    if (element == .empty and occ == 0) {
                        changed = true;
                        break :blk GridElement.occupied;
                    } else if (element == .occupied and occ >= 5) {
                        changed = true;
                        break :blk GridElement.empty;
                    } else {
                        break :blk element; // no change
                    }
                };
            }
        }

        self.state = new_state;
        self.iteration += 1;

        return changed;
    }

    fn printDebug(self: *const Grid) void {
        print("\nGrid iteration {}:\n\n", .{self.iteration});
        for (self.state) |row| {
            for (row) |element| {
                print("{c}", .{@intFromEnum(element)});
            }
            print("\n", .{});
        }
    }
};

test "example" {
    const data =
        \\L.LL.LL.LL
        \\LLLLLLL.LL
        \\L.L.L..L..
        \\LLLL.LL.LL
        \\L.LL.LL.LL
        \\L.LLLLL.LL
        \\..L.L.....
        \\LLLLLLLLLL
        \\L.LLLLLL.L
        \\L.LLLLL.LL
    ;
    var grid = Grid{};
    grid.load(data);
    grid.printDebug();
    try std.testing.expectEqual(grid.state[0][0], GridElement.empty);

    var changed = grid.stepRuleFirst();
    grid.printDebug();
    try std.testing.expectEqual(true, changed);
    try std.testing.expectEqual(grid.state[0][0], GridElement.occupied);
    try std.testing.expectEqual(2, grid.noOfOccupiedImmediate(0, 0));

    changed = grid.stepRuleFirst();
    grid.printDebug();
    try std.testing.expectEqual(true, changed);
    try std.testing.expectEqual(grid.state[0][2], GridElement.empty);
    try std.testing.expectEqual(1, grid.noOfOccupiedImmediate(0, 0));

    while (changed) {
        changed = grid.stepRuleFirst();
    }
    //grid.printDebug();
    try std.testing.expectEqual(37, grid.totalOccupied());
}

test "ray occupation 1" {
    var grid = Grid{};
    grid.load(
        \\.......#.
        \\...#.....
        \\.#.......
        \\.........
        \\..#L....#
        \\....#....
        \\.........
        \\#........
        \\...#.....
    );
    //grid.printDebug();
    try std.testing.expectEqual(true, grid.isOccupiedRay(0, 0, 1, 0));
    try std.testing.expectEqual(2, grid.noOfOccupiedRay(0, 0));
    try std.testing.expectEqual(GridElement.empty, try grid.get(3, 4));
    try std.testing.expectEqual(8, grid.noOfOccupiedRay(3, 4));
}

test "ray occupation 2" {
    var grid = Grid{};
    grid.load(
        \\.............
        \\.L.L.#.#.#.#.
        \\.............
    );

    try std.testing.expectEqual(GridElement.empty, try grid.get(1, 1));
    try std.testing.expectEqual(0, grid.noOfOccupiedRay(1, 1));
}

test "ray full" {
    const data =
        \\L.LL.LL.LL
        \\LLLLLLL.LL
        \\L.L.L..L..
        \\LLLL.LL.LL
        \\L.LL.LL.LL
        \\L.LLLLL.LL
        \\..L.L.....
        \\LLLLLLLLLL
        \\L.LLLLLL.L
        \\L.LLLLL.LL
    ;
    var grid = Grid{};
    grid.load(data);
    while (grid.stepRuleSecond()) {}

    try std.testing.expectEqual(26, grid.totalOccupied());
    grid.reset();
    try std.testing.expectEqual(0, grid.totalOccupied());
}
