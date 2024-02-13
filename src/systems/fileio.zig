const std = @import("std");
const zgl = @import("zopengl");
const gls = @import("../systems/glsystem.zig");
const tex = @import("../assets/texture.zig");

pub const FOpts = enum { relative, absolute };
pub const FPath = union(FOpts) { relative: []const u8, absolute: []const u8 };

pub const FIOErrors = error{
    /// Incorrect type of file based on header/tailer data
    WrongFileType,
    /// Compression style for file is incorrect
    WrongCompression,
};

/// Opening of file is externalized from functions as to allow for direct access to:
/// A. live generated data
/// B. embedded data
pub fn openFile(path: FPath, op: enum { read, write }) !std.fs.File {
    switch (path) {
        .relative => |p| {
            switch (op) {
                .read => return std.fs.cwd().openFile(
                    p,
                    std.fs.File.OpenFlags{ .mode = .read_only },
                ),
                .write => return std.fs.cwd().openFile(
                    p,
                    std.fs.File.OpenFlags{ .mode = .write_only },
                ),
            }
        },
        .absolute => |p| {
            switch (op) {
                .read => return std.fs.openFileAbsolute(
                    p,
                    std.fs.File.OpenFlags{ .mode = .read_only },
                ),
                .write => return std.fs.openFileAbsolute(
                    p,
                    std.fs.File.OpenFlags{ .mode = .write_only },
                ),
            }
        },
    }
}

pub inline fn readFileAlloc(filename: []const u8, allocator: std.mem.Allocator, max_file_size: usize) ![]u8 {
    const cwd = std.fs.cwd();
    var file = try cwd.openFile(filename, .{});
    defer file.close();
    return file.readToEndAlloc(allocator, max_file_size);
}

pub fn loadDDS(raw_buffer: []u8, texture: *tex.Texture, allocator: std.mem.Allocator) ![]u8 {
    if (!std.mem.eql(u8, "DDS ", raw_buffer[0..4])) {
        std.log.err("Provided data buffer not pf type DDS", .{});
        return FIOErrors.WrongFileType;
    }

    const readInt = std.mem.readInt;

    // generating OS used little endian
    texture.dimensions = .{
        .x = readInt(i32, raw_buffer[8..12], .little),
        .y = readInt(i32, raw_buffer[12..16], .little),
    };
    const tex_size = readInt(u64, raw_buffer[16..24], .little);
    texture.px_b_size = @intCast(@divExact(tex_size, @as(
        u64,
        @intCast(texture.dimensions.x * texture.dimensions.y),
    )));

    if (raw_buffer[80] != 'D') // DXT
    {
        std.log.err("Mismatch of compression type or file corruption.", .{});
        return FIOErrors.WrongCompression;
    }

    texture.tex_format = switch (raw_buffer[83]) {
        '1' => //DXT1
        zgl.COMPRESSED_RGBA_S3TC_DXT1_EXT,
        '3' => //DXT3
        zgl.COMPRESSED_RGBA_S3TC_DXT3_EXT,
        '5' => //DXT5
        zgl.COMPRESSED_RGBA_S3TC_DXT5_EXT,
        else => {
            std.log.err("Incorrect compression type for texture processing", .{});
            return FIOErrors.WrongCompression;
        },
    };

    var tex_buffer = try allocator.alloc(u8, tex_size);
    for (raw_buffer[124..], 0..) |c, i| tex_buffer[c] = i;

    return tex_buffer;
}

///The container for bitmap data
pub const Bitmap = struct {
    ///The size of this header, in bytes (40)
    header_size: u32 = 0,
    ///The bitmap width in pixels (signed integer)
    width: u32 = 0,
    ///The bitmap height in pixels (signed integer)
    height: u32 = 0,
    ///The number of color planes (must be 1)
    color_planes: u16 = 0,
    ///The number of bits per pixel, which is the color depth of the image. Typical values are 1, 4, 8, 16, 24 and 32.
    bpp: u16 = 0,
    ///The compression method being used. See the next table for a list of possible values
    compression: u32 = 0,
    ///The image size. This is the size of the raw bitmap data; a dummy 0 can be given for BI_RGB bitmaps.
    size: u32 = 0,
    ///Image bitmap image raw data
    pixel_data: []u8 = undefined,
};

/// Propagates Bitmap Header and data fields from a raw file as a struct
pub fn bitmapFromFile(raw_buffer: []u8, allocator: std.mem.Allocator) !Bitmap {
    if (!std.mem.eql(u8, raw_buffer[0..2], "BM"))
        return error.InvalidBMPFile;

    const data_start: u32 = std.mem.readInt(u32, raw_buffer[10..14], .little);

    var bmp: Bitmap = .{};
    bmp.header_size = std.mem.readInt(u32, raw_buffer[14..18], .little);
    bmp.width = std.mem.readInt(u32, raw_buffer[18..22], .little);
    bmp.height = std.mem.readInt(u32, raw_buffer[22..26], .little);
    bmp.color_planes = std.mem.readInt(u16, raw_buffer[26..28], .little);
    bmp.bpp = std.mem.readInt(u16, raw_buffer[28..30], .little);
    bmp.compression = std.mem.readInt(u32, raw_buffer[30..34], .little);
    bmp.size = std.mem.readInt(u32, raw_buffer[34..38], .little);

    std.debug.print("{any}\n", .{bmp});
    bmp.pixel_data = try allocator.alloc(u8, bmp.size);
    @memcpy(bmp.pixel_data, raw_buffer[data_start .. data_start + bmp.size]);
    return bmp;
}

pub inline fn saveBuffer(filename: []const u8, buffer: []const u8) !void {
    const cwd = std.fs.cwd();
    var file = try cwd.createFile(filename, .{});
    defer file.close();
    _ = try file.write(buffer);
}
