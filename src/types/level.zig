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
pub const Level = struct {
    name: []const u8 = "level",
    cubes: []cbe.Cube = undefined,
    sky_color: tpe.Float4 = tpe.Float4.init(1, 1, 1, 1),
    light_color: tpe.Float4 = tpe.Float4.init(1, 1, 1, 1),
    amb_color: tpe.Float4 = tpe.Float4.init(1, 1, 1, 1),
    sun_direction: tpe.Float3 = tpe.Float3.init(-0.2, 0.3, -0.5),
};

/// Level State
/// The indication of where we are in playing the level
pub const LevelState = enum {
    loaded,
    playing,
    paused,
    failed,
    succeeded,
};

pub var active_level: Level = undefined;

pub fn loadDebugLevel() !Level {
    var level: Level = .{};

    level.name = "debug";
    level.cubes = try sys.allocator.alloc(cbe.Cube, 3);
    var ogd = cbe.OGD{
        .type = @intFromEnum(cbe.CubeType.player),
        .paint = @intFromEnum(cbe.CubePaint.player),
        .pos_z = 136,
    };
    var cube = try cbe.createCube(ogd, 0);
    level.cubes[0] = cube;
    ogd = cbe.OGD{
        .type = @intFromEnum(cbe.CubeType.ground),
        .paint = @intFromEnum(cbe.CubePaint.ground),
        .pos_z = 122,
        .sca_x = 4,
        .sca_y = 3,
        .sca_z = 0,
    };
    cube = try cbe.createCube(ogd, 1);
    level.cubes[1] = cube;
    ogd = cbe.OGD{
        .type = @intFromEnum(cbe.CubeType.ground),
        .paint = @intFromEnum(cbe.CubePaint.glass),
        .pos_z = 122,
        .pos_x = 129,
        .pos_y = 129,
        .sca_z = 2,
    };
    cube = try cbe.createCube(ogd, 2);
    level.cubes[2] = cube;

    const camera = &wnd.windows.items[0].camera;
    camera.euclid.position.addAxial(.{ -2.0, -4.0, 513.0 });
    camera.euclid.rotation = zmt.qmul(wnd.windows.items[0].camera.euclid.rotation, csm.convEulToQuat(
        csm.Vec3{ 0.0, 0.3, 0.3 },
    ));
    camera.field_of_view = 1.4;

    return level;
}

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
    _ = level;
}

pub fn saveLevel(level: Level) !void {
    //TODO process cubes back -> front for proper transparency blending
    _ = level;
}

/// Unloads current level and deletes
pub fn unloadActiveLevel() void {
    for (active_level.cubes) |*cube|
        cbe.destroyCube(cube);

    // this *should* panic is level cubes is not allocated,
    // but that's probably a failed state we'd want to catch
    sys.allocator.free(active_level.cubes);
}
