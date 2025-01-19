//! This is not thread safe yet!!
const std = @import("std");
const dbp = std.debug.print;

const LoggingLevel = enum {
    info,
    warn,
    err,
};

var logging_level = LoggingLevel.warn;

pub fn set_logging_level(ll: LoggingLevel) void {
    logging_level = ll;
    // May need to change this for thread safety...
}

pub fn log_info(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(logging_level) >= @intFromEnum(LoggingLevel.info)) return;

    dbp("[INFO]: ", .{});
    dbp(fmt, args);
    dbp("\n", .{});
}

pub fn log_warn(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(logging_level) >= @intFromEnum(LoggingLevel.warn)) return;

    dbp("[WARN]", .{});
    dbp(fmt, args);
    dbp("\n", .{});
}

pub fn log_err(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(logging_level) >= @intFromEnum(LoggingLevel.err)) return;

    dbp("[ERROR]", .{});
    dbp(fmt, args);
    dbp("\n", .{});
}
