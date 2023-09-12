const zmt = @import("zmath");
const pos = @import("../types/position.zig");
const tps = @import("../types/types.zig");

/// The Combination of Position, Rotation, and Scale
/// MEBE onboard matrix calcs?
/// MEBE swap out pst.Position for simpler Float3?
pub const Euclid = struct {
    position: pos.Position = .{},
    rotation: zmt.Quat = zmt.Quat{ 0, 0, 0, 1 },
    scale: tps.Float3 = tps.Float3.init(1, 1, 1),
};
