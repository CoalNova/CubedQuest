const std = @import("std");
const tpe = @import("types.zig");

// Bit alotment for position per axis (sans z index for intradimensional transitions)
const i_ = i32;
const decimal_bits = 11;
const unit_bits = 10;
const axial_bits = decimal_bits + unit_bits;

const decimal_divisor = 1 << decimal_bits;
const axial_divisor = 1 << (axial_bits);
const axial_mask = (axial_divisor) - 1;
const index_mask = ((1 << (@bitSizeOf(i_) - 1)) - 1) ^ axial_mask;

/// Position for interdimensional positioning
/// Please ignore complexity for the demonstration of Cubes
pub const Position = packed struct {
    x: i_ = 512 * decimal_divisor,
    y: i_ = 512 * decimal_divisor,
    z: i_ = 0,
    z_index: i_ = 0,
    pub inline fn addAxial(this: *Position, axial: tpe.Float3) void {
        this.x += @intFromFloat(axial.x * decimal_divisor);
        this.y += @intFromFloat(axial.y * decimal_divisor);
        this.z += @intFromFloat(axial.z * decimal_divisor);
    }
    pub inline fn getAxial(this: Position) tpe.Float3 {
        return tpe.Float3.init(
            (@as(f32, @floatFromInt(this.x & axial_mask)) / decimal_divisor) - 512.0,
            (@as(f32, @floatFromInt(this.y & axial_mask)) / decimal_divisor) - 512.0,
            (@as(f32, @floatFromInt(this.z)) / decimal_divisor),
        );
    }
    pub inline fn setAxial(this: *Position, axial: tpe.Float3) void {
        this.x = (this.x & index_mask) + @as(i_, @intFromFloat((axial.x + 512.0) * decimal_divisor));
        this.y = (this.y & index_mask) + @as(i_, @intFromFloat((axial.y + 512.0) * decimal_divisor));
        this.z = @as(i_, @intFromFloat((axial.z) * decimal_divisor));
    }
    pub inline fn getIndex(this: Position) tpe.Point3 {
        return .{
            .x = (this.x >> axial_bits),
            .y = (this.y >> axial_bits),
            .z = this.z_index,
        };
    }
    pub fn init(index: tpe.Point3, axial: tpe.Float3) Position {
        return .{
            .x = (index.x << unit_bits) + @as(i_, @intFromFloat((512.0 + axial.x) * decimal_divisor)),
            .y = (index.y << unit_bits) + @as(i_, @intFromFloat((512.0 + axial.y) * decimal_divisor)),
            .z = @as(i_, @intFromFloat(axial.z * decimal_divisor)),
            .z_index = index.z,
        };
    }
};
