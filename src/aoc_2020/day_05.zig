const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;

const input = @embedFile("day_05_input.txt");

// https://adventofcode.com/2020/day/5

pub fn main() !void {
    var it = std.mem.tokenizeScalar(u8, input, '\n');

    var taken_seats = std.bit_set.ArrayBitSet(usize, 1024).initEmpty();

    var max_id: usize = 0;
    while (it.next()) |line| {
        const id = seatId(line);
        taken_seats.set(id);
        //print("{}\n", .{id});
        max_id = @max(max_id, id);
    }

    print("# of taken_seats = {}\n", .{taken_seats.count()});
    print("First set = {}\n", .{taken_seats.findFirstSet().?});
    print("Last set = {}\n", .{taken_seats.findLastSet().?});

    // some seats in the front are missing
    taken_seats.setRangeValue(.{ .start = 0, .end = taken_seats.findFirstSet().? }, true);
    const free_seats = taken_seats.complement();

    print("\n---\nAnswer Part 1 = {}\n", .{max_id});
    print("Answer Part 2 = {}\n", .{free_seats.findFirstSet().?});
}

pub fn decode(data: []const u8, start: comptime_int, end: comptime_int) usize {
    // TODO Can I check if data is long enough at comptime?
    assert(data.len >= end);

    var value: usize = 0;
    for (data[start..end], 0..) |cur, index| {
        if (cur == 'B' or cur == 'R') { // upper half
            value |= @as(usize, 1) << @as(u6, @truncate(end - start - 1 - index));
        }
    }

    return value;
}

pub fn decodeRow(data: []const u8) usize {
    return decode(data, 0, 7);
}

pub fn decodeCol(data: []const u8) usize {
    return decode(data, 7, 10);
}

pub fn seatId(data: []const u8) usize {
    return decodeRow(data) * 8 + decodeCol(data);
}

test "example" {
    const data = "FBFBBFFRLR";
    try std.testing.expectEqual(44, decodeRow(data));
    try std.testing.expectEqual(5, decodeCol(data));
    try std.testing.expectEqual(357, seatId(data));
}
