const std = @import("std");
const asc = @import("../assets/assetcollection.zig");
const shd = @import("../assets/shader.zig");

pub const Material = struct {
    id: u32 = 0,
    subscribers: u32 = 0,
    shader_index: usize = 0,
};

pub var materials = asc.AssetCollection(Material, addMaterial, remMaterial){};

fn addMaterial(material_id: u32) Material {
    var material = Material{
        .id = material_id,
    };
    material.shader_index = shd.shaders.fetch(0) catch |err|
        {
        std.log.err("Material failed to get shader: {}", .{err});
        return material;
    };
    return material;
}

fn remMaterial(material: *Material) void {
    _ = material;
    shd.shaders.release(0);
}
