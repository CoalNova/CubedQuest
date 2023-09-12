const std = @import("std");
const zmath = @import("libs/zmath/build.zig");
const zbullet = @import("libs/zbullet/build.zig");
const zopengl = @import("libs/zopengl/build.zig");
const zsdl = @import("libs/zsdl/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "cubedquest",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const zsdl_pkg = zsdl.package(b, target, optimize, .{});
    const zopengl_pkg = zopengl.package(b, target, optimize, .{});
    const zbullet_pkg = zbullet.package(b, target, optimize, .{});
    const zmath_pkg = zmath.package(b, target, optimize, .{
        .options = .{ .enable_cross_platform_determinism = true },
    });

    zsdl_pkg.link(exe);
    zmath_pkg.link(exe);
    zopengl_pkg.link(exe);
    zbullet_pkg.link(exe);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
