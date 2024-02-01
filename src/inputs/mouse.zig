const std = @import("std");
const zdl = @import("zsdl");
const wnd = @import("../types/window.zig");
const tpe = @import("../types/types.zig");
const evt = @import("../systems/event.zig");

pub const Mouse = struct {
    abs_position: tpe.Point2 = .{},
    rel_position: tpe.Float2 = .{},
    button_state: [32]evt.InputState = [_]evt.InputState{.left} ** 32, // for excessive mice
    pub fn procMouse(self: *Mouse, window: wnd.Window) void {
        const input_bits = zdl.getMouseState(&self.abs_position.x, &self.abs_position.y);

        const fmx = @as(f32, @floatFromInt(self.abs_position.x));
        const fmy = @as(f32, @floatFromInt(self.abs_position.y));
        const fww = @as(f32, @floatFromInt(window.bounds.w));
        const fwx = @as(f32, @floatFromInt(window.bounds.x));
        const fwy = @as(f32, @floatFromInt(window.bounds.y));
        const fwz = @as(f32, @floatFromInt(window.bounds.z));
        _ = fww;
        _ = fwx;

        self.rel_position = tpe.Float2{
            .x = ((fmx - fwy / 2.0) / fwy) * 2.0,
            .y = -(((fmy - fwz / 2.0) / fwz) * 2.0),
        };

        for (&self.button_state, 0..) |*state, i| {
            const b: bool = (((@as(u32, 1) << @intCast(i)) & input_bits) > 0);
            state.* = switch (state.*) {
                evt.InputState.none => if (b) .down else .none,
                evt.InputState.down => if (b) .stay else .left,
                evt.InputState.stay => if (b) .stay else .left,
                evt.InputState.left => if (b) .down else .none,
            };
        }
    }
};
