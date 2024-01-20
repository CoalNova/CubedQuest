const std = @import("std");
const zgl = @import("zopengl");
const zdl = @import("zsdl");
const rnd = @import("../render/renderer.zig");
const tex = @import("../assets/texture.zig");

/// Possible errors, stored here because hell if I know what I'm doing
pub const GLSError = error{ GLInitFailed, GLValueOoB };

// Please ignore texture stack, it is shy and unfinished
// Texture stack go brrrrrrrr
pub var max_tex_array_layers: i32 = 0;
pub var max_tex_binding_points: i32 = 0;

const RendOpts = struct {
    poly_mode: enum { fill, line, point } = .fill,
    v_sync: enum { none, single, double, triple } = .none,
    t_blend: bool = true,
    culling: enum { none, front, back } = .back,
    z_depth: enum { none, front, back } = .back,
};

/// Initialize OpenGL, currently baked in at 3.3
pub fn initalizeGL(render_options: RendOpts) !void {
    try zgl.loadCoreProfile(rnd.getProcAddress, 3, 3);

    switch (render_options.poly_mode) {
        .fill => zgl.polygonMode(zgl.FRONT_AND_BACK, zgl.FILL),
        .line => zgl.polygonMode(zgl.FRONT_AND_BACK, zgl.LINE),
        .point => zgl.polygonMode(zgl.FRONT_AND_BACK, zgl.POINT),
    }

    switch (render_options.culling) {
        .none => {},
        .front => {
            zgl.enable(zgl.CULL_FACE);
            zgl.cullFace(zgl.FRONT);
        },
        .back => {
            zgl.enable(zgl.CULL_FACE);
            zgl.cullFace(zgl.BACK);
        },
    }
    switch (render_options.z_depth) {
        .none => {},
        .back => {
            zgl.enable(zgl.DEPTH_TEST);
            zgl.depthFunc(zgl.LESS);
        },
        .front => {
            zgl.enable(zgl.DEPTH_TEST);
            zgl.depthFunc(zgl.GREATER);
        },
    }

    if (render_options.t_blend) {
        zgl.enable(zgl.BLEND);
        zgl.blendFunc(zgl.SRC_ALPHA, zgl.ONE_MINUS_SRC_ALPHA);
    }

    zgl.clearColor(0.0, 0.01, 0.02, 1.0);

    zgl.getIntegerv(zgl.MAX_ARRAY_TEXTURE_LAYERS, &max_tex_array_layers);
    std.log.info("Max Texture Array Layer Depth: {}", .{max_tex_array_layers});
    zgl.getIntegerv(zgl.MAX_TEXTURE_IMAGE_UNITS, &max_tex_binding_points);
    std.log.info("Max Texture Binding Points: {}", .{max_tex_binding_points});
}

/// Toggles Wireframe rendering state
pub fn toggleWireFrame() void {
    const toggle_state = struct {
        var wire: bool = false;
    };

    toggle_state.wire = !toggle_state.wire;
    if (toggle_state.wire)
        zgl.polygonMode(zgl.FRONT_AND_BACK, zgl.LINE) //LINE
    else
        zgl.polygonMode(zgl.FRONT_AND_BACK, zgl.FILL); //FILL

}

// Name declarations for clarification
/// Texture name
pub const GLTexName = u32;
/// Texture compression/pixel type
pub const GLFmtType = u32;
pub const GLFmtSet = u32;
pub const GLType = u32;
