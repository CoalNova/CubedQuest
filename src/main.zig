const std = @import("std");
const zdl = @import("zsdl");
const zmt = @import("zmath");
const csm = @import("systems/csmath.zig");
const sys = @import("systems/system.zig");
const lvl = @import("types/level.zig");
const cms = @import("systems/csmath.zig");
const wnd = @import("types/window.zig");
const evt = @import("systems/event.zig");
const gls = @import("systems/glsystem.zig");
const cbe = @import("objects/cube.zig");

/// Main insertion point, due to the lite natue of the function it is an adequate location for testing.
// For production/final this function should only contain the initializer, deinitializer, and process call.
pub fn main() !void {
    // Initialize Engine
    try sys.init();
    // Deinitialize Engine
    defer sys.deinit();

    //DEBUG set level
    lvl.active_level = try lvl.loadDebugLevel();

    // Process Engine Parts
    while (try sys.proc()) {

        //DEBUG camera rotation to find
        if (evt.getInputStay(.{ .input_id = @intFromEnum(zdl.Scancode.up) }))
            wnd.windows.items[0].camera.euclid.position.addAxial(.{ 0.0, 0.01, 0.0 });
        if (evt.getInputStay(.{ .input_id = @intFromEnum(zdl.Scancode.down) }))
            wnd.windows.items[0].camera.euclid.position.addAxial(.{ 0.0, -0.01, 0.0 });
        if (evt.getInputStay(.{ .input_id = @intFromEnum(zdl.Scancode.left) }))
            wnd.windows.items[0].camera.euclid.position.addAxial(.{ 0.01, 0.0, 0.0 });
        if (evt.getInputStay(.{ .input_id = @intFromEnum(zdl.Scancode.right) }))
            wnd.windows.items[0].camera.euclid.position.addAxial(.{ -0.01, 0.0, 0.0 });

        if (evt.getInputStay(.{ .input_id = @intFromEnum(zdl.Scancode.rshift) }))
            wnd.windows.items[0].camera.euclid.position.addAxial(.{ 0.0, 0.0, 0.01 });
        if (evt.getInputStay(.{ .input_id = @intFromEnum(zdl.Scancode.rctrl) }))
            wnd.windows.items[0].camera.euclid.position.addAxial(.{ 0.0, 0.0, -0.01 });
        //DEBUG quit
        if (evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.escape) }))
            sys.setStateOff(sys.EngineState.alive);

        //DEBUG wireframe mode
        if (evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.space) }))
            gls.toggleWireFrame();
    }
}
