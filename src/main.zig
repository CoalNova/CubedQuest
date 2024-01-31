const std = @import("std");
const zdl = @import("zsdl");
const zgl = @import("zopengl");
const zmt = @import("zmath");
const sys = @import("systems/system.zig");
const lvl = @import("types/level.zig");
const evt = @import("systems/event.zig");
const gls = @import("systems/glsystem.zig");
const rui = @import("render/ui.zig");

/// Main insertion point, due to the lite natue of the function it is an adequate location for testing.
// For production/final this function should only contain the initializer, deinitializer, and process call.
pub fn main() !void {
    // Initialize Engine
    try sys.init();
    // Deinitialize Engine
    defer sys.deinit();

    //DEBUG set level
    try lvl.loadDebugLevel();

    std.debug.print("Press enter to start level!\n", .{});

    // Process Engine Parts
    while (try sys.proc()) {

        //DEBUG quit
        if (evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.escape) }))
            sys.setStateOff(sys.EngineState.alive);

        if (lvl.active_level.lvl_state == lvl.LevelState.generated) {
            if (evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.@"return") }) or
                evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.w) }) or
                evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.s) }) or
                evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.a) }) or
                evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.a) }))
            {
                lvl.active_level.lvl_state = lvl.LevelState.playing;
                try rui.update(.play_playing);
            }
        }

        //DEBUG wireframe mode
        if (evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.space) }))
            gls.toggleWireFrame();
    }
}
