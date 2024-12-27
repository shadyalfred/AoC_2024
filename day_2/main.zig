const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const mem = std.mem;
const fmt = std.fmt;

var arena = heap.ArenaAllocator.init(heap.page_allocator);
const alloc = arena.allocator();

fn parse(input: []const u8) ![][]i32 {
    var levels = try std.ArrayList([]i32).initCapacity(alloc, 2 << 9);
    defer levels.deinit();

    var line_it = mem.tokenizeSequence(u8, input, "\n");
    while (line_it.next()) |line| {
        var level = try std.ArrayList(i32).initCapacity(alloc, 16);

        var num_it = mem.tokenizeSequence(u8, line, " ");
        while (num_it.next()) |num| {
            try level.append(try fmt.parseInt(i32, num, 10));
        }

        try levels.append(try alloc.dupe(i32, level.items));

        level.clearRetainingCapacity();
    }

    return try levels.toOwnedSlice();
}

fn part1(levels: []const []i32) u32 {
    var count: u32 = 0;
    outer: for (levels) |level| {
        var isValid = true;

        // test increasing
        for (1..level.len) |i| {
            const diff = level[i] - level[i - 1];
            if (diff > 3 or diff < 1) {
                isValid = false;
                break;
            }
        }

        if (isValid) {
            count += 1;
            continue :outer;
        }

        isValid = true;

        // test decreasing
        for (1..level.len) |i| {
            const diff = level[i - 1] - level[i];
            if (diff > 3 or diff < 1) {
                isValid = false;
                break;
            }
        }

        if (isValid) {
            count += 1;
        }
    }

    return count;
}

fn isSafe(level: []i32, skip_i: ?i32) bool {
    for (0..level.len - 1) |i| {

    }
}

fn part2(levels: []const []i32) u32 {
    var count: u32 = 0;

    outer: for (levels) |level| {
        if (isSafe(level)) {
            count += 1;
            continue;
        }

        for (0..level.len) |i| {
            if (isSafe(level, i)) {
                count += 1;
                continue :outer;
            }
        }
    }

    return count;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var input_file = try fs.cwd().openFile("input.txt", .{});
    defer input_file.close();

    const input = try input_file.readToEndAlloc(alloc, try input_file.getEndPos());

    const levels = try parse(input);

    try stdout.print("part 1: {d}\n", .{part1(levels)});
    try stdout.print("part 2: {d}\n", .{part2(levels)});
}

test "part 1 test" {
    const dbg = std.debug;
    const input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    const levels = try parse(input);
    dbg.assert(part1(levels) == 2);
}

test "part 2 test" {
    const dbg = std.debug;
    const input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    const levels = try parse(input);
    const score = part2(levels);
    dbg.print("{d}\n", .{score});
    dbg.assert(score == 4);
}
