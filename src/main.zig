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

    // The first argument after the program name is assumed to be the filename
    const filename = args[1];

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var arr = std.ArrayList(u8).init(allocator);
    defer arr.deinit();

    var line_count: usize = 0;
    var byte_count: usize = 0;
    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        // readded the new line to keep line address matching up
        try arr.append('\n');
        line_count += 1;
        byte_count += arr.items.len;
    }

    var i: usize = 0;

    while (i < arr.items.len) {
        if (i % 16 == 0) {
            if (i != 0) {
                std.debug.print(" ", .{});
                for (arr.items[i - 16 .. i]) |c| {
                    if (c >= 0x20 and c <= 0x7E) {
                        std.debug.print("{c}", .{c});
                    } else {
                        std.debug.print(".", .{});
                    }
                }
                std.debug.print("\n", .{});
            }
            std.debug.print("{x:0>8}: ", .{i});
        }
        const hexSlice = arr.items[i .. i + 2];
        const hexString = std.fmt.fmtSliceHexLower(hexSlice);
        std.debug.print("{x:02} ", .{hexString});
        i += 2;
    }
    std.debug.print("\n", .{});
}

