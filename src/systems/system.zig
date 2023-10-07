//! System contains initialization, as well as static resources
const std = @import("std");
const zdl = @import("zsdl");
const zgl = @import("zopengl");
const zmt = @import("zmath");
const csm = @import("../systems/csmath.zig");
const phy = @import("../systems/physics.zig");
const tpe = @import("../types/types.zig");
const wnd = @import("../types/window.zig");
const rnd = @import("../systems/renderer.zig");
const evt = @import("../systems/event.zig");
const lvl = @import("../types/level.zig");
const msh = @import("../assets/mesh.zig");
const mat = @import("../assets/material.zig");
const shd = @import("../assets/shader.zig");
const gls = @import("../systems/glsystem.zig");
const cbe = @import("../objects/cube.zig");
const cnt = @import("../systems/controller.zig");

// Allocator
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

/// Engine States, each flag is a bit array for state.
/// Engine states dictate what processes are executed.
pub const EngineState = enum(u8) {
    alive = 0b0000_0001,
    render = 0b0000_0010,
    audio = 0b0000_0100,
    events = 0b0000_1000,
    physics = 0b0001_0000,
    opengl = 0b0010_0000,
    playing = 0b0100_0000,
    setting = 0b1000_0000,
};

/// Engine State
var state: u8 = 0;

/// Set an engine state as true, or 'on'
pub inline fn setStateOn(new_state: EngineState) void {
    state |= @intFromEnum(new_state);
}

/// Set an engine state as false, or 'off'
pub inline fn setStateOff(new_state: EngineState) void {
    if (getState(new_state))
        state ^= @intFromEnum(new_state);
}

/// Returns state boolean for provided state
pub inline fn getState(new_state: EngineState) bool {
    return (state & @intFromEnum(new_state) > 0);
}

/// Initialize Engine in totality
pub fn init() !void {

    // initilalize asset containers
    msh.meshes.init(allocator);
    mat.materials.init(allocator);
    shd.shaders.init(allocator);

    // initilaize (z)sdl and create window
    try zdl.init(zdl.InitFlags.everything);
    std.log.info("SDL initialized succesfully.", .{});
    try wnd.init();
    std.log.info("Window initialized succesfully.", .{});

    // initialize physics
    try phy.init();

    //TODO move window count/name/configuration over to configurable options
    try wnd.createNewWindow(
        "cubedquest",
        .{ .x = 300, .y = 300 },
        .{ .x = 800, .y = 600 },
    );

    // init sky
    try rnd.initSky();

    // set engine flags to everything we need
    setStateOn(EngineState.alive);
    setStateOn(EngineState.events);
    setStateOn(EngineState.playing);
}

/// Deinitialize Engine
pub fn deinit() void {
    //unload active level, deleting assets
    lvl.unloadActiveLevel();

    rnd.deinitSky();

    //
    msh.meshes.deinit();
    mat.materials.deinit();
    shd.shaders.deinit();

    if (getState(EngineState.physics))
        phy.deinit();

    wnd.deinit();
    zdl.quit();
}

/// Run a single frame, returns engine alive flag
/// TODO catch all failures internally
pub fn proc() !bool {
    //set from events
    if (getState(EngineState.events))
        try evt.processEvents();

    //Process physics
    if (getState(EngineState.physics)) {
        phy.proc();
    }

    //Run through loaded items for events
    if (getState(EngineState.playing)) {
        const cubes = lvl.active_level.cubes;
        for (cubes.items) |*c| {
            switch (c.cube_type) {
                cbe.CubeType.ground => {},
                cbe.CubeType.player => {
                    cnt.procPlayer(c);
                },
                cbe.CubeType.enemy => {
                    cnt.procEnemy(c);
                },
                cbe.CubeType.coin => {},
                cbe.CubeType.endgate => {},
                cbe.CubeType.spotlight => {},
                cbe.CubeType.trigger => {},
                cbe.CubeType.force => {},
            }
        }
    }

    //run all extra scripts
    //TODO script centralization

    //render
    if (getState(EngineState.render))
        try rnd.render();

    //have a merry old time
    zdl.delay(15);
    return getState(EngineState.alive);
}
