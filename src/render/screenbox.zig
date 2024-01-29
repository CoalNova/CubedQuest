const std = @import("std");
const zmt = @import("zmath");
const zgl = @import("zopengl");
const sys = @import("../systems/system.zig");
const msh = @import("../assets/mesh.zig");
const mat = @import("../assets/material.zig");
const shd = @import("../assets/shader.zig");
const tpe = @import("../types/types.zig");
const asc = @import("../assets/assetcollection.zig");
const rnd = @import("../render/renderer.zig");
const tex = @import("../assets/texture.zig");

/// The box object drawn to the screen
pub const ScreenBox = struct {
    id: u32 = 0,
    mesh_id: usize = 0,
    contents: []const u8 = undefined,
    layer: f32 = 0,
    bounds: tpe.Float4 = .{},
    color: tpe.Float4 = .{},
    pub fn drawBox(self: ScreenBox) void {
        const mesh: *msh.Mesh = msh.meshes.peek(self.mesh_id);
        const material: *mat.Material = mat.materials.peek(mesh.material_index);
        //const texture: *tex.Texture = tex.peek(material.texture_index);
        const shader: *shd.Shader = shd.shaders.peek(material.shader_index);

        zgl.useProgram(shader.program);
        _ = rnd.checkGLErrorState("Use Program");

        zgl.bindVertexArray(mesh.vao);
        _ = rnd.checkGLErrorState("Bind VAO");

        zgl.uniform1f(shader.bse_name, self.layer);
        _ = rnd.checkGLErrorState("Base Uniform");

        zgl.uniform4fv(shader.bnd_name, 1, @ptrCast(&self.bounds));
        _ = rnd.checkGLErrorState("Bounds Uniform");

        //zgl.uniform1i(shader.t0i_name, @as(c_int, @intCast(texture.index)));
        //zgl.uniform1i(shader.t0o_name, @as(c_int, @intCast(texture.offset)));

        zgl.uniform4fv(shader.cra_name, 1, @ptrCast(&self.color));

        zgl.drawElements(0, 1, zgl.UNSIGNED_INT, null);
        _ = rnd.checkGLErrorState("Draw Elements");

        zgl.uniform1f(shader.bse_name, self.layer - 0.1);
        _ = rnd.checkGLErrorState("Char Base Uniform");

        const l_c = tpe.Point4{};
        zgl.uniform4fv(shader.cra_name, 1, @ptrCast(&l_c));
        _ = rnd.checkGLErrorState("Char Base Uniform");

        //TODO set based on window bounds
        const l = tpe.Float2{ .x = 0.1, .y = 0.1 };

        // need axiliary positioning for wrapping of text
        for (self.contents, 0..) |c, i| {
            // get uv off character position
            // coords are 0.0-1.0 relational
            // charmap is 16*16 px
            const d: f32 = 1.0 / 16.0;
            const u: f32 = @as(f32, @floatFromInt(c % 16)) * d;
            const v: f32 = 1.0 - @as(f32, @floatFromInt(c / 16)) * d;
            zgl.uniform4f(shader.ind_name, u, v, u + d, v + d);
            _ = rnd.checkGLErrorState("Char UV Uniform");

            const x = self.bounds.w + l.x * @as(f32, @floatFromInt(i + 1));
            const y = self.bounds.x + l.y;

            const bounds = tpe.Float4{
                .w = x,
                .x = y,
                .y = l.x,
                .z = l.y,
            };
            zgl.uniform4fv(shader.bnd_name, 1, @ptrCast(&bounds));
            _ = rnd.checkGLErrorState("Char Bounds Uniform");

            zgl.drawElements(0, 1, zgl.UNSIGNED_INT, null);
            _ = rnd.checkGLErrorState("Char Draw Elements");
        }
    }
};

var screenboxes = asc.AssetCollection(ScreenBox, createBox, removeBox){};

pub fn init() !void {
    screenboxes.init(sys.allocator);
}

pub fn deinit() void {
    screenboxes.deinit();
}

fn createBox(asset_id: u32) ScreenBox {
    return ScreenBox{
        .id = asset_id,
        .contents = "mmm, box",
        .bounds = .{ .w = -0.5, .x = -0.5, .y = 1.0, .z = 1.0 },
        .color = .{ 0.5, 0.5, 0.5, 1.0 },
        .mesh_id = msh.meshes.fetch(asset_id),
    };
}

fn removeBox(screen_box: *ScreenBox) void {
    msh.meshes.release(screen_box.id);
}
