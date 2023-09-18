const std = @import("std");
const zmt = @import("zmath");
const zdl = @import("zsdl");
const zph = @import("zbullet");
const phy = @import("../systems/physics.zig");
const csm = @import("../systems/csmath.zig");
const sys = @import("../systems/system.zig");
const euc = @import("../types/euclid.zig");
const msh = @import("../assets/mesh.zig");
const pos = @import("../types/position.zig");
const cnt = @import("../systems/controller.zig");
const evt = @import("../systems/event.zig");
const tpe = @import("../types/types.zig");

/// Cube
pub const Cube = struct {
    euclid: euc.Euclid = .{},
    mesh_index: usize = 0,
    cube_data: u8 = 3 << 6, //part of an in-vain attempt to squeeze into 64 bytes (cache line)
    phys_body: zph.Body = undefined,
};

/// The Cube Type
/// For determining behavior
pub const CubeType = enum(u3) {
    ground = 0,
    player = 1,
    enemy = 2,
    endgate = 3,
    coin = 4,
    trigger = 5,
    force = 6,
    spotlight = 7,
};

/// Cube Paint
/// For makin' the cube look purty
pub const CubePaint = enum(u3) {
    ground = 0,
    wall = 1,
    obelisk = 2,
    glass = 3,
    player = 4,
    enemy = 5,
    coin = 6,
    invisible = 7,
};

/// Cube state,
/// if active, inactive, enabled, or disabled
pub const CubeState = enum(u2) {
    enabled = 0x01,
    active = 0x10,
};

pub const OGD = packed struct {
    data: u8 = 3 << 6, //state, paint, type
    pos_x: u8 = 128, //-128, *0.5f
    pos_y: u8 = 128,
    pos_z: u8 = 128,
    rot_x: u3 = 0, //division of rotation, in increments of pi rd/4 for full axis
    rot_y: u3 = 0,
    rot_z: u3 = 0,
    sca_x: u3 = 0, //2 ^ (x) (creates 1, 2, 4, 8, 16, 32, 64, 128)
    sca_y: u3 = 0,
    sca_z: u3 = 0,
};

/// Determines control type, paint type, and positioning
pub fn createCube(ogd: OGD, cube_index: u8) !Cube {
    var cube: Cube = .{
        .cube_data = ogd.data,
        .euclid = .{ .position = pos.Position.init(.{}, .{
            .x = (@as(f32, @floatFromInt(ogd.pos_x)) - 128.0) * 0.5,
            .y = (@as(f32, @floatFromInt(ogd.pos_y)) - 128.0) * 0.5,
            .z = (@as(f32, @floatFromInt(ogd.pos_z)) - 128.0) * 0.5 + 512,
        }), .scale = .{
            .x = std.math.pow(f32, 2.0, @as(f32, @floatFromInt(ogd.sca_x))),
            .y = std.math.pow(f32, 2.0, @as(f32, @floatFromInt(ogd.sca_y))),
            .z = std.math.pow(f32, 2.0, @as(f32, @floatFromInt(ogd.sca_z))),
        }, .rotation = csm.convEulToQuat(csm.Vec3{
            (std.math.pi / 8.0) * @as(f32, @floatFromInt(ogd.rot_x)),
            (std.math.pi / 8.0) * @as(f32, @floatFromInt(ogd.rot_y)),
            (std.math.pi / 8.0) * @as(f32, @floatFromInt(ogd.rot_z)),
        }) },
        .mesh_index = try msh.meshes.fetch(0),
    };

    cube.phys_body = phy.addPhysCube(&cube, cube_index);
    return cube;
}

/// Destroys cube and frees resources
pub fn destroyCube(cube: *Cube) void {
    phy.remPhysCube(cube);
    msh.meshes.release(0);
}

/// Cube Center Color
pub const aColors = [_]csm.Vec4{
    csm.Vec4{ 0.2, 0.7, 0.2, 1.0 }, //ground
    csm.Vec4{ 0.7, 0.6, 0.2, 1.0 }, //wall
    csm.Vec4{ 0.2, 0.1, 0.3, 1.0 }, //obelisk
    csm.Vec4{ 0.6, 0.6, 0.8, 0.4 }, //glass
    csm.Vec4{ 0.1, 0.3, 0.7, 1.0 }, //player
    csm.Vec4{ 0.8, 0.2, 0.1, 1.0 }, //enemy
    csm.Vec4{ 1.0, 1.0, 0.3, 1.0 }, //coin
    csm.Vec4{ 0.8, 0.6, 0.2, 0.3 }, //invisible with editor
};

/// Cube Edge Color
pub const bColors = [_]csm.Vec4{
    csm.Vec4{ 0.1, 0.35, 0.1, 1.0 }, //ground
    csm.Vec4{ 0.3, 0.3, 0.1, 1.0 }, //wall
    csm.Vec4{ 0.2, 0.1, 0.3, 1.0 }, //obelisk
    csm.Vec4{ 0.3, 0.3, 0.4, 0.7 }, //glass
    csm.Vec4{ 0.05, 0.15, 0.35, 1.0 }, //player
    csm.Vec4{ 0.5, 0.1, 0.1, 1.0 }, //enemy
    csm.Vec4{ 0.7, 0.7, 0.1, 1.0 }, //coin
    csm.Vec4{ 0.6, 0.3, 0.1, 0.4 }, //invisible with editor
};
