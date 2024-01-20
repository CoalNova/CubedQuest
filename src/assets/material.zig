const std = @import("std");
const asc = @import("../assets/assetcollection.zig");
const shd = @import("../assets/shader.zig");
const tex = @import("../assets/texture.zig");

pub const Material = struct {
    id: u32 = 0,
    subscribers: u32 = 0,
    shader_index: usize = 0,
    texture_index: usize = 0,
};

pub var materials = asc.AssetCollection(Material, createMaterial, destroyMaterial){};

fn createMaterial(material_id: u32) Material {
    var material = Material{
        .id = material_id,
        .subscribers = 1,
    };
    material.shader_index = shd.shaders.fetch(material_id) catch |err| {
        std.log.err("Material {} failed to get shader: {!}", .{ material_id, err });
        return material;
    };
    material.texture_index = tex.fetch(material_id) catch |err| {
        std.log.err("Material {} failed to get texture: {!}", .{ material_id, err });
        return material;
    };
    return material;
}

fn destroyMaterial(material: *Material) void {
    const shader = shd.shaders.peek(material.shader_index);
    shd.shaders.release(shader.id);
}
