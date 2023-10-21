const std = @import("std");
const sys = @import("../systems/system.zig");
const msh = @import("../assets/mesh.zig");
const tpe = @import("../types/types.zig");

/// The box object drawn to the screen
pub const ScreenBox = struct {
    mesh_id: usize = 0,
    contents: []u8 = undefined,
    bounds: tpe.Float4 = .{},
};

/// Layout types available, number should align to []layouts index position
pub const LayoutType = enum(u8) {
    none = 0,
    main = 1,
    play = 2,
    pause = 3,
    success = 4,
    failure = 5,
    editor = 6,
    settings = 7,
};

/// The screen template for each type
/// Contains boxes, mostly
pub const Layout = struct {
    layout_type: LayoutType = undefined,
    boxes: []ScreenBox = undefined,
};

/// current layout container, set to none by default
var active_layout: *Layout = &layouts[0];

pub fn init() void {}
pub fn deinit() void {}

const layouts = [_]Layout{
    Layout{
        .layout_type = LayoutType.none,
        .boxes = [_]ScreenBox{},
    },
    Layout{
        .layout_type = LayoutType.main,
        .boxes = [_]ScreenBox{ScreenBox{
            .bounds = tpe.Float4.init(-0.8, -0.8, 0.2, 0.2),
            .contents = [_]u8{ 'h', 'u', 'l', 'l', 'o' },
        }},
    },
};

pub fn loadLayout(layout_type: LayoutType) !void {
    for (active_layout.boxes) |box|
        msh.meshes.release(box.mesh_id);

    active_layout = layouts[@intFromEnum(layout_type)];
    for (active_layout.boxes) |*box| {
        // 85 = 'U' 73 = 'I'
        box.mesh_id = try msh.meshes.fetch(8573);
    }
}

pub fn getActiveLayout() Layout {}
