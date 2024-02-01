const std = @import("std");
const zdl = @import("zsdl");
const zgl = @import("zopengl");
const lvl = @import("../types/level.zig");
const sys = @import("../systems/system.zig");
const box = @import("../render/screenbox.zig");
const rnd = @import("../render/renderer.zig");
const scr = @import("../render/screen.zig");
const wnd = @import("../types/window.zig");

var ui_buffer: u32 = 0;
var ui_render_buffer: u32 = 0;
var screen: scr.Screen = undefined;

/// Create the buffer(s)
pub fn init() !void {
    zgl.genFramebuffers(1, &ui_buffer);
    zgl.bindFramebuffer(zgl.FRAMEBUFFER, ui_buffer);
    zgl.genRenderbuffers(1, &ui_render_buffer);
    zgl.bindRenderbuffer(zgl.RENDERBUFFER, ui_render_buffer);
    zgl.bindFramebuffer(zgl.FRAMEBUFFER, 0);

    screen = try scr.buildScreen(.start_landing);

    std.log.info("Successfully initialized UI buffer: {}", .{screen.boxes.len});
}

/// Destroy the buffer(s)
pub fn deinit() void {
    zgl.deleteFramebuffers(1, &ui_buffer);
    zgl.deleteRenderbuffers(1, &ui_render_buffer);
    std.log.info("Successfully deinitialized UI buffer", .{});
}

/// Draw the buffer(s)
pub fn proc(window: wnd.Window) !void {
    zgl.bindRenderbuffer(zgl.RENDERBUFFER, ui_render_buffer);
    if (rnd.checkGLErrorState("Bind Render Buffer to READ_FRAMEBUFFER error"))
        std.debug.print("ui_render_buffer name {} \n", .{ui_render_buffer});

    zgl.bindFramebuffer(zgl.DRAW_FRAMEBUFFER, 0);
    _ = rnd.checkGLErrorState("Bind Render Buffer to DRAW_FRAMEBUFFER error");

    zgl.blitFramebuffer(0, 0, 1024, 1024, 0, 0, 1024, 1024, zgl.COLOR_BUFFER_BIT, zgl.NEAREST);
    _ = rnd.checkGLErrorState("Blit Render Buffer to Draw Buffer error");
    //for now, just draw box

    if (screen.screen_type == .play_playing) {
        const score: []const u8 = try std.fmt.allocPrint(
            sys.allocator,
            "Score: {d}",
            .{lvl.active_level.cur_score},
        );
        defer sys.allocator.free(score);
        screen.boxes[1].contents = score;
        for (screen.boxes) |b|
            b.drawBox(window);
    } else {
        for (screen.boxes) |b|
            b.drawBox(window);
    }
}

/// Modify the buffer(s)
pub fn update(screen_type: scr.ScreenType) !void {
    screen = try scr.buildScreen(screen_type);
}
