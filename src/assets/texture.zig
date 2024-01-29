const std = @import("std");
const zgl = @import("zopengl");
const sys = @import("../systems/system.zig");
const gls = @import("../systems/glsystem.zig");
const asc = @import("../assets/assetcollection.zig");
const tpe = @import("../types/types.zig");
const fio = @import("../systems/fileio.zig");
const rnd = @import("../render/renderer.zig");

/// Texture metadata to align with relevant GPU data
pub const Texture = struct {
    id: u32 = 0,
    subscribers: u32 = 0,
    /// The hosted binding point
    index: u32 = 0,
    /// The hosted index in the bound point
    offset: i32 = 0,
    /// size of texture
    size: tpe.Point2 = .{},
    /// GL format of texture data
    format: gls.GLFmtType = 0,
    /// GL superset of format
    format_set: gls.GLFmtSet = 0,
    /// GL type for each texel
    gl_type: gls.GLType = 0,
    /// GL texture object name
    name: gls.GLTexName = 0,
};

/// Stack sub-collection to represent GPU texture memory layout
const Column = struct {
    /// GL name
    name: gls.GLTexName = 0,
    /// dimensions
    size: tpe.Point2 = .{},
    /// Compression/Pixel type
    format: gls.GLFmtType = 0,
    /// How many texture arrray slots are in use
    count: usize = 0,
    /// The Textures within the column
    textures: []Texture = undefined,
};

/// The texture stack object
const Stack = struct {
    /// Columns for storing texture metadata
    textures: []Texture = undefined,
    /// Persistant allocator
    allocator: std.mem.Allocator = undefined,
};

/// Options for initializing the texture stack
pub const StackOptions = struct {
    /// Initial Column size for texture metadata
    initial_size: usize = 4,
};

/// should not be accessed directly from outside, it's comfier in here
var stack: Stack = .{};

///Initialize the Stack
///Fills with columns equal to the texture bind points available from the hardware
/// allocator: Persistant Allocator Type
///
pub fn init(allocator: std.mem.Allocator, stack_options: StackOptions) !void {
    _ = stack_options;
    stack.allocator = allocator;
    stack.textures = try stack.allocator.alloc(Texture, @intCast(gls.max_tex_binding_points));
    for (stack.textures, 0..) |*texture, i| {
        texture.* = Texture{ .index = @intCast(i) };
    }
}

pub fn deinit() void {
    for (stack.textures) |*texture| {
        zgl.deleteTextures(1, &texture.name);
    }
    stack.allocator.free(stack.textures);
}

/// Generates a single usize for texture indexing
inline fn stackIndex(column_index: usize, texture_index: usize) usize {
    return ((texture_index << 8) + column_index);
}

/// Returns the index of a texture matching the provided index
/// Will generate and place texture if none exists
pub fn fetch(texture_id: u32) !usize {
    // first check if Texture is already loaded
    for (stack.textures, 0..) |texture, i| {
        if (texture.subscribers > 0)
            if (texture.id == texture_id) {
                return i;
            };
    }

    return try createTexture(texture_id);
}

/// Releases use of texture
pub fn release(texture_id: u32) void {
    for (stack.textures) |texture|
        if (texture.id == texture_id) {
            if (texture.subscribers > 0) {
                texture.subscribers -= 1;
            } else {
                std.log.warn(
                    "Texture {} released more than subscribed",
                    .{texture_id},
                );
            }
        };
}

pub fn peek(texture_index: usize) *Texture {
    return &stack.columns[texture_index & 255].textures[texture_index >> 8];
}

inline fn getTexFileName(texture_id: u32) []const u8 {
    return switch (texture_id) {
        255 => "./_assets/spritesheet.bmp",
        else => "./_assets/test.bmp",
    };
}

/// Converts a supplied bitmap into a supplied Texture
/// Converts to a supplied GL pixel format
pub fn bitmapToTexture(bmp: fio.Bitmap, gl_fmt: gls.GLFmtSet, allocator: std.mem.Allocator) ![]u8 {
    const px_size = (bmp.bpp / 8);
    const tx_count = bmp.size / px_size;
    const tx_size: u32 = switch (gl_fmt) {
        //
        zgl.RGB5_A1 => 2,
        //
        zgl.RGB10_A2 => 4,
        // fall through to => RGBA8
        else => 4,
    };

    var texels = try allocator.alloc(u8, tx_count * tx_size);
    for (0..tx_count) |p| {
        const i = p * px_size;
        switch (gl_fmt) {
            //A8R8G8B8 to GL_RGB5_A1
            zgl.RGB5_A1 => {
                const tx: u16 =
                    ((@as(u16, @intCast(bmp.pixel_data[i + 1] >> 3))) << (11)) +
                    ((@as(u16, @intCast(bmp.pixel_data[i + 2] >> 3))) << (6)) +
                    ((@as(u16, @intCast(bmp.pixel_data[i + 3] >> 3))) << (1)) +
                    (@as(u16, @intCast(bmp.pixel_data[i] / 128)));
                if (bmp.pixel_data[i + 1] == 255)
                    std.debug.print("[{},{},{},{}] = {}\n", .{
                        bmp.pixel_data[i + 1],
                        bmp.pixel_data[i + 2],
                        bmp.pixel_data[i + 3],
                        bmp.pixel_data[i],
                        tx,
                    });
                texels[p * tx_size] = @as(u8, @intCast(tx >> 8));
                texels[p * tx_size + 1] = @as(u8, @intCast(tx & 255));
            },
            //A8R8G8B8 to GL_RGB10_A2
            zgl.RGB10_A2 => {
                const tx: u32 =
                    (@as(u32, @intCast(bmp.pixel_data[i + 1] * 4)) << (22)) +
                    (@as(u32, @intCast(bmp.pixel_data[i + 2] * 4)) << (12)) +
                    (@as(u32, @intCast(bmp.pixel_data[i + 3] * 4)) << (2)) +
                    ((bmp.pixel_data[i] / 64));
                texels[p * tx_size] = @as(u8, @intCast(tx >> 24));
                texels[p * tx_size + 1] = @as(u8, @intCast(tx >> 16));
                texels[p * tx_size + 2] = @as(u8, @intCast(tx >> 8));
                texels[p * tx_size + 3] = @as(u8, @intCast(tx));
            },
            // fall through to RGBA8
            else => {
                texels[p * tx_size] = bmp.pixel_data[i + 1];
                texels[p * tx_size + 1] = bmp.pixel_data[i + 2];
                texels[p * tx_size + 2] = bmp.pixel_data[i + 3];
                texels[p * tx_size + 3] = bmp.pixel_data[i];
            },
        }
    }

    return texels;
}

/// Create and emplace a new Texture both in stack and GPU
/// Matching up representative position
fn createTexture(texture_id: u32) !usize {
    var tex = Texture{ .id = texture_id };

    // generate texture object, with bounds as part of the data
    const file_buffer = try fio.readFileAlloc(getTexFileName(texture_id), sys.allocator, 1 << 20);
    defer sys.allocator.free(file_buffer);

    const bitmap = try fio.bitmapFromFile(file_buffer, sys.allocator);
    defer sys.allocator.free(bitmap.pixel_data);

    tex.format = switch (texture_id) {
        //255 => zgl.RGB5_A1,
        else => zgl.RGBA8,
    };
    tex.format_set = switch (texture_id) {
        255 => zgl.RGBA,
        else => zgl.RGBA,
    };
    tex.gl_type = switch (texture_id) {
        //255 => zgl.UNSIGNED_SHORT_5_5_5_1,
        else => zgl.UNSIGNED_INT,
    };

    const texels = try bitmapToTexture(bitmap, tex.format, sys.allocator);
    defer sys.allocator.free(texels);

    // then find appropriate position
    const texture_index = try getPositionIndex(tex);

    tex.subscribers = 1;
    tex.size = tpe.Point2{
        .x = @intCast(bitmap.width),
        .y = @intCast(bitmap.height),
    };
    tex.index = @intCast(texture_index & 255);
    tex.offset = @intCast(texture_index >> 8);

    zgl.activeTexture(zgl.TEXTURE0 + @as(c_uint, @intCast(texture_index & 255)));

    zgl.bindTexture(zgl.TEXTURE_2D, stack.columns[texture_index & 255].name);

    zgl.texImage2D(
        zgl.TEXTURE_2D,
        0,
        zgl.RGBA8,
        256,
        256,
        0,
        zgl.RGBA,
        zgl.UNSIGNED_INT,
        texels,
    );

    std.debug.print("Got Here!\n", .{});

    _ = rnd.checkGLErrorState("Tex Subimage2D");

    stack.columns[texture_index & 255].count += 1;

    // then jam it in
    stack.textures[texture_index] = tex;
    // then return labelled position
    return texture_index;
}

fn destroyTexture(texture: *Texture) void {
    _ = texture;
}

fn getPositionIndex(tex: Texture) !usize {
    _ = tex;
    // firstly, check if any openings exist
    for (stack.textures, 0..) |*texture, i| {
        if (texture.subscribers < 1)
            // if so, grab index and break
            return i;
    }
    return 0;
}
