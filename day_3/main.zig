const std = @import("std");
const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const ascii = std.ascii;
const fmt = std.fmt;

var arena = heap.ArenaAllocator.init(heap.page_allocator);
const alloc = arena.allocator();

const ParsingError = error {
    NotAnOpeningParenthesis,
    NotAClosingParenthesis,
    NotAComma,
    NumberIsTooBig,
    InvalidCharacter,
    ReachedEOF,
};

const Mul = struct {
    left: u32,
    right: u32,
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var input_file = try fs.cwd().openFile("input.txt", .{});
    defer input_file.close();

    const input = try input_file.readToEndAlloc(alloc, try input_file.getEndPos());

    const score_1 = part1(input);
    const score_2 = part2(input);

    try stdout.print("part 1: {d}\n", .{score_1});
    try stdout.print("part 2: {d}\n", .{score_2});
}

fn part1(input: []const u8) u32 {
    var score: u32 = 0;

    const muls: []Mul = parse(input) catch unreachable;
    defer alloc.free(muls);

    for (muls) |mul| {
        score += mul.left * mul.right;
    }

    return score;
}

fn parse(input: []const u8) ![]Mul {
    var muls = try std.ArrayList(Mul).initCapacity(alloc, 2 << 8);
    defer muls.deinit();

    var l: usize = 0;
    var r: usize = 0;

    while (r < input.len) : (r += 1) {
        if (input[r] == 'm') {
            l = r;
            continue;
        }

        if (r - l == 3) {
            if (mem.eql(u8, input[l..r], "mul")) {
                const mul = parseNums(input, &r) catch {
                    l = r;
                    continue;
                };

                try muls.append(mul);
            }
        }
    }

    return muls.toOwnedSlice();
}

fn parseNums(input: []const u8, i: *usize) !Mul {
    try eatOpenParenthesis(input, i);

    const left = try eatLeftDigit(input, i);

    try eatComma(input, i);

    const right = try eatRightDigit(input, i);

    try checkClosingParenthesis(input, i);

    return Mul{ .left = left, .right = right };
}

fn eatOpenParenthesis(input: []const u8, i: *usize) ParsingError!void {
    if (i.* >= input.len) {
        return ParsingError.ReachedEOF;
    }

    if (input[i.*] != '(') {
        return ParsingError.NotAnOpeningParenthesis;
    }

    i.* += 1;
}

fn eatLeftDigit(input: []const u8, i: *usize) !u32 {
    if (i.* >= input.len) {
        return ParsingError.ReachedEOF;
    }

    const l = i.*;

    while (i.* < l + 3) : (i.* += 1) {
        if (i.* >= input.len) {
            return ParsingError.ReachedEOF;
        }

        if (!ascii.isDigit(input[i.*])) {
            if (input[i.*] != ',') {
                return ParsingError.NotAComma;
            } else break;
        }
    }

    return try fmt.parseInt(u32, input[l..i.*], 10);
}

fn eatComma(input: []const u8, i: *usize) ParsingError!void {
    if (i.* >= input.len) {
        return ParsingError.ReachedEOF;
    }

    if (input[i.*] != ',') {
        return ParsingError.NotAComma;
    }

    i.* += 1;
}

fn eatRightDigit(input: []const u8, i: *usize) !u32 {
    if (i.* >= input.len) {
        return ParsingError.ReachedEOF;
    }

    const l = i.*;

    while (i.* < l + 3) : (i.* += 1) {
        if (i.* >= input.len) {
            return ParsingError.ReachedEOF;
        }

        if (!ascii.isDigit(input[i.*])) {
            if (input[i.*] != ')') {
                return ParsingError.NotAClosingParenthesis;
            } else break;
        }
    }

    return try fmt.parseInt(u32, input[l..i.*], 10);
}

fn checkClosingParenthesis(input: []const u8, i: *usize) ParsingError!void {
    if (i.* >= input.len) {
        return ParsingError.ReachedEOF;
    }

    if (input[i.*] != ')') {
        return ParsingError.NotAnOpeningParenthesis;
    }
}

fn part2(input: []const u8) u32 {
    var score: u32 = 0;

    var dont_it = mem.tokenizeSequence(u8, input, "don't()");

    // count first part before any `don't()`
    const first_part = dont_it.next() orelse unreachable;
    std.debug.print("first_part = {s}\n\n", .{first_part});
    score += sumMuls(parse(first_part) catch unreachable);

    while (dont_it.next()) |after_dont_portion| {
        std.debug.print("· after_dont_portion = {s}\n", .{after_dont_portion});
        var do_it = mem.tokenizeSequence(u8, after_dont_portion, "do()");

        // skip first portion after don't()
        _ = do_it.next();

        while (do_it.next()) |after_do_portion| {
            std.debug.print("\tafter_do_portion = {s}\n", .{after_do_portion});
            const muls = parse(after_do_portion) catch unreachable;
            defer alloc.free(muls);

            score += sumMuls(muls);
        }
        std.debug.print("\n\n", .{});
    }

    return score;
}

fn sumMuls(muls: []const Mul) u32 {
    var total: u32 = 0;
    for (muls) |mul| {
        total += mul.left * mul.right;
    }
    return total;
}

test "part 1 test" {
    const dbg = std.debug;
    const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";

    const result = part1(input);

    dbg.print("part 1 = {d}\n", .{result});

    dbg.assert(result == 161);
}

test "part 2 test" {
    const dbg = std.debug;
    const input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";

    const result = part2(input);

    dbg.print("part 2 = {d}\n", .{result});

    dbg.assert(result == 48);
}
