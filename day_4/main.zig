const std = @import("std");
const heap = std.heap;
const fs = std.fs;
const mem = std.mem;

var arena = heap.ArenaAllocator.init(heap.page_allocator);
const alloc = arena.allocator();

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var input_file = try fs.cwd().openFile("input.txt", .{});
    defer input_file.close();

    const input = try input_file.readToEndAlloc(alloc, try input_file.getEndPos());
    const lines = try splitLines(input);
    defer alloc.free(lines);

    const score_1 = try part1(lines);
    const score_2 = try part2(lines);

    try stdout.print("part 1 = {d}\n", .{score_1});
    try stdout.print("part 2 = {d}\n", .{score_2});
}

fn splitLines(input: []const u8) ![][]const u8 {
    var lines = try std.ArrayList([]const u8).initCapacity(alloc, 2 << 8);
    defer lines.deinit();

    var lines_it = mem.tokenizeScalar(u8, input, '\n');
    while (lines_it.next()) |line| {
        try lines.append(line);
    }

    return lines.toOwnedSlice();
}

fn part1(lines: [][]const u8) !u32 {
    var score: u32 = 0;

    var window = try std.ArrayList(u8).initCapacity(alloc, 4);
    defer window.deinit();

    // check horizontal
    for (lines) |line| {
        var l: usize = 0;
        for (0..line.len) |r| {
            if (r - l >= 3) {
                defer window.clearRetainingCapacity();
                defer l += 1;

                for (l..r + 1) |i| {
                    try window.append(line[i]);
                }

                if (mem.eql(u8, window.items, "XMAS") or mem.eql(u8, window.items, "SAMX")) {
                    score += 1;
                }
            }
        }
    }

    // check vertical
    var t: usize = 0;
    for (0..lines.len) |b| {
        if (b - t >= 3) {
            defer t += 1;

            for (0..lines[0].len) |c| {
                defer window.clearRetainingCapacity();

                for (t..b + 1) |r| {
                    try window.append(lines[r][c]);
                }

                if (mem.eql(u8, window.items, "XMAS") or mem.eql(u8, window.items, "SAMX")) {
                    score += 1;
                }
            }
        }
    }

    // check diagonal SE ↘️
    var top: usize = 0;
    for (0..lines.len) |bottom| {
        if (bottom - top >= 3) {
            defer top += 1;

            var left: usize = 0;
            for (0..lines[0].len) |right| {
                if (right - left >= 3) {
                    defer left += 1;
                    defer window.clearRetainingCapacity();

                    for (top..bottom + 1, left..right + 1) |row, col| {
                        try window.append(lines[row][col]);
                    }

                    if (mem.eql(u8, window.items, "XMAS") or mem.eql(u8, window.items, "SAMX")) {
                        score += 1;
                    }
                }
            }
        }
    }

    // check diagonal SW ↙️
    top = 0;
    for (0..lines.len) |bottom| {
        if (bottom - top >= 3) {
            defer top += 1;

            var right: usize = lines[0].len - 1;
            var left = lines[0].len;
            while (left > 0) {
                left -= 1;

                if (right - left >= 3) {
                    defer right -= 1;
                    defer window.clearRetainingCapacity();

                    var row: usize = top;
                    var col = right;
                    while (row <= bottom and col >= left) : (row += 1) {
                        try window.append(lines[row][col]);
                        col -%= 1;
                    }

                    if (mem.eql(u8, window.items, "XMAS") or mem.eql(u8, window.items, "SAMX")) {
                        score += 1;
                    }
                }
            }
        }
    }

    return score;
}

fn part2(lines: [][]const u8) !u32 {
    var score: u32 = 0;

    var win_1 = try std.ArrayList(u8).initCapacity(alloc, 3);
    defer win_1.deinit();
    var win_2 = try std.ArrayList(u8).initCapacity(alloc, 3);
    defer win_2.deinit();

    var top: usize = 0;
    var bottom: usize = 0;
    while (bottom < lines.len) : (bottom += 1) {
        if (bottom - top >= 2) {
            defer top += 1;

            var left: usize = 0;
            for (0..lines[0].len) |right| {
                if (right - left >= 2) {
                    defer left += 1;
                    defer win_1.clearRetainingCapacity();
                    defer win_2.clearRetainingCapacity();

                    // check ↘️
                    try win_1.append(lines[top][left]);
                    try win_1.append(lines[top + 1][left + 1]);
                    try win_1.append(lines[top + 2][left + 2]);

                    // check ↙️
                    try win_2.append(lines[top + 2][left]);
                    try win_2.append(lines[top + 1][left + 1]);
                    try win_2.append(lines[top][left + 2]);

                    if (
                        (mem.eql(u8, win_1.items, "MAS") or mem.eql(u8, win_1.items, "SAM")) and
                        (mem.eql(u8, win_2.items, "MAS") or mem.eql(u8, win_2.items, "SAM"))
                    ) {
                        score += 1;
                    }
                }
            }
        }
    }

    return score;
}

test "part 1 test" {
    const dbg = std.debug;

    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;

    const lines = try splitLines(input);
    const count = try part1(lines);
    dbg.print("count = {d}\n", .{count});

    dbg.assert(count == 18);
}

test "part 2 test" {
    const dbg = std.debug;

    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;

    const lines = try splitLines(input);
    const count = try part2(lines);
    dbg.print("count = {d}\n", .{count});

    dbg.assert(count == 9);
}
