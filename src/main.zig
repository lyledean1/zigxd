const std = @import("std");

const Config = struct {
    bytes_per_line: usize = 16,
    show_ascii: bool = true,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try std.io.getStdErr().writer().print("Usage: {s} <filename>\n", .{args[0]});
        std.process.exit(1);
    }

    const filename = args[1];
    try hexDumpFile(filename, allocator, .{});
}

fn hexDumpFile(filename: []const u8, allocator: std.mem.Allocator, config: Config) !void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf = try allocator.alloc(u8, config.bytes_per_line);
    defer allocator.free(buf);

    const reader = file.reader();
    var offset: usize = 0;

    while (true) {
        const bytes_read = try reader.read(buf);
        if (bytes_read == 0) break;

        try printHexDumpLine(offset, buf[0..bytes_read], config);
        offset += bytes_read;
    }
}

fn printHexDumpLine(offset: usize, bytes: []const u8, config: Config) !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("{x:0>8}: ", .{offset});

    for (bytes, 0..) |byte, i| {
        if (i % 2 == 0 and i != 0) {
            try stdout.print(" ", .{});
        }
        try stdout.print("{x:0>2}", .{byte});
    }

    const padding_needed = config.bytes_per_line - bytes.len;
    var i: usize = 0;
    while (i < padding_needed) : (i += 1) {
        if ((bytes.len + i) % 2 == 0) {
            try stdout.print(" ", .{});
        }
        try stdout.print("  ", .{});
    }

    if (config.show_ascii) {
        try stdout.print("  ", .{});
        for (bytes) |byte| {
            const c = if (isPrintableAscii(byte)) byte else '.';
            try stdout.print("{c}", .{c});
        }
    }

    try stdout.print("\n", .{});
}

fn isPrintableAscii(byte: u8) bool {
    return byte >= 0x20 and byte <= 0x7E;
}
