const std = @import("std");
const bufPrint = std.fmt.bufPrint;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("/Users/lyledean/compilers/cyclang/bin/main", .{});
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
                std.debug.print("\n", .{});
            }
            std.debug.print("{x:0>8}: ", .{i});
        }
        const hexString = std.fmt.fmtSliceHexLower(arr.items[i .. i + 2]);
        std.debug.print("{x:02} ", .{hexString});
        i += 2;
    }
    std.debug.print("\n", .{});
}
