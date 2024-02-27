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
const wnd = @import("../types/window.zig");

/// The box object drawn to the screen
pub const ScreenBox = struct {
    id: u32 = 255,
    mesh_id: usize = 0,
    contents: []const u8 = undefined,
    layer: f32 = 0.5,
    bounds: tpe.Float4 = .{},
    color: tpe.Float4 = .{},
    button: ?*const fn () void = null,
    sub_box: ?[]ScreenBox = null,
    pub fn drawBox(self: ScreenBox, window: wnd.Window) void {
        const mesh: *msh.Mesh = msh.meshes.peek(self.mesh_id);
        const material: *mat.Material = mat.materials.peek(mesh.material_index);
        const texture: *tex.Texture = tex.peek(material.texture_index);
        const shader: *shd.Shader = shd.shaders.peek(material.shader_index);

        zgl.useProgram(shader.program);
        _ = rnd.checkGLErrorState("Use Program");

        zgl.bindVertexArray(mesh.vao);
        _ = rnd.checkGLErrorState("Bind VAO");

        //zgl.activeTexture(zgl.TEXTURE0 + @as(c_uint, @intCast(texture.index & 255)));
        zgl.bindTexture(zgl.TEXTURE_2D, texture.name);
        zgl.uniform4f(shader.ind_name, 0, 0, 0, 0);
        _ = rnd.checkGLErrorState("Char UV Uniform");

        zgl.uniform1f(shader.bse_name, self.layer);
        _ = rnd.checkGLErrorState("Base Uniform");

        zgl.uniform4fv(shader.bnd_name, 1, @ptrCast(&self.bounds));
        _ = rnd.checkGLErrorState("Bounds Uniform");

        zgl.uniform1i(shader.t0i_name, @as(c_int, @intCast(texture.index)));
        zgl.uniform1i(shader.t0o_name, @as(c_int, @intCast(texture.offset)));

        const m_rel = window.mouse.rel_position;
        var color = self.color;
        if (self.button != null) {
            if (m_rel.x > self.bounds.w and m_rel.x < self.bounds.w + self.bounds.y and
                m_rel.y > self.bounds.x and m_rel.y < self.bounds.x + self.bounds.z)
            {
                if (window.mouse.button_state[0] == .stay)
                    color = .{ .w = color.w * 1.5, .x = color.x * 1.5, .y = color.y * 1.5, .z = 1.0 }
                else
                    color = .{ .w = color.w * 2, .x = color.x * 2, .y = color.y * 2, .z = 1.0 };
                if (window.mouse.button_state[0] == .left)
                    self.button.?();
            }
        }

        zgl.uniform4fv(shader.cra_name, 1, @ptrCast(&color));

        zgl.drawElements(0, 1, zgl.UNSIGNED_INT, null);
        _ = rnd.checkGLErrorState("Draw Elements");

        zgl.uniform1f(shader.bse_name, self.layer - 0.1);
        _ = rnd.checkGLErrorState("Char Base Uniform");

        const l_c = tpe.Point4{ .w = 1.0, .x = 1.0, .y = 1.0, .z = 1.0 };
        zgl.uniform4fv(shader.cra_name, 1, @ptrCast(&l_c));
        _ = rnd.checkGLErrorState("Char Base Uniform");

        // ratio set by window bounds, and a predetermined size for
        const ratio = @as(f32, @floatFromInt(window.bounds.y)) / @as(f32, @floatFromInt(window.bounds.z));
        const scale: f32 = 0.05;
        const shape = tpe.Float2{ .x = scale, .y = ratio * scale };

        // split contents apart based on whitespace characters
        //TODO catch newline for basic formatting
        var spliterator = std.mem.splitAny(u8, self.contents, "\n ");
        var x: usize = 0;
        var y: usize = 0;
        const abs_width_units = @as(u32, @intFromFloat(@ceil(self.bounds.y / shape.x)));

        while (spliterator.next()) |word| {
            var w_adj: f32 = 1.0;
            if (word.len + x > abs_width_units) {
                if (x > 0) {
                    x = 0;
                    y += 1;
                }
                // get the adjusted width of oversized words
                if (word.len > abs_width_units) {
                    w_adj = self.bounds.y / @as(f32, @floatFromInt(word.len));
                    w_adj /= scale;
                }
                if (self.bounds.z < scale * w_adj) {
                    w_adj = self.bounds.z / scale;
                }
            }

            // need axiliary positioning for wrapping of text
            for (word) |c| {
                // get uv off character position
                // coords are 0.0-1.0 relational
                // charmap is 16*16 px
                const d: f32 = 1.0 / 16.0;
                const u: f32 = @as(f32, @floatFromInt(@mod(c, 16))) * d;
                const v: f32 = 1.0 - @as(f32, @floatFromInt(@divTrunc(c, 16) + 1)) * d;

                // pass character UVs to shader
                zgl.uniform4f(shader.ind_name, u, v, u + d, v + d);
                _ = rnd.checkGLErrorState("Char UV Uniform");

                // calculate screenspace coords
                const bounds = tpe.Float4{
                    // x
                    .w = self.bounds.w + @as(f32, @floatFromInt(x)) * scale * w_adj,
                    // y
                    .x = self.bounds.z + self.bounds.x - @as(f32, @floatFromInt(1 + y)) * scale * ratio,
                    // width
                    .y = shape.x * w_adj,
                    // height
                    .z = shape.y * w_adj,
                };
                zgl.uniform4fv(shader.bnd_name, 1, @ptrCast(&bounds));
                _ = rnd.checkGLErrorState("Char Bounds Uniform");

                zgl.drawElements(0, 1, zgl.UNSIGNED_INT, null);
                _ = rnd.checkGLErrorState("Char Draw Elements");
                x += 1;
            }

            if (x < abs_width_units) {
                x += 1;
            } else {
                x = 0;
                y += 1;
            }
        }

        if (self.sub_box) |sub|
            for (sub) |box|
                box.drawBox(window);
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
