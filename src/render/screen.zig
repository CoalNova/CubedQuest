const std = @import("std");
const sys = @import("../systems/system.zig");
const box = @import("../render/screenbox.zig");
const msh = @import("../assets/mesh.zig");

pub const ScreenType = enum {
    start_landing,
    start_main,
    level_select,
    level_load,
    play_start,
    play_pause,
    play_playing,
    play_succeed,
    play_failure,
    settings_controls,
    settings_graphics,
    settings_accessibility,
};

pub const Screen = struct {
    screen_type: ScreenType,
    boxes: []box.ScreenBox,
};

pub fn destroyScreen(screen: Screen) void {
    sys.allocator.free(screen.boxes);
}

pub fn buildScreen(screen_type: ScreenType) !Screen {
    std.log.info("Switching screen to {any}", .{screen_type});

    const screen: Screen = .{ .screen_type = screen_type, .boxes = switch (screen_type) {
        .start_landing => &start_landing_boxes,
        .start_main => unreachable,
        .level_select => unreachable,
        .level_load => unreachable,
        .play_start => &play_start_boxes,
        .play_pause => unreachable,
        .play_playing => &play_playing_boxes,
        .play_succeed => &play_succeed_boxes,
        .play_failure => unreachable,
        .settings_controls => unreachable,
        .settings_graphics => unreachable,
        .settings_accessibility => unreachable,
    } };

    for (screen.boxes) |*b| {
        b.mesh_id = try msh.meshes.fetch(255);
    }

    return screen;
}

var start_landing_boxes = [_]box.ScreenBox{};
var start_main_boxes = [_]box.ScreenBox{};
var level_select_boxes = [_]box.ScreenBox{};
var level_load_boxes = [_]box.ScreenBox{};
var play_start_boxes = [_]box.ScreenBox{.{
    .bounds = .{ .w = -0.5, .x = -0.5, .y = 1.0, .z = 1.0 },
    .color = .{ .w = 0.2, .x = 0.2, .y = 0.2, .z = 1.0 },
    .id = 255,
    .layer = 0.5,
    .mesh_id = 0,
    .contents = "Use the directional keys or press 'Enter' to begin.",
}};
var play_pause_boxes = [_]box.ScreenBox{};
var play_playing_boxes = [_]box.ScreenBox{.{
    .bounds = .{ .w = -0.99, .x = -0.99, .y = 0.05, .z = 1.99 },
    .color = .{ .w = 0.2, .x = 0.2, .y = 0.2, .z = 1.0 },
    .id = 255,
    .layer = 0.5,
    .mesh_id = 0,
    .contents = "Playing!",
}};
var play_succeed_boxes = [_]box.ScreenBox{.{
    .bounds = .{ .w = -0.25, .x = -0.1, .y = 0.5, .z = 0.2 },
    .color = .{ .w = 0.2, .x = 0.2, .y = 0.2, .z = 1.0 },
    .id = 255,
    .layer = 0.5,
    .mesh_id = 0,
    .contents = "You're Winner!",
}};
var play_failure_boxes = [_]box.ScreenBox{.{
    .bounds = .{ .w = -0.25, .x = -0.1, .y = 0.5, .z = 0.2 },
    .color = .{ .w = 0.2, .x = 0.2, .y = 0.2, .z = 1.0 },
    .id = 255,
    .layer = 0.5,
    .mesh_id = 0,
    .contents = "Lost!",
}};
var settings_controls_boxes = [_]box.ScreenBox{};
var settings_graphics_boxes = [_]box.ScreenBox{};
var settings_accessibility_boxes = [_]box.ScreenBox{};
