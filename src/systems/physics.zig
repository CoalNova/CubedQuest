const std = @import("std");
const zpy = @import("zbullet");
const zmt = @import("zmath");
const csm = @import("../systems/csmath.zig");
const sys = @import("../systems/system.zig");
const cbe = @import("../objects/cube.zig");
const tpe = @import("../types/types.zig");

// allocator appropriate for physics?
var a_a = std.heap.ArenaAllocator.init(sys.allocator);
const arena_allocator = a_a.allocator();

// physics containers?
var physics_world: zpy.World = undefined;
var physics_cube_shape: zpy.BoxShape = undefined;

/// Generate a phys cube and add new cube to the physics blob
/// TODO interpolate rotation into 3x3 matrix... maybe?
/// TODO figure out why no collision
pub fn addPhysCube(cube: *cbe.Cube, index: u8) zpy.Body {

    //
    const cube_type = @as(cbe.CubeType, @enumFromInt(cube.cube_data & 7));
    const mass: f32 = if (cube_type == cbe.CubeType.player or cube_type == cbe.CubeType.enemy) 1.0 else 0.0;

    std.debug.print("CUBE: {} MASS {}\n", .{ cube_type, mass });

    const axial = cube.euclid.position.getAxial();
    const scale = tpe.Float3{
        .x = cube.euclid.scale.x * 0.5,
        .y = cube.euclid.scale.y * 0.5,
        .z = cube.euclid.scale.z * 0.5,
    };
    const rotform = csm.convQuatToMat4(cube.euclid.rotation);
    const initial_phys_cube_transform = [_]f32{
        rotform[0][0], rotform[0][1], rotform[0][2], // orientation
        rotform[1][0], rotform[1][1], rotform[1][2],
        rotform[2][0], rotform[2][1], rotform[2][2],
        axial.x, axial.y, axial.z, // translation
    };
    const box_cube = zpy.initBoxShape(&scale.toArray());
    var phys_body = zpy.initBody(
        mass, // mass (0.0 for static objects)
        &initial_phys_cube_transform,
        box_cube.asShape(),
    );

    phys_body.setCcdSweptSphereRadius(0.5);
    phys_body.setUserIndex(0, index);
    phys_body.setFriction(1.0);
    phys_body.setRollingFriction(0.0);
    phys_body.setSpinningFriction(1.5);
    phys_body.setDamping(0.3, 1.9);
    phys_body.setActivationState(.deactivation_disabled);
    // add body to the physics world
    physics_world.addBody(phys_body);
    return phys_body;
}

/// Remove Physics Cube
pub fn remPhysCube(cube: *cbe.Cube) void {
    physics_world.removeBody(cube.phys_body);
    cube.phys_body.deinit();
}

/// Initialize Physics World and Cube Physics Template?
pub fn init() void {
    zpy.init(arena_allocator);
    physics_world = zpy.initWorld();
    physics_world.setGravity(&[3]f32{ 0, 0, -9.8 });
    physics_cube_shape = zpy.initBoxShape(&.{ 1.0, 1.0, 1.0 });
    std.log.info("Bullet Physics initialized successfully", .{});
    sys.setStateOn(sys.EngineState.physics);
}

/// Deinitilaize Physics World
pub fn deinit() void {
    sys.setStateOff(sys.EngineState.physics);
    physics_cube_shape.deinit();
    physics_world.deinit();
    zpy.deinit();
}

/// Process Physworld
/// TODO proper timing on physics steps
pub fn proc() void {
    _ = physics_world.stepSimulation(0.015, .{});
}
