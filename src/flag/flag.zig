const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;
const eql = std.mem.eql;
const dbg = std.debug;

const FLAG_DEBUG = true;

const FlagParseError = error{
    DoesNotExist,
    InvalidFormat,
};

// I cannot workout how to have a proper way to handle void in a tagged union
pub const FlashOption = union(enum) {
    flash: []u8,
    verify: []u8,
    example,
};

// In this case we can get:
// - zig-flash run
// - zig-flash example
// - zig-flash verify

/// Get the option to control what the Flashing CLI uses.
pub fn get_option() FlagParseError!FlashOption {
    // Make a buffer allocator
    var buffer: [500]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const alloc = fba.allocator();

    // Get the arguments
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();
    _ = args.next(); // We discard the program name

    while (args.next()) |arg| {
        // Check the arguement.
        if (FLAG_DEBUG) {
            dbg.print("The argument was: {s}\n", .{arg});
        }
        // Check the flash
        if (eql(u8, arg, "flash")) {
            // We have a flash option and need to get the next arg,
            // check that we have the next arg and that will be the
            // filename
            if (args.next() == null) {
                return FlagParseError.InvalidFormat;
            }
            return FlashOption{ .flash = @constCast(arg) };
        }

        // Check for verify
        if (eql(u8, arg, "verify")) {
            if (args.next() == null) {
                return FlagParseError.InvalidFormat;
            }
            return FlashOption{ .verify = @constCast(arg) };
        }

        // Check for example
        if (eql(u8, arg, "example")) {
            return FlashOption.example;
        }

        // If we get to here then we have an invalid option, so return null
        return FlagParseError.InvalidFormat;
    }

    return FlagParseError.InvalidFormat;
}

// Need to check the that we only have one option, I am not sure if the first
// arg is the executable name. So we may only have two or three args
