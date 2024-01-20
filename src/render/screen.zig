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

    var temp_screens = try sys.allocator.alloc(box.ScreenBox, 1);
    temp_screens[0] = .{
        .bounds = .{ .w = -0.5, .x = -0.5, .y = 1.0, .z = 1.0 },
        .color = .{ .w = 0.2, .x = 0.2, .y = 0.2, .z = 1.0 },
        .id = 255,
        .layer = 0.5,
        .mesh_id = try msh.meshes.fetch(255),
        .contents = "hullo",
    };

    switch (screen_type) {
        .start_landing => {
            return Screen{
                .screen_type = screen_type,
                .boxes = temp_screens,
            };
        },
        .start_main => unreachable,
        .level_select => unreachable,
        .level_load => unreachable,
        .play_start => unreachable,
        .play_pause => unreachable,
        .play_playing => unreachable,
        .play_succeed => unreachable,
        .play_failure => unreachable,
        .settings_controls => unreachable,
        .settings_graphics => unreachable,
        .settings_accessibility => unreachable,
    }
}
