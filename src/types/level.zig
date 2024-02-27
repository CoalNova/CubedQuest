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
const scr = @import("../render/screen.zig");
const rui = @import("../render/ui.zig");
const euc = @import("../types/euclid.zig");

/// Active Level Struct
/// TODO/MEBE figure out how this is gonna work
pub const ActiveLevel = struct {
    level: Level = undefined,
    name: []const u8 = "level",
    cubes: std.ArrayList(cbe.Cube) = undefined,
    links: std.ArrayList(Link) = undefined,
    sky_color: tpe.Float4 = tpe.Float4.init(1, 1, 1, 1),
    sun_color: tpe.Float4 = tpe.Float4.init(1, 1, 1, 1),
    amb_color: tpe.Float4 = tpe.Float4.init(1, 1, 1, 1),
    amb_lumin: f32 = 0.01,
    sun_direction: tpe.Float3 = tpe.Float3.init(-0.2, 0.3, -0.5),
    start_time: std.time.Instant = undefined,
    end_time: std.time.Instant = undefined,
    cur_score: u8 = 0,
    max_score: u8 = 0,
    lvl_state: LevelState = LevelState.degenerateded,
    allocator: std.mem.Allocator = undefined,
    pub fn init(self: *ActiveLevel, allocator: std.mem.Allocator) void {
        self.allocator = allocator;
    }
    pub fn generateFromLevel(self: *ActiveLevel, level: Level) !void {
        // unload active, just in case
        if (self.lvl_state != LevelState.degenerateded)
            self.degenLevel();
        self.cur_score = 0;
        self.level = level;
        self.amb_color.fromUIntArray(level.amb_color, 255.0);
        self.sun_color.fromUIntArray(level.sun_color, 255.0);
        self.sky_color.fromUIntArray(level.sky_color, 255.0);
        self.cubes = std.ArrayList(cbe.Cube).init(self.allocator);
        self.links = std.ArrayList(Link).init(self.allocator);

        for (level.ogds, 0..) |ogd, i| {
            try self.cubes.append(try cbe.createCube(ogd, @intCast(i)));
            if (ogd.cube_type == @intFromEnum(cbe.CubeType.coin))
                self.max_score += 1;
        }

        self.sun_direction = .{
            .x = @as(f32, @floatFromInt(level.sun_direction[0])) / 128.0,
            .y = @as(f32, @floatFromInt(level.sun_direction[1])) / 128.0,
            .z = @as(f32, @floatFromInt(level.sun_direction[2])) / 128.0,
        };

        //manual normalizitaion?
        const sum: f32 =
            @abs(self.sun_direction.x) +
            @abs(self.sun_direction.y) +
            @abs(self.sun_direction.z);
        if (sum != 0) {
            self.sun_direction.x /= sum;
            self.sun_direction.y /= sum;
            self.sun_direction.z /= sum;
        }

        self.amb_lumin = @as(f32, @floatFromInt(level.amb_lumin)) / 255.0;
        const camera = &wnd.windows.items[0].camera;
        const position = pst.Position.init(.{}, .{
            .x = @as(f32, @floatFromInt(@as(i32, @intCast(level.cam_pos[0])) - 32768)) * 0.05,
            .y = @as(f32, @floatFromInt(@as(i32, @intCast(level.cam_pos[1])) - 32768)) * 0.05,
            .z = @as(f32, @floatFromInt(@as(i32, @intCast(level.cam_pos[2])) - 32768)) * 0.05 + 512,
        });

        camera.field_of_view = level.cam_fov;
        camera.euclid = euc.Euclid{
            .position = position,
            .rotation = level.cam_rot,
        };

        //self.links.init(self.allocator);
        for (0..level.link_list.len / 2) |l| {
            std.debug.print("{}-{}\n", .{ level.link_list[l * 2], level.link_list[l * 2 + 1] });
            const link = Link{
                .source = level.link_list[l * 2],
                .destination = level.link_list[l * 2 + 1],
            };
            try self.links.append(link);
        }

        setActiveState(.generated);
    }
    pub fn degenLevel(self: *ActiveLevel) void {
        for (self.cubes.items) |*cube|
            cbe.destroyCube(cube);

        self.cubes.deinit();
        self.lvl_state = LevelState.degenerateded;
        self.links.deinit();
    }
};

/// Serializable Level Struct
pub const Level = struct {
    name: []const u8 = undefined,
    ogds: []cbe.OGD = undefined,
    link_list: []u8 = undefined, // dual links, even is source, odd is dest
    sky_color: [4]u8 = undefined,
    sun_color: [4]u8 = undefined,
    amb_color: [4]u8 = undefined,
    sun_direction: [3]u8 = undefined, // as f32, minus 128, normalized
    amb_lumin: u8 = undefined,
    cam_pos: [3]u16 = undefined, // as i32, -= 32768, *= 0.05
    cam_rot: [4]f32 = undefined, // straight up quat
    cam_fov: f32 = undefined,
    cam_bind: u8 = undefined, // bitflag for camera bound on axis to object linked
    cam_link: u8 = undefined, // linked object to bind camera
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
pub const LevelState = enum(u8) {
    /// Level is not in an initilaized state
    uninitialized,
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
    /// Level is being edited
    editing,
};

pub var active_level: ActiveLevel = undefined;

pub fn bufferLevel(level: Level, allocator: std.mem.Allocator) ![]u8 {
    const buff_size =
        4 + 4 + 4 + 4 + 3 + 1 + 6 + 16 + 4 + 1 + 1 + 3 + level.name.len + level.ogds.len * @sizeOf(cbe.OGD) + level.link_list.len;
    var buffer = try allocator.alloc(u8, buff_size);

    for (buffer, 0..) |*b, l| b.* = @as(u8, @intCast(l));

    @memcpy(buffer[0..4], "CQ3\x01");
    var i: usize = 4;

    // Sky Color - 4u8
    @memcpy(buffer[i .. i + 4], &level.sky_color);
    i += 4;
    // Sun Color - 4u8
    @memcpy(buffer[i .. i + 4], &level.sun_color);
    i += 4;
    // Ambient Color - 4u8
    @memcpy(buffer[i .. i + 4], &level.amb_color);
    i += 4;
    // Sun Direction - 3u8
    @memcpy(buffer[i .. i + 3], &level.sun_direction);
    i += 3;
    // Ambient Luminent - u8
    buffer[i] = level.amb_lumin;
    i += 1;

    // Camera Position - [3]u16
    for (0..3) |j| {
        buffer[i] = @as(u8, @intCast(level.cam_pos[j] & 255));
        buffer[i + 1] = @as(u8, @intCast(level.cam_pos[j] >> 8));
        i += 2;
    }

    // Camera Rotation - [4]f32
    for (0..4) |j| {
        for (0..4) |k| {
            buffer[i] = @as(u8, @intCast((@as(u32, @bitCast(level.cam_rot[j])) >>
                (@as(u5, @intCast(k)) * 8)) & 255));
            i += 1;
        }
    }

    // Cam Field of View - f32
    for (0..4) |j| {
        buffer[i] = @as(u8, @intCast((@as(u32, @bitCast(level.cam_fov)) >>
            (@as(u5, @intCast(j)) * 8)) & 255));
        i += 1;
    }

    // Camera Binds - u8
    buffer[i] = level.cam_bind;
    i += 1;

    // Camera Link - u8
    buffer[i] = level.cam_link;
    i += 1;

    // Name Length - u8
    buffer[i] = @as(u8, @intCast(level.name.len));
    i += 1;

    // Name - []u8
    @memcpy(buffer[i .. i + level.name.len], level.name);
    i += level.name.len;

    // OGDs Length - u8
    buffer[i] = @intCast(level.ogds.len);
    i += 1;

    // OGDs - []u8
    for (0..level.ogds.len) |j| {
        for (0..@sizeOf(cbe.OGD)) |k| {
            buffer[i] =
                @as(u8, @intCast((@as(u64, @bitCast(level.ogds[j])) >>
                (@as(u6, @intCast(k)) * 8)) & 255));
            i += 1;
        }
    }

    // Linked List Length - u8
    buffer[i] = @intCast(level.link_list.len);
    i += 1;

    // Linked List - []u8
    @memcpy(buffer[i .. i + level.link_list.len], level.link_list);

    return buffer;
}

/// Generate level from level file
pub fn levelFromBuffer(buffer: []const u8, allocator: std.mem.Allocator) !Level {
    if (!std.mem.eql(u8, buffer[0..3], "CQ3")) {
        std.log.err("Provided file was not a valid level file", .{});
        return error.InvalidLevelFileFormat;
    }

    // for versioning updated processes
    const proc_ver = buffer[3];
    const processors = [_]u8{1};
    for (processors) |proc| {
        if (proc_ver == proc) {
            var level: Level = .{};

            // raw data index
            var i: usize = 4;

            // Sky Color - 4u8
            @memcpy(&level.sky_color, buffer[i .. i + 4]);
            i += 4;
            // Sun Color - 4u8
            @memcpy(&level.sun_color, buffer[i .. i + 4]);
            i += 4;
            // Ambient Color - 4u8
            @memcpy(&level.amb_color, buffer[i .. i + 4]);
            i += 4;
            // Sun Direction - 3u8
            @memcpy(&level.sun_direction, buffer[i .. i + 3]);
            i += 3;
            // Ambient Luminent - u8
            level.amb_lumin = buffer[i];
            i += 1;

            // Camera Position - [3]u16
            for (0..3) |j| {
                level.cam_pos[j] = @as(u16, @intCast(buffer[i])) +
                    (@as(u16, @intCast(buffer[i + 1])) << 8);
                i += 2;
            }

            // Camera Rotation - [4]f32
            for (0..4) |j| {
                var f: u32 = 0;
                for (0..4) |k| {
                    f += @as(u32, buffer[i]) << (8 * @as(u5, @intCast(k)));
                    i += 1;
                }
                level.cam_rot[j] = @as(f32, @bitCast(f));
            }

            // Cam Field of View - f32
            {
                var f: u32 = 0;
                for (0..4) |j| {
                    f += @as(u32, buffer[i]) << (8 * @as(u5, @intCast(j)));
                    i += 1;
                }
                level.cam_fov = @bitCast(f);
            }

            // Camera Binds - u8
            level.cam_bind = buffer[i];
            i += 1;

            // Camera Link - u8
            level.cam_link = buffer[i];
            i += 1;

            // Name Length - u8
            const name_length = buffer[i];
            i += 1;

            // Name - []u8
            const name = try allocator.alloc(u8, name_length);
            @memcpy(name, buffer[i .. i + name_length]);
            level.name = name;
            i += name_length;

            // OGDs Length - u8
            const ogd_length = buffer[i];
            i += 1;

            // OGDs - []u8
            level.ogds = try allocator.alloc(cbe.OGD, ogd_length);
            for (0..ogd_length) |j| {
                var ogd: u64 = 0;
                for (0..@sizeOf(cbe.OGD)) |k| {
                    ogd += @as(u64, buffer[i]) << (@as(u6, @intCast(k)) * 8);
                    i += 1;
                }
                level.ogds[j] = @bitCast(ogd);
            }

            // Linked List Length - u8
            const list_length = buffer[i];
            i += 1;

            // Linked List - []u8
            level.link_list = try allocator.alloc(u8, list_length);
            @memcpy(level.link_list, buffer[i .. i + list_length]);

            for (level.link_list) |l| {
                std.debug.print("{}\n", .{l});
            }

            return level;
        }
    }
    std.log.err(
        "Level file version \"{d}\" incompatible with available processors {any}",
        .{ proc_ver, processors },
    );
    return error.ProcessingVersionIncompatible;
}

pub fn saveLevel(level: Level) !void {
    //TODO process cubes back -> front for proper transparency blending?

    _ = level;
}

pub fn setActiveState(state: LevelState) void {
    active_level.lvl_state = state;
    switch (state) {
        LevelState.generated => rui.update(scr.ScreenType.play_start) catch unreachable,
        LevelState.playing => rui.update(scr.ScreenType.play_playing) catch unreachable,
        LevelState.paused => rui.update(scr.ScreenType.play_pause) catch unreachable,
        LevelState.succeeded => rui.update(scr.ScreenType.play_succeed) catch unreachable,
        LevelState.failed => rui.update(scr.ScreenType.play_failure) catch unreachable,
        LevelState.degenerateded => rui.update(scr.ScreenType.start_landing) catch unreachable,
        LevelState.editing => rui.update(scr.ScreenType.level_select) catch unreachable,
        LevelState.uninitialized => rui.update(scr.ScreenType.level_select) catch unreachable,
    }
}

pub fn getActiveState() LevelState {
    return active_level.lvl_state;
}

const main_name: []const u8 = "Main Menu";
var main_ogds = [_]cbe.OGD{
    cbe.OGD{
        .cube_type = @intFromEnum(cbe.CubeType.ground),
        .cube_paint = @intFromEnum(cbe.CubePaint.ground),
        .sca_x = 4,
        .sca_y = 4,
        .sca_z = 4,
        .pos_z = 116,
    },
    cbe.OGD{
        .cube_type = @intFromEnum(cbe.CubeType.ground),
        .cube_paint = @intFromEnum(cbe.CubePaint.ground),
        .sca_x = 3,
        .sca_y = 3,
        .sca_z = 3,
        .pos_z = 124,
        .rot_x = 6,
        .rot_y = 2,
        .rot_z = 5,
    },
    cbe.OGD{
        .cube_type = @intFromEnum(cbe.CubeType.enemy),
        .cube_paint = @intFromEnum(cbe.CubePaint.enemy),
        .pos_x = 120,
        .pos_y = 120,
        .pos_z = 133,
    },
    cbe.OGD{
        .cube_type = @intFromEnum(cbe.CubeType.enemy),
        .cube_paint = @intFromEnum(cbe.CubePaint.enemy),
        .pos_x = 136,
        .pos_y = 120,
        .pos_z = 133,
    },
    cbe.OGD{
        .cube_type = @intFromEnum(cbe.CubeType.enemy),
        .cube_paint = @intFromEnum(cbe.CubePaint.enemy),
        .pos_x = 136,
        .pos_y = 136,
        .pos_z = 133,
    },
    cbe.OGD{
        .cube_type = @intFromEnum(cbe.CubeType.enemy),
        .cube_paint = @intFromEnum(cbe.CubePaint.enemy),
        .pos_x = 120,
        .pos_y = 136,
        .pos_z = 133,
    },
};
var main_link = [_]u8{ 2, 3, 3, 4, 4, 5, 5, 2 };

pub const main_menu: Level = .{
    .name = main_name,
    .ogds = &main_ogds,
    .link_list = &main_link,
    .sky_color = [_]u8{ 80, 95, 160, 255 },
    .sun_color = [_]u8{ 172, 128, 96, 0 },
    .amb_color = [_]u8{ 128, 128, 128, 255 },
    .amb_lumin = 128,
    .sun_direction = [_]u8{ 196, 128, 128 },

    .cam_rot = csm.convEulToQuat(csm.Vec3{ 0.0, 3.14159 / 2.0, 0.0 }),
    .cam_bind = 0,
    .cam_link = 0,
    .cam_pos = .{ 32768, 32768, 1500 + 32768 },
    .cam_fov = 0.4,
};

const debug_name: []const u8 = "Level 1";
var debug_ogds = [_]cbe.OGD{
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

pub const debug_level: Level = .{
    .name = debug_name,
    .ogds = &debug_ogds,

    .sky_color = [_]u8{ 80, 95, 160, 255 },
    .sun_color = [_]u8{ 100, 118, 126, 0 },
    .amb_color = [_]u8{ 12, 8, 0, 0 },
    .amb_lumin = 210,
    .sun_direction = [_]u8{ 168, 152, 184 },

    .cam_pos = .{ 32768, 32768 - (50 * 20), 32768 + (46 * 20) },
    .cam_rot = csm.convEulToQuat(csm.Vec3{ 0.0, 0.75, 0.0 }),
    .cam_fov = 0.33,
};
