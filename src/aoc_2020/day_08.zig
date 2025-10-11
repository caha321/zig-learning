const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;

const input = @embedFile("day_08_input.txt");

// https://adventofcode.com/2020/day/8

pub fn main() !void {
    var program = try Program.fromData(input);

    _ = debugProgram(&program);

    program.reset();
    fixProgram(&program);
}

const Error = error{
    InvalidInstruction,
    TooManyInstructions,
};

const Operation = enum {
    nop,
    acc,
    jmp,

    fn fromStr(op_str: []const u8) !Operation {
        if (std.mem.eql(u8, "acc", op_str)) {
            return .acc;
        } else if (std.mem.eql(u8, "jmp", op_str)) {
            return .jmp;
        } else if (std.mem.eql(u8, "nop", op_str)) {
            return .nop;
        } else {
            return Error.InvalidInstruction;
        }
    }
};

const Instruction = struct {
    operation: Operation = Operation.nop,
    argument: i32 = 0,

    fn fromLine(line: []const u8) !Instruction {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const op_str = it.next() orelse return Error.InvalidInstruction;
        const arg_str = it.next() orelse return Error.InvalidInstruction;

        return Instruction{
            .argument = try std.fmt.parseInt(i32, arg_str, 10),
            .operation = try Operation.fromStr(op_str),
        };
    }
};

const Program = struct {
    instructions: [1024]Instruction = [_]Instruction{.{}} ** 1024,
    accumulator: isize = 0,
    program_counter: usize = 0,

    fn fromData(data: []const u8) !Program {
        var it = std.mem.tokenizeScalar(u8, data, '\n');
        var program = Program{};

        var count: usize = 0;
        while (it.next()) |line| {
            if (count >= program.instructions.len) {
                return Error.TooManyInstructions;
            }
            program.instructions[count] = try Instruction.fromLine(line);
            count += 1;
        }

        return program;
    }

    fn reset(self: *Program) void {
        self.accumulator = 0;
        self.program_counter = 0;
    }

    fn step(self: *Program) void {
        const instruction = self.instructions[self.program_counter];
        switch (instruction.operation) {
            .nop => {
                self.program_counter += 1;
            },
            .acc => {
                self.accumulator += instruction.argument;
                self.program_counter += 1;
            },
            .jmp => {
                self.program_counter = @as(usize, @intCast(@as(i32, @intCast(self.program_counter)) + instruction.argument));
            },
        }
    }

    fn printDebug(self: *Program) void {
        print("{} @ pc={}, acc={}\n", .{
            self.instructions[self.program_counter],
            self.program_counter,
            self.accumulator,
        });
    }
};

const ExitReason = enum { Loop, Termination };

fn debugProgram(program: *Program) ExitReason {
    var executed = std.bit_set.ArrayBitSet(usize, 1024).initEmpty();
    while (true) {
        if (program.program_counter >= 1024) {
            print("Program terminated! acc={}\n", .{program.accumulator});
            return ExitReason.Termination;
        }
        if (executed.isSet(program.program_counter)) {
            print("Loop detected! acc={}\n", .{program.accumulator});
            return ExitReason.Loop;
        }
        executed.set(program.program_counter); // mark current instruction as executed
        program.step();
        //program.printDebug();
    }
}

fn fixProgram(program: *Program) void {
    // exactly 1 jmp/nop in the program should be a nop/jmp instead
    for (0..program.instructions.len) |index| {
        const operation = &program.instructions[index].operation;
        switch (operation.*) {
            .nop => {
                operation.* = Operation.jmp;
                if (debugProgram(program) == .Termination) {
                    print("fixed by replacing the nop @ {} with a jmp!\n", .{index});
                    return;
                }
                operation.* = Operation.nop; // restore
                program.reset();
            },
            .jmp => {
                operation.* = Operation.nop;
                if (debugProgram(program) == .Termination) {
                    print("fixed by replacing a jmp @ {} with a nop!\n", .{index});
                    return;
                }
                operation.* = Operation.jmp; // restore
                program.reset();
            },
            else => {},
        }
    }
}

// fn runProgram(data: []const u8) isize {
//     var  = 0;
// }

fn testExample() !Program {
    const data =
        \\nop +0
        \\acc +1
        \\jmp +4
        \\acc +3
        \\jmp -3
        \\acc -99
        \\acc +1
        \\jmp -4
        \\acc +6
    ;

    return try Program.fromData(data);
}

fn testExampleFixed() !Program {
    const data =
        \\nop +0
        \\acc +1
        \\jmp +4
        \\acc +3
        \\jmp -3
        \\acc -99
        \\acc +1
        \\nop -4
        \\acc +6
    ;

    return try Program.fromData(data);
}

test "parse example" {
    const program = try testExample();
    try std.testing.expectEqual(
        Operation.nop,
        program.instructions[0].operation,
    );
    try std.testing.expectEqual(
        Operation.acc,
        program.instructions[1].operation,
    );
    try std.testing.expectEqual(
        1,
        program.instructions[1].argument,
    );
    try std.testing.expectEqual(
        Operation.jmp,
        program.instructions[2].operation,
    );
    try std.testing.expectEqual(
        4,
        program.instructions[2].argument,
    );
}

test "run example" {
    var program = try testExample();
    const reason = debugProgram(&program);
    try std.testing.expectEqual(ExitReason.Loop, reason);
    try std.testing.expectEqual(5, program.accumulator);
}

test "run example fixed manual" {
    var program = try testExampleFixed();
    const reason = debugProgram(&program);
    try std.testing.expectEqual(ExitReason.Termination, reason);
    try std.testing.expectEqual(8, program.accumulator);
}

test "run example fixed automatic" {
    var program = try testExample();
    fixProgram(&program);
    try std.testing.expectEqual(8, program.accumulator);
}
