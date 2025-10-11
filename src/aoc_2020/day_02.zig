const std = @import("std");
const print = std.debug.print;

const input = @embedFile("day_02_input.txt");

// https://adventofcode.com/2020/day/2

const ParsingError = error{InvalidInput};

const Entry = struct {
    first: u64,
    second: u64,
    letter: u8,
    password: []const u8,

    pub fn fromLine(data: []const u8) !Entry {
        const index_limiter = std.mem.indexOf(u8, data, "-") orelse return ParsingError.InvalidInput;
        const first = try std.fmt.parseInt(u64, data[0..index_limiter], 10);

        const first_space = std.mem.indexOf(u8, data, " ") orelse return ParsingError.InvalidInput;
        const second = try std.fmt.parseInt(u64, data[index_limiter + 1 .. first_space], 10);
        const letter = data[first_space + 1];
        const password = data[first_space + 4 ..];

        return Entry{
            .letter = letter,
            .second = second,
            .first = first,
            .password = password,
        };
    }

    pub fn isValidFirst(self: *const Entry) bool {
        var count: usize = 0;
        for (self.password) |p_letter| {
            if (self.letter == p_letter) {
                count += 1;
            }
        }

        return (count >= self.first) and (count <= self.second);
    }

    pub fn isValidSecond(self: *const Entry) bool {
        var count: usize = 0;

        var pos = self.first - 1;
        if (self.password[pos] == self.letter) {
            count += 1;
        }

        pos = self.second - 1;
        if (self.password[pos] == self.letter) {
            count += 1;
        }

        return count == 1;
    }
};

// pub fn isValid(data: []const u8) !bool {
//     const entry = try Entry.fromLine(data);
//     print("entry = {}\n", .{entry});

//     return entry.isValidFirst();
// }

pub fn main() !void {
    const bla = try Entry.fromLine("1-3 a: abcde");
    _ = try std.testing.expect(bla.isValidSecond());

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    var sum_first: usize = 0;
    var sum_second: usize = 0;
    while (it.next()) |line| {
        const entry = try Entry.fromLine(line);
        if (entry.isValidFirst()) {
            sum_first += 1;
        }
        if (entry.isValidSecond()) {
            sum_second += 1;
        }
    }

    print("# of valid passwords (1st part): {}\n", .{sum_first});
    print("# of valid passwords (2nd part): {}\n", .{sum_second});
}

test "entry from line" {
    const entry = try Entry.fromLine("1-3 a: abcde");
    try std.testing.expectEqual(1, entry.first);
    try std.testing.expectEqual(3, entry.second);
    try std.testing.expectEqual('a', entry.letter);
    try std.testing.expect(std.mem.eql(u8, "abcde", entry.password));
}

test "entry is valid first part" {
    var entry = Entry{
        .letter = 'a',
        .first = 1,
        .second = 3,
        .password = "abcde",
    };
    try std.testing.expect(entry.isValidFirst());

    entry = Entry{
        .letter = 'b',
        .first = 1,
        .second = 1,
        .password = "cdefg",
    };
    try std.testing.expect(!entry.isValidFirst());
}

test "entry is valid second part" {
    var entry = Entry{
        .letter = 'a',
        .first = 1,
        .second = 3,
        .password = "abcde",
    };
    try std.testing.expect(entry.isValidSecond());

    entry = Entry{
        .letter = 'b',
        .first = 1,
        .second = 1,
        .password = "cdefg",
    };
    try std.testing.expect(!entry.isValidSecond());

    entry = Entry{
        .letter = 'c',
        .first = 2,
        .second = 9,
        .password = "ccccccccc",
    };
    try std.testing.expect(!entry.isValidSecond());
}
