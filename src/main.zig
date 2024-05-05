const std = @import("std");
const bufPrint = std.fmt.bufPrint;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <filename>\n", .{args[0]});
        return;
    }
    const filename = args[1];

    var arr = try readFileContents(filename, allocator);
    defer arr.deinit();

    try printOutXxdFormattedFile(arr);
}

fn readFileContents(filename: []const u8, allocator: std.mem.Allocator) !std.ArrayList(u8) {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var arr = std.ArrayList(u8).init(allocator);

    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        // readded the new line to keep line address matching up
        try arr.append('\n');
    }
    return arr;
}

fn printOutXxdFormattedFile(arr: std.ArrayList(u8)) !void {
    var i: usize = 0;
    var startOfLine: usize = 0;
    while (i < arr.items.len) {
        if (i % 2 == 0) {
            std.debug.print(" ", .{});
        }
        if (i % 16 == 0) {
            if (i != 0) {
                startOfLine = i;
                std.debug.print(" ", .{});
                printBytesToAscii(arr.items[i - 16 .. i]);
                std.debug.print("\n", .{});
            }
            // print memory address
            std.debug.print("{x:0>8}: ", .{i});
        }
        // print byte
        std.debug.print("{x:01}", .{std.fmt.fmtSliceHexLower(arr.items[i .. i + 1])});
        i += 1;
    }
    try printLastXxdLine(arr, i, startOfLine);
}

fn printLastXxdLine(arr: std.ArrayList(u8), index: usize, startOfLine: usize) !void {
    var i = index;
    const endOfLine = i;
    while (i % 16 != 0) {
        std.debug.print("  ", .{});
        i += 1;
        if (i % 2 == 0) {
            std.debug.print(" ", .{});
        }
    }
    std.debug.print("  ", .{});
    printBytesToAscii(arr.items[startOfLine..endOfLine]);
    std.debug.print("\n", .{});
}

fn printBytesToAscii(out: []u8) void {
    for (out) |c| {
        if (c >= 0x20 and c <= 0x7E) {
            std.debug.print("{c}", .{c});
            continue;
        } else {
            std.debug.print(".", .{});
        }
    }
}
