const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const fmt = std.fmt;
const fs = std.fs;

var arena = heap.ArenaAllocator.init(heap.page_allocator);
const alloc = arena.allocator();

fn parse(input: []const u8) !struct { []u32, []u32 } {
    var l1 = try std.ArrayList(u32).initCapacity(alloc, 2 << 10);
    defer l1.deinit();

    var l2 = try std.ArrayList(u32).initCapacity(alloc, 2 << 10);
    defer l2.deinit();

    var line_it = mem.tokenizeSequence(u8, input, "\n");
    while (line_it.next()) |line| {
        var num_it = mem.tokenizeSequence(u8, line, "   ");
        const num_1 = num_it.next().?;
        try l1.append(try fmt.parseInt(u32, num_1, 10));
        const num_2 = num_it.next().?;
        try l2.append(try fmt.parseInt(u32, num_2, 10));
    }

    return .{ try l1.toOwnedSlice(), try l2.toOwnedSlice() };
}

fn part_1(l1: []u32, l2: []u32) u32 {
    mem.sort(u32, l1, {}, std.sort.asc(u32));
    mem.sort(u32, l2, {}, std.sort.asc(u32));

    var sum: u32 = 0;

    for (l1, l2) |n1, n2| {
        sum += @intCast(@abs(@as(i64, n1) - @as(i64, n2)));
    }

    return sum;
}

fn part_2(l1: []u32, l2: []u32) u32 {
    var map = std.AutoHashMap(u32, u32).init(alloc);
    defer map.deinit();

    for (l1) |k| {
        if (map.contains(k)) {
            continue;
        }

        map.put(k, 0) catch @panic("error putting element in hash map");
    }

    for (l2) |n| {
        if (map.contains(n)) {
            map.put(n, map.get(n).? + 1) catch @panic("error putting element in hash map");
        }
    }

    var it = map.iterator();
    var score: u32 = 0;
    while (it.next()) |e| {
        score += e.key_ptr.* * e.value_ptr.*;
    }
    return score;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var input_file = try fs.cwd().openFile("input.txt", .{});
    defer input_file.close();

    const input = try input_file.readToEndAlloc(alloc, try input_file.getEndPos());

    const l1, const l2 = try parse(input);

    try stdout.print("part 1: {d}\n", .{part_1(l1, l2)});
    try stdout.print("part 2: {d}\n", .{part_2(l1, l2)});
}

test "part 1 test" {
    const dbg = std.debug;
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;
    const l1, const l2 = try parse(input);
    const score = part_1(l1, l2);
    dbg.assert(score == 11);
}
