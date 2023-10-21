const std = @import("std");
const zgl = @import("zopengl");
const asc = @import("../assets/assetcollection.zig");
const mat = @import("../assets/material.zig");
const shd = @import("../assets/shader.zig");
const rnd = @import("../systems/renderer.zig");

pub const Mesh = struct {
    id: u32 = 0,
    subscribers: u32 = 0,
    vao: u32 = 0,
    vbo: u32 = 0,
    ibo: u32 = 0,
    vio: u32 = 0,
    num_elements: i32 = 0,
    material_index: usize = 0,
    drawstyle_enum: u32 = 0,
};

pub var meshes = asc.AssetCollection(Mesh, addMesh, remMesh){};

fn addMesh(mesh_id: u32) Mesh {
    var mesh: Mesh = .{
        .id = mesh_id,
    };
    var material_index = mat.materials.fetch(mesh_id) catch |err| {
        std.log.err("Material fetching errored: {}", .{err});
        return mesh;
    };
    mesh.material_index = material_index;
    const shader = shd.shaders.peek(mat.materials.peek(mesh.material_index).shader_index);
    zgl.useProgram(shader.program);
    _ = rnd.checkGLErrorState("Using GL Program");

    zgl.genVertexArrays(1, &mesh.vao);
    _ = rnd.checkGLErrorState("Generating Fresh VAO");
    zgl.genBuffers(1, &mesh.vbo);
    _ = rnd.checkGLErrorState("Generating Fresh VBO");
    zgl.genBuffers(1, &mesh.ibo);
    _ = rnd.checkGLErrorState("Generating Fresh IBO");

    //TODO not the debug cube
    mesh.drawstyle_enum = zgl.POINTS;
    zgl.bindVertexArray(mesh.vao);
    _ = rnd.checkGLErrorState("Binding VAO");
    zgl.bindBuffer(zgl.ARRAY_BUFFER, mesh.vbo);
    _ = rnd.checkGLErrorState("Binding VBO");
    zgl.bindBuffer(zgl.ELEMENT_ARRAY_BUFFER, mesh.ibo);
    _ = rnd.checkGLErrorState("Binding IBO");

    mesh.num_elements = 1;
    const buff_data: u32 = 1;
    const buff_data_zero: u32 = 0;
    zgl.bufferData(zgl.ARRAY_BUFFER, @sizeOf(u32), &buff_data, zgl.STATIC_DRAW);
    _ = rnd.checkGLErrorState("Buffering Vertex Buffer");
    zgl.bufferData(zgl.ELEMENT_ARRAY_BUFFER, @sizeOf(u32), &buff_data_zero, zgl.STATIC_DRAW);
    _ = rnd.checkGLErrorState("Buffering Element Buffer");
    zgl.vertexAttribPointer(0, @sizeOf(f32), zgl.FLOAT, 0, @sizeOf(f32), null);
    zgl.enableVertexAttribArray(0);
    _ = rnd.checkGLErrorState("Setting Attribute");

    mesh.subscribers = 1;
    return mesh;
}
fn remMesh(mesh: *Mesh) void {
    const material = mat.materials.peek(mesh.material_index);
    mat.materials.release(material.id);
}
