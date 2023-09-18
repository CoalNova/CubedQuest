const std = @import("std");
const zmt = @import("zmath");
const csm = @import("../systems/csmath.zig");
const sys = @import("../systems/system.zig");
const cbe = @import("../objects/cube.zig");
const tpe = @import("../types/types.zig");
const cam = @import("../objects/camera.zig");
const pos = @import("../types/position.zig");
const wnd = @import("../types/window.zig");
const pst = @import("../types/position.zig");

/// Level Struct
/// TODO/MEBE figure out how this is gonna work
pub const RunningLevel = struct {
    name: []const u8 = "level",
    cubes: std.ArrayList(cbe.Cube) = undefined,
    sky_color: tpe.Float4 = tpe.Float4.init(1, 1, 1, 1),
    sun_color: tpe.Float4 = tpe.Float4.init(1, 1, 1, 1),
    amb_color: tpe.Float4 = tpe.Float4.init(1, 1, 1, 1),
    sun_direction: tpe.Float3 = tpe.Float3.init(-0.2, 0.3, -0.5),
    start_time: std.time.Instant = undefined,
    end_time: std.time.Instant = undefined,
    cur_score: u8 = 0,
    max_score: u8 = 0,
    lvl_state: LevelState = LevelState.degenerateded,
};

pub const Level = struct {
    name: []u8 = undefined,
    ogds: []cbe.OGD = undefined,
    link_list: []u8 = undefined,
    sky_color: [4]u8 = undefined,
    amb_color: [4]u8 = undefined,
    sun_color: [4]u8 = undefined,
    sun_direction: [3]u8 = undefined,
};

/// Level State
/// The indication of where we are in playing the level
pub const LevelState = enum {
    /// Level is not in an interactable state, and has been cleared of data
    degenerateded,
    /// Level is loaded, generated, and prepped for play
    generated,
    /// Level is being played
    playing,
    /// Level play state is paused, likely in menu
    paused,
    /// Failed
    failed,
    /// Succeeded
    succeeded,
};

pub var active_level: RunningLevel = undefined;

/// Generate level from level file
/// TODO de-confuse the process, leave level structs in as separate entities?
///      or loaded/gen'd levels as seperate structs?
pub fn loadLevel(filepath: []const u8) !Level {
    var file: std.fs.File = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();
    const data = try file.readToEndAlloc(sys.allocator, 65536);
    defer sys.allocator.free(data);
    if (!std.mem.eql(u8, data[0..3], "CQ3")) {
        std.log.err("Provided file [{s}] was not a valid level file", .{filepath});
        return error.InvalidLevelFileFormat;
    }

    // for versioning updated processes
    var proc_ver = data[4];
    const processors = [_]u8{1};
    for (processors) |proc| {
        if (proc_ver == proc) {
            //TODO use a function call to seperate process
            //TODO actually implement how this is gonna work
            var level: Level = .{};
            return level;
        }
    }
    std.log.err(
        "Level file version \"{d}\" for file [{s}] incompatible with available processors {}",
        .{ proc_ver, filepath, processors },
    );
    return error.ProcessingVersionIncompatible;
}

pub fn generateLevel(level: Level) !void {
    // unload active, just in case
    if (active_level.lvl_state != LevelState.degenerateded)
        unloadActiveLevel();
    var active = RunningLevel{};
    active.amb_color.fromUIntArray(level.amb_color, 255.0);
    active.sun_color.fromUIntArray(level.sun_color, 255.0);
    active.sky_color.fromUIntArray(level.sky_color, 255.0);
    active.cubes = try sys.allocator.alloc(cbe.Cube, level.ogds.len);
    for (level.ogds, 0..) |ogd, i| {
        active.cubes.appendAssumeCapacity(cbe.createCube(ogd, i));
        if ((ogd.data & 7) == @intFromEnum(cbe.CubeType.coin))
            active.max_score += 1;
    }
    active.sun_direction.fromUIntArray(level.sun_direction, 255.0);
    active.lvl_state = LevelState.generated;
}

pub fn convertActive() Level {}

pub fn saveLevel(level: Level) !void {
    //TODO process cubes back -> front for proper transparency blending?

    _ = level;
}

/// Unloads current level and deletes
pub fn unloadActiveLevel() void {
    for (active_level.cubes.items) |*cube|
        cbe.destroyCube(cube);

    active_level.cubes.deinit();
    active_level.lvl_state = LevelState.degenerateded;
}

///Loads a debug first level, for testing and such
pub fn loadDebugLevel() !RunningLevel {
    var level: RunningLevel = .{};

    level.name = "Level 1";

    level.cubes = std.ArrayList(cbe.Cube).init(sys.allocator);

    var ogd = cbe.OGD{
        .data = @intFromEnum(cbe.CubeType.player) +
            (@as(u8, @intFromEnum(cbe.CubePaint.player)) << 3),
        .pos_z = 130,
        .pos_x = 118,
    };
    try level.cubes.append(try cbe.createCube(ogd, 0));
    ogd = cbe.OGD{
        .data = @intFromEnum(cbe.CubeType.ground) +
            (@as(u8, @intFromEnum(cbe.CubePaint.ground)) << 3),
        .pos_z = 126,
        .sca_x = 4,
        .sca_y = 4,
        .sca_z = 0,
    };
    try level.cubes.append(try cbe.createCube(ogd, 1));

    ogd = cbe.OGD{
        .data = @intFromEnum(cbe.CubeType.ground) +
            (@as(u8, @intFromEnum(cbe.CubePaint.wall)) << 3),
        .pos_y = 144,
        .sca_x = 4,
        .sca_z = 1,
    };
    try level.cubes.append(try cbe.createCube(ogd, 2));
    ogd = cbe.OGD{
        .data = @intFromEnum(cbe.CubeType.ground) +
            (@as(u8, @intFromEnum(cbe.CubePaint.wall)) << 3),
        .pos_y = 112,
        .sca_x = 4,
        .sca_z = 1,
    };
    try level.cubes.append(try cbe.createCube(ogd, 3));

    ogd = cbe.OGD{
        .data = @intFromEnum(cbe.CubeType.ground) +
            (@as(u8, @intFromEnum(cbe.CubePaint.wall)) << 3),
        .pos_x = 144,
        .sca_y = 4,
        .sca_z = 1,
    };
    try level.cubes.append(try cbe.createCube(ogd, 4));

    ogd = cbe.OGD{
        .data = @intFromEnum(cbe.CubeType.ground) +
            (@as(u8, @intFromEnum(cbe.CubePaint.wall)) << 3),
        .pos_x = 112,
        .sca_y = 4,
        .sca_z = 1,
    };
    try level.cubes.append(try cbe.createCube(ogd, 5));

    ogd = cbe.OGD{
        .data = @intFromEnum(cbe.CubeType.ground) +
            (@as(u8, @intFromEnum(cbe.CubePaint.glass)) << 3),
        .pos_z = 129,
        .sca_y = 1,
        .sca_x = 1,
        .sca_z = 1,
        .rot_z = 6,
    };
    try level.cubes.append(try cbe.createCube(ogd, 6));

    ogd = cbe.OGD{
        .data = @intFromEnum(cbe.CubeType.enemy) +
            (@as(u8, @intFromEnum(cbe.CubePaint.enemy)) << 3),
        .pos_z = 130,
        .pos_x = 138,
    };
    try level.cubes.append(try cbe.createCube(ogd, 7));

    const camera = &wnd.windows.items[0].camera;
    camera.euclid.position.addAxial(.{ 0.0, -8.0, 522.0 });
    camera.euclid.rotation = zmt.qmul(wnd.windows.items[0].camera.euclid.rotation, csm.convEulToQuat(
        csm.Vec3{ 0.0, 0.8, 0.0 },
    ));
    camera.field_of_view = 1.6;
    level.sky_color = tpe.Float4.init(0.2, 0.3, 0.8, 1.0);

    return level;
}
