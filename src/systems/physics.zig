const std = @import("std");
const zph = @import("zphysics");
const zmt = @import("zmath");
const csm = @import("../systems/csmath.zig");
const sys = @import("../systems/system.zig");
const cbe = @import("../objects/cube.zig");
const tpe = @import("../types/types.zig");

// allocator appropriate for physics?
var a_a = std.heap.ArenaAllocator.init(sys.allocator);
const arena_allocator = a_a.allocator();

// physics containers?
var physics_system: *zph.PhysicsSystem = undefined;
var broad_phase_layer_interface: *BroadPhaseLayerInterface = undefined;
var object_vs_broad_phase_layer_filter: *ObjectVsBroadPhaseLayerFilter = undefined;
var object_layer_pair_filter: *ObjectLayerPairFilter = undefined;
var contact_listener: *ContactListener = undefined;
var body_interface: *zph.BodyInterface = undefined;

/// Generate a phys cube and add new cube to the physics blob
/// TODO figure out why no collision
pub fn addPhysCube(cube: *cbe.Cube, index: u8) !void {
    _ = index;

    const axial = cube.euclid.position.getAxial();
    const quat = cube.euclid.rotation;
    const scale = cube.euclid.scale;

    // half extents?
    const box_shape_settings = try zph.BoxShapeSettings.create(.{ scale.x * 0.5, scale.y * 0.5, scale.z * 0.5 });
    defer box_shape_settings.release();

    const box_shape = try box_shape_settings.createShape();
    defer box_shape.release();

    //pub const BodyCreationSettings = extern struct {
    //position: [4]Real align(rvec_align) = .{ 0, 0, 0, 0 }, // 4th element is ignored
    //rotation: [4]f32 align(16) = .{ 0, 0, 0, 1 },
    //linear_velocity: [4]f32 align(16) = .{ 0, 0, 0, 0 }, // 4th element is ignored
    //angular_velocity: [4]f32 align(16) = .{ 0, 0, 0, 0 }, // 4th element is ignored
    //user_data: u64 = 0,
    //object_layer: ObjectLayer = 0,
    //collision_group: CollisionGroup = .{},
    //motion_type: MotionType = .dynamic,
    //allow_dynamic_or_kinematic: bool = false,
    //is_sensor: bool = false,
    //use_manifold_reduction: bool = true,
    //motion_quality: MotionQuality = .discrete,
    //allow_sleeping: bool = true,
    //friction: f32 = 0.2,
    //restitution: f32 = 0.0,
    //linear_damping: f32 = 0.05,
    //angular_damping: f32 = 0.05,
    //max_linear_velocity: f32 = 500.0,
    //max_angular_velocity: f32 = 0.25 * c.JPC_PI * 60.0,
    //gravity_factor: f32 = 1.0,
    //override_mass_properties: OverrideMassProperties = .calc_mass_inertia,
    //inertia_multiplier: f32 = 1.0,
    //mass_properties_override: MassProperties = .{},
    //reserved: ?*const anyopaque = null,
    //shape: ?*const Shape = null,

    cube.phys_body = try body_interface.createBody(.{
        .motion_type = if (cube.cube_type == cbe.CubeType.player or cube.cube_type == cbe.CubeType.enemy) .dynamic else .static,
        .position = .{ axial.x, axial.y, axial.z, 1.0 }, // 4th element is ignored
        .rotation = .{ quat[0], quat[1], quat[2], quat[3] },
        .shape = box_shape,
        .mass_properties_override = .{ .mass = 1.0 },
        .allow_sleeping = false,
        .motion_type = .static,
    });

    physics_system.optimizeBroadPhase();
}

/// Remove Physics Cube
pub fn remPhysCube(cube: *cbe.Cube) void {
    if (cube.phys_body) |body|
        body_interface.removeAndDestroyBody(body.id);
}

/// Initialize Physics World and Cube Physics Template?
pub fn init() !void {
    broad_phase_layer_interface = try sys.allocator.create(BroadPhaseLayerInterface);
    object_vs_broad_phase_layer_filter = try sys.allocator.create(ObjectVsBroadPhaseLayerFilter);
    object_layer_pair_filter = try sys.allocator.create(ObjectLayerPairFilter);
    contact_listener = try sys.allocator.create(ContactListener);

    broad_phase_layer_interface.* = BroadPhaseLayerInterface.init();
    object_vs_broad_phase_layer_filter.* = .{};
    object_layer_pair_filter.* = .{};
    contact_listener.* = .{};

    try zph.init(sys.allocator, .{});
    physics_system = try zph.PhysicsSystem.create(
        @as(*const zph.BroadPhaseLayerInterface, @ptrCast(broad_phase_layer_interface)),
        @as(*const zph.ObjectVsBroadPhaseLayerFilter, @ptrCast(object_vs_broad_phase_layer_filter)),
        @as(*const zph.ObjectLayerPairFilter, @ptrCast(object_layer_pair_filter)),
        .{
            .max_bodies = 1024,
            .num_body_mutexes = 0,
            .max_body_pairs = 1024,
            .max_contact_constraints = 1024,
        },
    );

    physics_system.setGravity(.{ 0, 0, -9.88 });

    body_interface = physics_system.getBodyInterfaceMut();
    std.log.info("ZPhysics (Jolt) initialized successfully", .{});
    sys.setStateOn(sys.EngineState.physics);
}

/// Deinitilaize Physics World
pub fn deinit() void {
    sys.setStateOff(sys.EngineState.physics);
    physics_system.destroy();
    zph.deinit();
}

/// Process Physworld
/// TODO proper timing on physics steps
pub fn proc() void {
    physics_system.update(1.0 / 60.0, .{}) catch unreachable;
}

///
const BroadPhaseLayerInterface = extern struct {
    usingnamespace zph.BroadPhaseLayerInterface.Methods(@This());
    __v: *const zph.BroadPhaseLayerInterface.VTable = &vtable,

    object_to_broad_phase: [object_layers.len]zph.BroadPhaseLayer = undefined,

    const vtable = zph.BroadPhaseLayerInterface.VTable{
        .getNumBroadPhaseLayers = _getNumBroadPhaseLayers,
        .getBroadPhaseLayer = _getBroadPhaseLayer,
    };

    fn init() BroadPhaseLayerInterface {
        var layer_interface: BroadPhaseLayerInterface = .{};
        layer_interface.object_to_broad_phase[object_layers.non_moving] = broad_phase_layers.non_moving;
        layer_interface.object_to_broad_phase[object_layers.moving] = broad_phase_layers.moving;
        return layer_interface;
    }

    fn _getNumBroadPhaseLayers(_: *const zph.BroadPhaseLayerInterface) callconv(.C) u32 {
        return broad_phase_layers.len;
    }

    fn _getBroadPhaseLayer(
        iself: *const zph.BroadPhaseLayerInterface,
        layer: zph.ObjectLayer,
    ) callconv(.C) zph.BroadPhaseLayer {
        const self = @as(*const BroadPhaseLayerInterface, @ptrCast(iself));
        return self.object_to_broad_phase[layer];
    }
};

const ObjectVsBroadPhaseLayerFilter = extern struct {
    usingnamespace zph.ObjectVsBroadPhaseLayerFilter.Methods(@This());
    __v: *const zph.ObjectVsBroadPhaseLayerFilter.VTable = &vtable,

    const vtable = zph.ObjectVsBroadPhaseLayerFilter.VTable{ .shouldCollide = _shouldCollide };

    fn _shouldCollide(
        _: *const zph.ObjectVsBroadPhaseLayerFilter,
        layer1: zph.ObjectLayer,
        layer2: zph.BroadPhaseLayer,
    ) callconv(.C) bool {
        return switch (layer1) {
            object_layers.non_moving => layer2 == broad_phase_layers.moving,
            object_layers.moving => true,
            else => unreachable,
        };
    }
};

const ObjectLayerPairFilter = extern struct {
    usingnamespace zph.ObjectLayerPairFilter.Methods(@This());
    __v: *const zph.ObjectLayerPairFilter.VTable = &vtable,

    const vtable = zph.ObjectLayerPairFilter.VTable{ .shouldCollide = _shouldCollide };

    fn _shouldCollide(
        _: *const zph.ObjectLayerPairFilter,
        object1: zph.ObjectLayer,
        object2: zph.ObjectLayer,
    ) callconv(.C) bool {
        return switch (object1) {
            object_layers.non_moving => object2 == object_layers.moving,
            object_layers.moving => true,
            else => unreachable,
        };
    }
};

const ContactListener = extern struct {
    usingnamespace zph.ContactListener.Methods(@This());
    __v: *const zph.ContactListener.VTable = &vtable,

    const vtable = zph.ContactListener.VTable{ .onContactValidate = _onContactValidate };

    fn _onContactValidate(
        self: *zph.ContactListener,
        body1: *const zph.Body,
        body2: *const zph.Body,
        base_offset: *const [3]zph.Real,
        collision_result: *const zph.CollideShapeResult,
    ) callconv(.C) zph.ValidateResult {
        _ = self;
        _ = body1;
        _ = body2;
        _ = base_offset;
        _ = collision_result;
        return .accept_all_contacts;
    }
};

const object_layers = struct {
    const non_moving: zph.ObjectLayer = 0;
    const moving: zph.ObjectLayer = 1;
    const len: u32 = 2;
};

const broad_phase_layers = struct {
    const non_moving: zph.BroadPhaseLayer = 0;
    const moving: zph.BroadPhaseLayer = 1;
    const len: u32 = 2;
};
