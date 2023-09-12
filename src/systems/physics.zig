const std = @import("std");
const zpy = @import("zbullet");
const cbe = @import("../objects/cube.zig");
const sys = @import("../systems/system.zig");

// allocator appropriate for physics?
var arena_allocator: std.mem.Allocator = undefined;

// physics containers?
var physics_world: zpy.World = undefined;
var physics_cube_shape: zpy.BoxShape = undefined;

/// Generate a phys cube and add new cube to the physics blob
/// TODO interpolate rotation into 3x3 matrix... maybe?
/// TODO figure out why no collision
pub fn addPhysCube(cube: *cbe.Cube) zpy.Body {
    const cube_type = @as(cbe.CubeType, @enumFromInt(cube.cube_data & 7));
    const mass: f32 = if (cube_type == cbe.CubeType.player or cube_type == cbe.CubeType.enemy) 1.0 else 0.0;
    const axial = cube.euclid.position.getAxial();
    const initial_phys_cube_transform = [_]f32{
        cube.euclid.scale.x, 0.0,                 0.0, // orientation
        0.0,                 cube.euclid.scale.z, 0.0,
        0.0,                 0.0,                 cube.euclid.scale.y,
        axial.x, axial.z, axial.y, // translation
    };
    const phys_body = zpy.initBody(
        mass, // mass (0.0 for static objects)
        &initial_phys_cube_transform,
        physics_cube_shape.asShape(),
    );

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
    arena_allocator = std.heap.ArenaAllocator.init(sys.allocator).allocator();
    zpy.init(arena_allocator);
    physics_world = zpy.initWorld();
    physics_cube_shape = zpy.initBoxShape(&.{ 0.5, 0.5, 0.5 });
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
