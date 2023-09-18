const std = @import("std");
const zdl = @import("zsdl");
const zgl = @import("zopengl");
const zmt = @import("zmath");
const csm = @import("../systems/csmath.zig");
const tpe = @import("../types/types.zig");
const wnd = @import("../types/window.zig");
const sys = @import("../systems/system.zig");
const lvl = @import("../types/level.zig");
const msh = @import("../assets/mesh.zig");
const mat = @import("../assets/material.zig");
const shd = @import("../assets/shader.zig");
const cbe = @import("../objects/cube.zig");

/// The Rendering Function
pub fn render() !void {

    // for all windows (just one)
    for (wnd.windows.items) |*w| {
        try zdl.gl.makeCurrent(w.sdl_window, w.gl_context);

        // get and set viewport from window bounds (to fix resizing issues)
        zdl.Window.getSize(w.sdl_window, &w.size.x, &w.size.y) catch unreachable;
        // clear
        zgl.clear(zgl.COLOR_BUFFER_BIT | zgl.DEPTH_BUFFER_BIT);
        zgl.viewport(0, 0, w.size.x, w.size.y);
        // calc camera matrices
        w.camera.calculateMatrices(w);
        //draw the sky
        {
            const sky_mesh: *msh.Mesh = msh.meshes.peek(skymesh);
            const sky_material: *mat.Material = mat.materials.peek(sky_mesh.material_index);
            const sky_shader: *shd.Shader = shd.shaders.peek(sky_material.shader_index);

            zgl.useProgram(sky_shader.program);
            if (checkGLErrorState("Use Program")) std.debug.print("Program Name:{d}\n", .{sky_shader.program});

            //bind mesh
            zgl.bindVertexArray(sky_mesh.vao);
            if (checkGLErrorState("Bind Vertex Array")) std.debug.print("VAO Address:{d}\n", .{sky_mesh.vao});

            zgl.uniform3fv(sky_shader.bse_name, 1, &lvl.active_level.sky_color.toArray());
            if (checkGLErrorState("Sky Sun Uniform Assignment")) std.debug.print("Uniform Address:{d} for program {d}\n", .{ sky_shader.bse_name, sky_shader.program });

            //draw
            zgl.drawElements(0, 1, zgl.UNSIGNED_INT, null);
            _ = checkGLErrorState("Draw Elements");
        }
        // for each cube
        for (lvl.active_level.cubes.items) |cube| {
            const mesh: *msh.Mesh = msh.meshes.peek(cube.mesh_index);
            const material: *mat.Material = mat.materials.peek(mesh.material_index);
            const shader: *shd.Shader = shd.shaders.peek(material.shader_index);
            const axial = cube.euclid.position.getAxial();
            const model =
                zmt.mul(
                zmt.mul(
                    zmt.scaling(cube.euclid.scale.x, cube.euclid.scale.y, cube.euclid.scale.z),
                    zmt.matFromQuat(cube.euclid.rotation),
                ),
                zmt.translation(axial.x, axial.y, axial.z),
            );

            const mvp = zmt.mul(model, w.camera.vp_matrix);

            zgl.useProgram(shader.program);
            if (checkGLErrorState("Use Program")) std.debug.print("Program Name:{d}\n", .{shader.program});

            //bind mesh
            zgl.bindVertexArray(mesh.vao);
            if (checkGLErrorState("Bind Vertex Array")) std.debug.print("VAO Address:{d}\n", .{mesh.vao});

            //assign matrix
            zgl.uniformMatrix4fv(shader.mtx_name, 1, zgl.FALSE, &mvp[0][0]);
            if (checkGLErrorState("MVP Matrix Uniform Assignment")) std.debug.print("Uniform Address:{d}\n", .{shader.mtx_name});

            var c = tpe.Float4{};
            c.fromSIMD(cbe.aColors[(cube.cube_data >> 3) & 7]);
            const a_color = c.toArray();
            c.fromSIMD(cbe.bColors[(cube.cube_data >> 3) & 7]);
            const b_color = c.toArray();

            const sun_color: [4]f32 = lvl.active_level.sky_color.toArray();
            const sun_direction: [3]f32 = lvl.active_level.sun_direction.toArray();
            const stride = cube.euclid.scale.toArray();

            zgl.uniform3fv(shader.str_name, 1, &stride);
            if (checkGLErrorState("Stride Uniform Assignment")) std.debug.print("Uniform Address:{d}\n", .{shader.str_name});
            zgl.uniform3fv(shader.rot_name, 1, &sun_direction);
            if (checkGLErrorState("Sun Rotation Uniform Assignment")) std.debug.print("Uniform Address:{d}\n", .{shader.rot_name});
            zgl.uniform4fv(shader.sun_name, 1, &sun_color);
            if (checkGLErrorState("Sun Color Uniform Assignment")) std.debug.print("Uniform Address:{d}\n", .{shader.sun_name});
            zgl.uniform4fv(shader.cra_name, 1, &a_color);
            if (checkGLErrorState("A (center) Color Uniform Assignment")) std.debug.print("Uniform Address:{d}\n", .{shader.cra_name});
            zgl.uniform4fv(shader.crb_name, 1, &b_color);
            if (checkGLErrorState("B (edge) Color Uniform Assignment")) std.debug.print("Uniform Address:{d}\n", .{shader.crb_name});

            //draw
            zgl.drawElements(0, 1, zgl.UNSIGNED_INT, null);
            _ = checkGLErrorState("Draw Elements");
        }

        zdl.gl.swapWindow(w.sdl_window);
    }
}

/// Get Proc Address
pub fn getProcAddress(name: [:0]const u8) ?*const anyopaque {
    // get proc address
    return zdl.gl.getProcAddress(name); // get proc address
}

/// Check if GL has an error, and log if so with the provided descriptor string
/// Also, return a bool, because why not?
pub fn checkGLErrorState(gl_op_description: []const u8) bool {
    var gl_err = zgl.getError();
    if (gl_err > 0) {
        std.log.err("GL drawing on operation: {s}, error: {s}", .{ gl_op_description, getGLErrorString(gl_err) });
        return true;
    }
    return false;
}

//Returns an appropriate GL error string for the error enum value
pub fn getGLErrorString(gl_error_enum_value: u32) []const u8 {
    switch (gl_error_enum_value) {
        0x0500 => {
            return "Inavlid Enum";
        },
        0x0501 => {
            return "Invalid Value";
        },
        0x0502 => {
            return "Invalid Operation";
        },
        0x0503 => {
            return "Stack Overflow";
        },
        0x0504 => {
            return "Stack Underflow";
        },
        0x0505 => {
            return "OOM!";
        },
        0x0506 => {
            return "Invalid Framebuffer Operation";
        },
        0x0507 => {
            return "GL_INVALID_ENUM";
        },
        0x8031 => {
            return "Table Too Large";
        },
        else => {
            return "No associated GL Enum?";
        },
    }
    unreachable;
}

var skymesh: usize = 0;

pub fn initSky() !void {
    skymesh = try msh.meshes.fetch(1);
}

pub fn deinitSky() void {
    msh.meshes.release(1);
}
