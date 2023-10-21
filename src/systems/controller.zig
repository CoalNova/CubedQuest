const std = @import("std");
const zdl = @import("zsdl");
const zmt = @import("zmath");
const zph = @import("zphysics");
const phy = @import("../systems/physics.zig");
const csm = @import("../systems/csmath.zig");
const evt = @import("../systems/event.zig");
const cbe = @import("../objects/cube.zig");
const tpe = @import("../types/types.zig");
const wnd = @import("../types/window.zig");
const lvl = @import("../types/level.zig");
const chr = @import("../systems/chrono.zig");

/// An Associated Event.Input Map
const InputMap = struct {
    input_forward: evt.Input = .{},
    input_backward: evt.Input = .{},
    input_leftward: evt.Input = .{},
    input_rightward: evt.Input = .{},
    input_upward: evt.Input = .{},
    input_downward: evt.Input = .{},
};

/// A List of All Maps
pub var inputmaps = [_]InputMap{
    InputMap{
        .input_forward = evt.Input{ .input_id = @intFromEnum(zdl.Scancode.w) },
        .input_backward = evt.Input{ .input_id = @intFromEnum(zdl.Scancode.s) },
        .input_leftward = evt.Input{ .input_id = @intFromEnum(zdl.Scancode.a) },
        .input_rightward = evt.Input{ .input_id = @intFromEnum(zdl.Scancode.d) },
        .input_upward = evt.Input{ .input_id = @intFromEnum(zdl.Scancode.space) },
        .input_downward = evt.Input{ .input_id = @intFromEnum(zdl.Scancode.lctrl) },
    },
};

/// Everything here is wrong
/// just thought you should know
pub fn procPlayer(cube: *cbe.Cube) void {
    // a rotational magnitude for testing inputs
    const rot_mag = 10000.0; //1.0 / (std.math.pi * 10.0);
    var euler = csm.Vec3{ 0, 0, 0 };

    if (evt.getInputStay(inputmaps[0].input_forward))
        euler += csm.Vec3{ -1.0, 0.0, 0.0 };
    if (evt.getInputStay(inputmaps[0].input_backward))
        euler += csm.Vec3{ 1.0, 0.0, 0.0 };
    if (evt.getInputStay(inputmaps[0].input_leftward))
        euler += csm.Vec3{ 0.0, -1.0, 0.0 };
    if (evt.getInputStay(inputmaps[0].input_rightward))
        euler += csm.Vec3{ 0.0, 1.0, 0.0 };

    euler *= csm.Vec3{ rot_mag, rot_mag, rot_mag };

    phy.procCube(cube, euler);
}

// does not adjust the physical collider
pub fn procCoin(cube: *cbe.Cube) void {
    if (lvl.active_level.lvl_state == lvl.LevelState.playing) {
        const delta = chr.frameDelta();
        cube.euclid.rotation = zmt.qmul(cube.euclid.rotation, csm.convEulToQuat(csm.Vec3{ 0, 0, 1 * delta }));
    }
}

pub fn procEnemy(cube: *cbe.Cube) void {
    // a rotational magnitude
    const rot_mag = 10000.0;
    var euler = csm.Vec3{ 0, 0, 0 };
    const self = cube.euclid.position.getAxial();
    target_block: {
        // find if linked a target
        for (lvl.active_level.links.items) |link| {
            if (link.source == cube.self_index) {
                const target = lvl.active_level.cubes.items[link.destination].euclid.position.getAxial();
                euler = csm.normalizeVec3(csm.Vec3{ self.x - target.x, self.y - target.y, 0 });
                break :target_block;
            }
        }
        // else find player explicitly
        for (lvl.active_level.cubes.items) |c| {
            if (c.cube_type == cbe.CubeType.player) {
                const target = c.euclid.position.getAxial();
                euler = csm.normalizeVec3(csm.Vec3{ self.y - target.y, -(self.x - target.x), 0 });
                break :target_block;
            }
        }
    }

    euler *= csm.Vec3{ rot_mag, rot_mag, rot_mag };
    phy.procCube(cube, euler);
}
