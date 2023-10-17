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

/// Active Level Struct
/// TODO/MEBE figure out how this is gonna work
pub const RunningLevel = struct {
    name: []const u8 = "level",
    cubes: std.ArrayList(cbe.Cube) = undefined,
    links: std.ArrayList(Link) = undefined,
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

/// Serializable Level Struct
pub const Level = struct {
    name: []u8 = undefined,
    ogds: []cbe.OGD = undefined,
    link_list: []u8 = undefined,
    sky_color: [4]u8 = undefined,
    amb_color: [4]u8 = undefined,
    sun_color: [4]u8 = undefined,
    sun_direction: [3]u8 = undefined,
};

pub const LinkType = enum(u8) {
    repeating = 0b0001,
    player = 0b0010,
    enemy = 0b0100,
};

/// Link Struct
pub const Link = struct {
    source: u8 = 0,
    link_type: u8 = 0,
    destination: u8 = 0,
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
    active_level = RunningLevel{};
    active_level.amb_color.fromUIntArray(level.amb_color, 255.0);
    active_level.sun_color.fromUIntArray(level.sun_color, 255.0);
    active_level.sky_color.fromUIntArray(level.sky_color, 255.0);
    active_level.cubes = std.ArrayList(cbe.Cube).init(sys.allocator);
    for (level.ogds, 0..) |ogd, i| {
        try active_level.cubes.append(try cbe.createCube(ogd, @intCast(i)));
        if (ogd.cube_type == @intFromEnum(cbe.CubeType.coin))
            active_level.max_score += 1;
    }
    active_level.sun_direction.fromUIntArray(level.sun_direction, 255.0);
    active_level.lvl_state = LevelState.generated;
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

/// DEBUG
/// Loads a debug first level, for testing and such
pub fn loadDebugLevel() !void {
    var name = [_]u8{ 'L', 'e', 'v', 'e', 'l', ' ', '1' };
    var ogds = [_]cbe.OGD{
        cbe.OGD{
            .cube_type = @intFromEnum(cbe.CubeType.player),
            .cube_paint = @intFromEnum(cbe.CubePaint.player),
            .pos_z = 128,
            .pos_x = 120,
        },
        cbe.OGD{
            .cube_type = @intFromEnum(cbe.CubeType.enemy),
            .cube_paint = @intFromEnum(cbe.CubePaint.enemy),
            .pos_z = 128,
            .pos_x = 136,
        },
        cbe.OGD{
            .pos_z = 126,
            .sca_x = 4,
            .sca_y = 4,
            .sca_z = 0,
        },
        cbe.OGD{
            .cube_paint = @intFromEnum(cbe.CubePaint.wall),
            .pos_y = 144,
            .sca_x = 4,
            .sca_z = 1,
        },
        cbe.OGD{
            .cube_paint = @intFromEnum(cbe.CubePaint.wall),
            .pos_y = 112,
            .sca_x = 4,
            .sca_z = 1,
        },
        cbe.OGD{
            .cube_paint = @intFromEnum(cbe.CubePaint.wall),
            .pos_x = 144,
            .sca_y = 4,
            .sca_z = 1,
        },
        cbe.OGD{
            .cube_paint = @intFromEnum(cbe.CubePaint.wall),
            .pos_x = 112,
            .sca_y = 4,
            .sca_z = 1,
        },
        cbe.OGD{
            .cube_paint = @intFromEnum(cbe.CubePaint.coin),
            .cube_type = @intFromEnum(cbe.CubeType.coin),
            .pos_y = 120,
            .pos_z = 129,
        },
        cbe.OGD{
            .cube_paint = @intFromEnum(cbe.CubePaint.coin),
            .cube_type = @intFromEnum(cbe.CubeType.coin),
            .pos_y = 138,
            .pos_x = 138,
            .pos_z = 129,
        },
        cbe.OGD{
            .cube_paint = @intFromEnum(cbe.CubePaint.coin),
            .cube_type = @intFromEnum(cbe.CubeType.coin),
            .pos_x = 114,
            .pos_z = 129,
        },
        cbe.OGD{
            .cube_paint = @intFromEnum(cbe.CubePaint.glass),
            .pos_z = 129,
            .sca_y = 2,
            .sca_x = 2,
            .sca_z = 1,
            .rot_z = 6,
        },
        cbe.OGD{
            .cube_type = @intFromEnum(cbe.CubeType.endgate),
            .pos_x = 142,
            .pos_z = 128,
        },
    };
    var level = Level{
        .name = &name,
        .sky_color = [_]u8{ 80, 95, 160, 255 },
        .sun_color = [_]u8{ 0, 255, 0, 255 },
        .amb_color = [_]u8{ 0, 0, 255, 255 },
        .ogds = &ogds,
    };

    const camera = &wnd.windows.items[0].camera;
    camera.euclid.position.addAxial(.{ .x = 0.0, .y = -8.0, .z = 522.0 });
    camera.euclid.rotation = zmt.qmul(wnd.windows.items[0].camera.euclid.rotation, csm.convEulToQuat(
        csm.Vec3{ 0.0, 0.8, 0.0 },
    ));
    camera.field_of_view = 1.6;
    return try generateLevel(level);
}
