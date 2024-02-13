const std = @import("std");
const zdl = @import("zsdl");
const zgl = @import("zopengl");
const zmt = @import("zmath");
const csm = @import("systems/csmath.zig");
const sys = @import("systems/system.zig");
const lvl = @import("types/level.zig");
const evt = @import("systems/event.zig");
const gls = @import("systems/glsystem.zig");
const rui = @import("render/ui.zig");
const wnd = @import("types/window.zig");
const fio = @import("systems/fileio.zig");
const cbe = @import("objects/cube.zig");

/// Main insertion point, due to the lite natue of the function it is an adequate location for testing.
// For production/final this function should only contain the initializer, deinitializer, and process call.
pub fn main() !void {
    std.debug.print("\n{}\n\n", .{@sizeOf(lvl.Level)});

    // Initialize Engine
    try sys.init();
    // Deinitialize Engine
    defer sys.deinit();

    const buffer = try lvl.bufferLevel(lvl.debug_level, sys.allocator);
    defer sys.allocator.free(buffer);
    try fio.saveBuffer("./debuglevel.cq3", buffer);

    const level_buff = try fio.readFileAlloc("./debuglevel.cq3", sys.allocator, 1 << 20);
    defer sys.allocator.free(level_buff);

    const level = try lvl.levelFromBuffer(level_buff, sys.allocator);
    defer {
        sys.allocator.free(level.link_list);
        sys.allocator.free(level.ogds);
        sys.allocator.free(level.name);
    }

    std.debug.assert(std.mem.eql(u16, &level.cam_pos, &lvl.debug_level.cam_pos));
    std.debug.assert(std.mem.eql(f32, &level.cam_rot, &lvl.debug_level.cam_rot));
    std.debug.assert(level.cam_fov == lvl.debug_level.cam_fov);
    for (lvl.debug_level.ogds, 0..) |ogd, i| {
        if (@as(u64, @bitCast(level.ogds[i])) != @as(u64, @bitCast(ogd)))
            std.debug.print("FAILED!\n{any}\n  {any}\n", .{ level.ogds[i], ogd });
    }

    //DEBUG set level
    //try lvl.loadMainMenu();
    try lvl.active_level.generateFromLevel(level);

    //sys.setStateOff(sys.EngineState.alive);

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
                lvl.setActiveState(.playing);
        }

        const cam_rot = &wnd.windows.items[0].camera.euclid.rotation;

        if (evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.up) }) and lvl.active_level.amb_lumin < 1.0)
            cam_rot.* = zmt.qmul(cam_rot.*, csm.convEulToQuat(.{ 0, 0.1, 0 }));

        if (evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.down) }) and lvl.active_level.amb_lumin > 0.0)
            lvl.active_level.amb_lumin -= 0.05;

        //DEBUG wireframe mode
        if (evt.getInputDown(.{ .input_id = @intFromEnum(zdl.Scancode.space) }))
            gls.toggleWireFrame();
    }
}
