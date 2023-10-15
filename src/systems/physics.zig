const std = @import("std");
const zphysics = @import("zphysics");
const zmt = @import("zmath");
const csm = @import("../systems/csmath.zig");
const sys = @import("../systems/system.zig");
const cbe = @import("../objects/cube.zig");
const tpe = @import("../types/types.zig");

// allocator appropriate for physics?
var a_a = std.heap.ArenaAllocator.init(sys.allocator);
const arena_allocator = a_a.allocator();

// physics containers?
const Phystainer = struct{
    physics_system: *zphysics.PhysicsSystem = undefined,
    broad_phase_layer_interface: *BroadPhaseLayerInterface = undefined,
    object_vs_broad_phase_layer_filter: *ObjectVsBroadPhaseLayerFilter = undefined,
    object_layer_pair_filter: *ObjectLayerPairFilter = undefined,
    contact_listener: *ContactListener = undefined,
    body_interface: *zphysics.BodyInterface = undefined,
    lock_interface: *const zphysics.BodyLockInterface = undefined,
    collision_group: zphysics.CollisionGroup = .{.group_id = @as(c_uint, 1), .sub_group_id = @as(c_uint, 1), },
 };

var phys = Phystainer{};

/// Initialize Physics World and Cube Physics Template?
pub fn init() !void {
    phys.broad_phase_layer_interface = try sys.allocator.create(BroadPhaseLayerInterface);
    phys.object_vs_broad_phase_layer_filter = try sys.allocator.create(ObjectVsBroadPhaseLayerFilter);
    phys.object_layer_pair_filter = try sys.allocator.create(ObjectLayerPairFilter);
    phys.contact_listener = try sys.allocator.create(ContactListener);

    phys.broad_phase_layer_interface.* = BroadPhaseLayerInterface.init();
    phys.object_vs_broad_phase_layer_filter.* = .{};
    phys.object_layer_pair_filter.* = .{};
    phys.contact_listener.* = .{};

    try zphysics.init(sys.allocator, .{});
    phys.physics_system = try zphysics.PhysicsSystem.create(
        @as(*const zphysics.BroadPhaseLayerInterface, @ptrCast(phys.broad_phase_layer_interface)),
        @as(*const zphysics.ObjectVsBroadPhaseLayerFilter, @ptrCast(phys.object_vs_broad_phase_layer_filter)),
        @as(*const zphysics.ObjectLayerPairFilter, @ptrCast(phys.object_layer_pair_filter)),
        .{
            .max_bodies = 1024,
            .num_body_mutexes = 0,
            .max_body_pairs = 1024,
            .max_contact_constraints = 1024,
        },
    );

    phys.physics_system.setGravity(.{ 0, 0, -9.88 });

    phys.body_interface = phys.physics_system.getBodyInterfaceMut();
    phys.lock_interface = phys.physics_system.getBodyLockInterface();
    std.log.info("ZPhysics (Jolt) initialized successfully", .{});
    sys.setStateOn(sys.EngineState.physics);
}

/// Deinitilaize Physics World
pub fn deinit() void {
    sys.setStateOff(sys.EngineState.physics);
    phys.physics_system.destroy();
    zphysics.deinit();
}

/// Process Physworld
/// TODO proper timing on physics steps
pub fn proc() void {
    phys.physics_system.update(1.0 / 60.0, .{}) catch unreachable;
    //phys.contact_listener.onContactAdded()
    //phys.body_interface.
}


/// Generate a phys cube and add new cube to the physics blob
/// TODO figure out why no collision
pub fn addPhysCube(cube: *cbe.Cube, index: u8) !void {
    _ = index;

    const axial = cube.euclid.position.getAxial();
    const quat = cube.euclid.rotation;
    const scale = cube.euclid.scale;

    // half extents?
    const box_shape_settings = try zphysics.BoxShapeSettings.create(.{ scale.x * 0.5, scale.y * 0.5, scale.z * 0.5 });
    defer box_shape_settings.release();

    const box_shape = try box_shape_settings.createShape();
    defer box_shape.release();

    cube.phys_body = try phys.body_interface.createAndAddBody( .{
        .motion_type = if (cube.cube_type == cbe.CubeType.player or cube.cube_type == cbe.CubeType.enemy) .dynamic else .static,
        .position = .{ axial.x, axial.y, axial.z, 1.0 }, // 4th element is ignored
        .rotation = .{ quat[0], quat[1], quat[2], quat[3] },
        .shape = box_shape,
        .mass_properties_override = .{ .mass = 1.0 },
        .allow_sleeping = false,
        .collision_group = phys.collision_group,
        .object_layer = if (cube.cube_type == cbe.CubeType.player or cube.cube_type == cbe.CubeType.enemy) object_layers.moving else object_layers.non_moving,
        .friction = 1.0
    }, .activate);

    phys.physics_system.optimizeBroadPhase();
}

/// Remove Physics Cube
pub fn remPhysCube(cube: *cbe.Cube) void {
    phys.body_interface.removeAndDestroyBody(cube.phys_body);
    phys.physics_system.optimizeBroadPhase();

}

/// Process 
pub fn procCube(cube : *cbe.Cube, torque : @Vector(3, f32)) void {
    
    const max_ang = 12.0;

    //var write_lock: zph.BodyLockWrite = .{};
    //write_lock.lock(phys.lock_interface, cube.phys_body);
    //defer write_lock.unlock();
    //const body = write_lock.body.?;
    const cur_ang = phys.body_interface.getAngularVelocity(cube.phys_body);
    const ang_mag = @abs(cur_ang[0]) + @abs(cur_ang[2])  + @abs(cur_ang[1]);
    if (ang_mag < max_ang)
        phys.body_interface.addTorque(cube.phys_body, torque);
    //phys.body_interface.addForce(cube.phys_body, torque);


    //std.debug.print("cube {s}\n", .{if (phys.body_interface.isAdded(cube.phys_body)) "true" else "false"});
    const pos = phys.body_interface.getPosition(cube.phys_body);
    const rot = phys.body_interface.getRotation(cube.phys_body);

    cube.euclid.position.setAxial(tpe.Float3{
        .x = pos[0], 
        .y = pos[1], 
        .z = pos[2],
        });
    cube.euclid.rotation = zmt.Quat{
        rot[0],
        rot[1],
        rot[2],
        rot[3],
        };

         
    // if (zphysics.tryGetBody(phys.physics_system.tryGetBodies(), cube.phys_body)) |body|
    // {
    //     std.debug.print("{d}\n", .{body.getCollisionGroup().group_id});
    // }
}


/// Necessary for ZPhysics/Jolt
const BroadPhaseLayerInterface = extern struct {
    usingnamespace zphysics.BroadPhaseLayerInterface.Methods(@This());
    __v: *const zphysics.BroadPhaseLayerInterface.VTable = &vtable,

    object_to_broad_phase: [object_layers.len]zphysics.BroadPhaseLayer = undefined,

    const vtable = zphysics.BroadPhaseLayerInterface.VTable{
        .getNumBroadPhaseLayers = _getNumBroadPhaseLayers,
        .getBroadPhaseLayer = _getBroadPhaseLayer,
    };

    fn init() BroadPhaseLayerInterface {
        var layer_interface: BroadPhaseLayerInterface = .{};
        layer_interface.object_to_broad_phase[object_layers.non_moving] = broad_phase_layers.non_moving;
        layer_interface.object_to_broad_phase[object_layers.moving] = broad_phase_layers.moving;
        return layer_interface;
    }

    fn _getNumBroadPhaseLayers(_: *const zphysics.BroadPhaseLayerInterface) callconv(.C) u32 {
        return broad_phase_layers.len;
    }

    fn _getBroadPhaseLayer(
        iself: *const zphysics.BroadPhaseLayerInterface,
        layer: zphysics.ObjectLayer,
    ) callconv(.C) zphysics.BroadPhaseLayer {
        const self = @as(*const BroadPhaseLayerInterface, @ptrCast(iself));
        return self.object_to_broad_phase[layer];
    }
};

/// Necessary for ZPhysics/Jolt
const ObjectVsBroadPhaseLayerFilter = extern struct {
    usingnamespace zphysics.ObjectVsBroadPhaseLayerFilter.Methods(@This());
    __v: *const zphysics.ObjectVsBroadPhaseLayerFilter.VTable = &vtable,

    const vtable = zphysics.ObjectVsBroadPhaseLayerFilter.VTable{ .shouldCollide = _shouldCollide };

    fn _shouldCollide(
        _: *const zphysics.ObjectVsBroadPhaseLayerFilter,
        layer1: zphysics.ObjectLayer,
        layer2: zphysics.BroadPhaseLayer,
    ) callconv(.C) bool {
        return switch (layer1) {
            object_layers.non_moving => layer2 == broad_phase_layers.moving,
            object_layers.moving => true,
            else => unreachable,
        };
    }
};

/// Necessary for ZPhysics/Jolt
const ObjectLayerPairFilter = extern struct {
    usingnamespace zphysics.ObjectLayerPairFilter.Methods(@This());
    __v: *const zphysics.ObjectLayerPairFilter.VTable = &vtable,

    const vtable = zphysics.ObjectLayerPairFilter.VTable{ .shouldCollide = _shouldCollide };

    fn _shouldCollide(
        _: *const zphysics.ObjectLayerPairFilter,
        object1: zphysics.ObjectLayer,
        object2: zphysics.ObjectLayer,
    ) callconv(.C) bool {
        return switch (object1) {
            object_layers.non_moving => object2 == object_layers.moving,
            object_layers.moving => true,
            else => unreachable,
        };
    }
};

/// Necessary for ZPhysics/Jolt
const ContactListener = extern struct {
    usingnamespace zphysics.ContactListener.Methods(@This());
    __v: *const zphysics.ContactListener.VTable = &vtable,
    //system: *phys. SystemState,

    const vtable = zphysics.ContactListener.VTable{
        .onContactValidate = _onContactValidate,
        .onContactAdded = _onContactAdded,
    };

    fn _onContactValidate(
        iself: *zphysics.ContactListener,
        body1: *const zphysics.Body,
        body2: *const zphysics.Body,
        base_offset: *const [3]zphysics.Real,
        collision_result: *const zphysics.CollideShapeResult,
    ) callconv(.C) zphysics.ValidateResult {
        _ = iself;
        _ = body1;
        _ = body2;
        _ = base_offset;
        _ = collision_result;
        return .accept_all_contacts;
    }

    fn _onContactAdded(
        iself: *zphysics.ContactListener,
        body1: *const zphysics.Body,
        body2: *const zphysics.Body,
        manifold: *const zphysics.ContactManifold,
        settings: *zphysics.ContactSettings,
    ) callconv(.C) void {
        _ = settings;
        _ = manifold;
        _ = body2;
        _ = body1;
        const self = @as(*const ContactListener, @ptrCast(iself));
        _ = self;
        std.debug.print("Hullo\n", .{});
       
    }
};

const object_layers = struct {
    const non_moving: zphysics.ObjectLayer = 0;
    const moving: zphysics.ObjectLayer = 1;
    const len: u32 = 2;
};

const broad_phase_layers = struct {
    const non_moving: zphysics.BroadPhaseLayer = 0;
    const moving: zphysics.BroadPhaseLayer = 1;
    const len: u32 = 2;
};
