const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const common = @import("common.zig");

const input = @embedFile("day_11_input.txt");

// https://adventofcode.com/2020/day/11

pub fn main() !void {
    var grid = Grid{};
    grid.load(input);

    while (grid.stepRuleFirst()) {
        print("it {}\r", .{grid.iteration});
    }

    print("Occupied seats: {}\n", .{grid.totalOccupied()});
}

const Error = error{ InvalidXPosition, InvalidYPosition };

const GridElement = enum(u8) {
    floor = '.',
    empty = 'L',
    occupied = '#',
};

const grid_size = 128;

const Grid = struct {
    state: [grid_size][grid_size]GridElement = .{.{.floor} ** grid_size} ** grid_size,
    iteration: usize = 0,

    fn load(self: *Grid, data: []const u8) void {
        var it_row = std.mem.tokenizeScalar(u8, data, '\n');
        var x: usize = 0;
        while (it_row.next()) |row| {
            for (row, 0..) |element, y| {
                self.state[x][y] = if (element == 'L') GridElement.empty else GridElement.floor;
            }
            x += 1;
        }
    }

    fn get(self: *const Grid, x: isize, y: isize) !GridElement {
        if (x < 0 or x >= self.state.len) return Error.InvalidXPosition;
        if (y < 0 or y >= self.state.len) return Error.InvalidYPosition;

        return self.state[@as(usize, @abs(x))][@as(usize, @abs(y))];
    }

    fn isOccupied(self: *const Grid, x: isize, y: isize) bool {
        const element = self.get(x, y) catch return false;
        return switch (element) {
            .occupied => true,
            else => false,
        };
    }

    fn noOfOccupied(self: *const Grid, x: isize, y: isize) usize {
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
        for (0..grid_size) |x| {
            for (0..grid_size) |y| {
                if (self.state[x][y] == .occupied) total += 1;
            }
        }
        return total;
    }

    fn stepRuleFirst(self: *Grid) bool {
        var new_state: [grid_size][grid_size]GridElement = .{.{.floor} ** grid_size} ** grid_size;
        var changed = false;

        for (self.state, 0..) |row, x| {
            for (row, 0..) |element, y| {
                if (element == .floor) continue;

                const occ = self.noOfOccupied(@intCast(x), @intCast(y));
                new_state[x][y] = blk: {
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
    //grid.printDebug();
    try std.testing.expectEqual(grid.state[0][0], GridElement.empty);

    var changed = grid.stepRuleFirst();
    //grid.printDebug();
    try std.testing.expectEqual(true, changed);
    try std.testing.expectEqual(grid.state[0][0], GridElement.occupied);
    try std.testing.expectEqual(2, grid.noOfOccupied(0, 0));

    changed = grid.stepRuleFirst();
    //grid.printDebug();
    try std.testing.expectEqual(true, changed);
    try std.testing.expectEqual(grid.state[0][2], GridElement.empty);
    try std.testing.expectEqual(1, grid.noOfOccupied(0, 0));

    while (changed) {
        changed = grid.stepRuleFirst();
    }
    //grid.printDebug();
    try std.testing.expectEqual(37, grid.totalOccupied());
}
