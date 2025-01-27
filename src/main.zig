const std = @import("std");
const flag = @import("flag.zig");
const parser = @import("config.zig");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // Try the command line
    const option = flag.get_option() catch {
        try stdout.print("Option getter returned an error", .{});
        try bw.flush(); // don't forget to flush!
        return;
    };
    _ = option;

    try bw.flush(); // don't forget to flush!

    // Now see if I can open that file.
    const data = parser.get_config_data("./src/config/demo.json");
    if (data == null) {
        std.debug.print("Could not open file", .{});
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "another simple test" {
    try std.testing.expectEqual(1, 2);
}
