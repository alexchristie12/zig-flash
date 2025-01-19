const std = @import("std");
const json = std.json; // The config is in JSON format.
const Allocator = std.mem.Allocator;
const dbg = std.debug.print;

const ConfigurationData = struct {
    general_config: GeneralConfig,
    i2c_config: [2]I2CConfig,
    adc_config: [4]ADCConfig,
};

const GeneralConfig = struct {
    name: []const u8,
    hardware_id: u64,
};

const ADCConfig = struct {
    name: []const u8,
    max_val: f32,
    min_val: f32,
    max_map_val: u16,
    min_map_val: u16,
};

const I2CConfig = struct {
    name: []const u8,
    sensor_type: u8,
};

const ConfigError = union(enum) {
    good,
    err: []const u8,
};

pub fn get_config_data(fname: []const u8) ?[]u8 {
    const cwd = std.fs.cwd();
    const handle = cwd.openFile(fname, .{ .mode = .read_only }) catch {
        std.debug.print("Could not find file to open, or could not open it!\n", .{});
        return null;
    };
    defer handle.close();
    // Create a buffer, can store in memory... initially check the file size
    const stats = handle.stat() catch {
        @panic("Cannot get file stats, this is dangerous!");
    };
    if (stats.size > 5000) {
        // If the config file is larger than 5kiB, then it is suspiciously large,
        // and we will not handle it for now.
        return null;
    }
    var buffer: [5000]u8 = undefined;
    _ = handle.readAll(&buffer) catch {
        return null;
    };
    return &buffer;
}

fn parse_config_data(buffer: []u8, allocator: Allocator) ?std.json.Parsed(ConfigurationData) {
    const parsed = json.parseFromSlice(ConfigurationData, allocator, buffer, .{}) catch return null;
    return parsed;
}

test "check if parsed breaks result when deinited for parseConfigData" {
    const allocator = std.testing.allocator;
    const configuration = parse_config_data(@constCast(EXAMPLE_CONFIG), allocator);
    defer configuration.?.deinit();
    try std.testing.expect(configuration != null);
}

fn verify_config(config: ConfigurationData) bool {
    // We have a bunch of errors that are possible.
    var errors: [7]ConfigError = undefined;
    errors[0] = verify_general_config(config.general_config);
    for (config.i2c_config, 1..) |i2cc, idx| {
        errors[idx] = verify_I2C_config(i2cc);
    }
    for (config.adc_config, 3..) |adcc, idx| {
        errors[idx] = verify_ADC_config(adcc);
    }
    // TODO: Print out all of the errors
    return check_for_errors(&errors);
}

fn verify_general_config(gen_config: GeneralConfig) ConfigError {
    // Name length must be less than 50 characters
    if (gen_config.name.len >= 50) return ConfigError{ .err = "General Config name is too long" };
    return ConfigError.good;
}

fn verify_ADC_config(adc_config: ADCConfig) ConfigError {
    if (adc_config.name.len >= 50) return ConfigError{ .err = "ADC Config name is too long, must be >=50 characters" };
    return ConfigError.good;
}

fn verify_I2C_config(i2c_config: I2CConfig) ConfigError {
    if ((i2c_config.sensor_type > 4) or (i2c_config.sensor_type == 0)) return ConfigError{ .err = "Invalid I2C Config Sensor type, must be 1, 2, or 3" };
    if (i2c_config.name.len >= 50) return ConfigError{ .err = "I2C Config name is too long, must be >= characters" };
    return ConfigError.good;
}

// Return false if an error if found, true if none are found
fn check_for_errors(error_collection: []ConfigError) bool {
    if (error_collection.len == 0) return true;
    for (error_collection) |err| {
        switch (err) {
            ConfigError.good => continue,
            ConfigError.err => |msg| {
                std.debug.print("{s}\n", .{msg});
                return false;
            },
        }
    }
    return true;
}

test "valid configuration" {
    // This will give a valid configuration
    const valid_configuration_json =
        \\{
        \\   "general_config": {
        \\      "name": "Example Config",
        \\      "hardware_id": 305419896
        \\   },
        \\   "i2c_config": [
        \\      {
        \\         "name": "TempHum-Sensor-01",
        \\         "sensor_type": 1
        \\      },
        \\      {
        \\         "name": "SoilMoist-Sensor-01",
        \\         "sensor_type": 2
        \\      }
        \\   ],
        \\   "adc_config": [
        \\      {
        \\         "name": "ADC-Sensor-01",
        \\         "max_val": 100,
        \\         "min_val": 0,
        \\         "max_map_val": 3000,
        \\         "min_map_val": 200
        \\      },
        \\      {
        \\         "name": "ADC-Sensor-01",
        \\         "max_val": 24,
        \\         "min_val": -10,
        \\         "max_map_val": 1234,
        \\         "min_map_val": 123
        \\      },
        \\      {
        \\         "name": "ADC-Sensor-03",
        \\         "max_val": 100,
        \\         "min_val": 0,
        \\         "max_map_val": 3000,
        \\         "min_map_val": 200
        \\      },
        \\      {
        \\         "name": "ADC-Sensor-04",
        \\         "max_val": 24,
        \\         "min_val": -10,
        \\         "max_map_val": 1234,
        \\         "min_map_val": 123
        \\      }
        \\   ]
        \\}
    ;
    const valid_configuration = parse_config_data(@constCast(valid_configuration_json), std.testing.allocator);
    defer valid_configuration.?.deinit();
    // Ensure that the configuration is valid
    try std.testing.expect(valid_configuration != null);
    try std.testing.expect(verify_config(valid_configuration.?.value));
}

test "invalid configuration" {
    // This should give an invalid configuration
    const invalid_configuration_json =
        \\{
        \\   "general_config": {
        \\      "name": "Example Config",
        \\      "hardware_id": 305419896
        \\   },
        \\   "i2c_config": [
        \\      {
        \\         "name": "TempHum-Sensor-01",
        \\         "sensor_type": 69
        \\      },
        \\      {
        \\         "name": "SoilMoist-Sedddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddnsor-01TooLong",
        \\         "sensor_type": 2
        \\      }
        \\   ],
        \\   "adc_config": [
        \\      {
        \\         "name": "ADC-Sensor-01",
        \\         "max_val": 100,
        \\         "min_val": 0,
        \\         "max_map_val": 3000,
        \\         "min_map_val": 200
        \\      },
        \\      {
        \\         "name": "ADC-Sensor-01",
        \\         "max_val": 24,
        \\         "min_val": -10,
        \\         "max_map_val": 1234,
        \\         "min_map_val": 123
        \\      },
        \\      {
        \\         "name": "ADC-Sensor-03",
        \\         "max_val": 100,
        \\         "min_val": 0,
        \\         "max_map_val": 3000,
        \\         "min_map_val": 200
        \\      },
        \\      {
        \\         "name": "ADC-Sensor-04",
        \\         "max_val": 24,
        \\         "min_val": -10,
        \\         "max_map_val": 1234,
        \\         "min_map_val": 123
        \\      }
        \\   ]
        \\}
    ;

    const invalid_configuration = parse_config_data(@constCast(invalid_configuration_json), std.testing.allocator);
    defer invalid_configuration.?.deinit();
    try std.testing.expect(invalid_configuration != null);
    try std.testing.expect(!verify_config(invalid_configuration.?.value));
}

const EXAMPLE_CONFIG =
    \\{
    \\   "general_config": {
    \\      "name": "Example Config",
    \\      "hardware_id": 305419896
    \\   },
    \\   "i2c_config": [
    \\      {
    \\         "name": "TempHum-Sensor-01",
    \\         "sensor_type": 69
    \\      },
    \\      {
    \\         "name": "SoilMoist-Sensor-01TooLong",
    \\         "sensor_type": 2
    \\      }
    \\   ],
    \\   "adc_config": [
    \\      {
    \\         "name": "ADC-Sensor-01",
    \\         "max_val": 100,
    \\         "min_val": 0,
    \\         "max_map_val": 3000,
    \\         "min_map_val": 200
    \\      },
    \\      {
    \\         "name": "ADC-Sensor-01",
    \\         "max_val": 24,
    \\         "min_val": -10,
    \\         "max_map_val": 1234,
    \\         "min_map_val": 123
    \\      },
    \\      {
    \\         "name": "ADC-Sensor-03",
    \\         "max_val": 100,
    \\         "min_val": 0,
    \\         "max_map_val": 3000,
    \\         "min_map_val": 200
    \\      },
    \\      {
    \\         "name": "ADC-Sensor-04",
    \\         "max_val": 24,
    \\         "min_val": -10,
    \\         "max_map_val": 1234,
    \\         "min_map_val": 123
    \\      }
    \\   ]
    \\}
;
