const std = @import("std");
const zgl = @import("zopengl");
const zdl = @import("zsdl");
const tps = @import("../types/types.zig");
const sys = @import("../systems/system.zig");
const cam = @import("../objects/camera.zig");
const tpe = @import("../types/types.zig");
const gls = @import("../systems/glsystem.zig");

/// The Window Container Struct
/// Contains context, sdl_window, camera, and size.
pub const Window = struct {
    sdl_window: *zdl.Window,
    gl_context: zdl.gl.Context,
    size: tpe.Point2 = undefined,
    camera: cam.Camera = undefined,
};

/// Basic array list of all windows (currently one)
pub var windows: std.ArrayList(Window) = undefined;

/// Initializes window collection
pub fn init() !void {
    windows = std.ArrayList(Window).init(sys.allocator);
}

/// Destroys all running windows apropriately and deinits collection
pub fn deinit() void {
    for (windows.items) |window| {
        zdl.gl.deleteContext(window.gl_context);
        zdl.Window.destroy(window.sdl_window);
    }
    windows.deinit();
}

/// Creates SDL Window with provided parameters
pub fn createNewWindow(name: [:0]const u8, position: tps.Point2, dimensions: tps.Point2) !void {

    // create (z)sdl window
    var temp_window = try zdl.Window.create(
        name,
        position.x,
        position.y,
        dimensions.x,
        dimensions.y,
        .{ .opengl = true, .resizable = true },
    );
    // if fails destroy it
    errdefer (zdl.Window.destroy(temp_window));
    std.log.info("SDL window \"{s}\" created successfully", .{name});

    // create a gl context for the window
    var temp_context = try zdl.gl.createContext(temp_window);
    // again, if fails, destroy it
    errdefer (zdl.gl.deleteContext(temp_context));
    std.log.info("GL context for window \"{s}\" created successfully", .{name});

    // also make context current
    try zdl.gl.makeCurrent(temp_window, temp_context);

    // if GL has not been initialized then do so
    // required after context creation as GL needs an active context to initialize
    // it's actually worse than this, but don't question it for your own sanity's sake
    if (!sys.getState(sys.EngineState.render)) {
        try gls.initalizeGL();
        sys.setStateOn(sys.EngineState.render);
    }

    // add window to arraylist
    try windows.append(Window{
        .sdl_window = temp_window,
        .gl_context = temp_context,
        .size = dimensions,
        .camera = .{},
    });
}
