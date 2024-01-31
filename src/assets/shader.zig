const std = @import("std");
const zgl = @import("zopengl");
const asc = @import("../assets/assetcollection.zig");
const sys = @import("../systems/system.zig");
const rnd = @import("../render/renderer.zig");

pub const Shader = struct {
    id: u32 = 0,
    subscribers: u32 = 0,

    program: u32 = 0,
    tex_name: u8 = 0,
    tex_index: u8 = 0,

    mtx_name: i32 = -1, // "matrix"
    mdl_name: i32 = -1, // "model"
    vpm_name: i32 = -1, // "viewproj"
    pst_name: i32 = -1, // "position"
    cam_name: i32 = -1, // "camera"
    rot_name: i32 = -1, // "rotation"
    bnd_name: i32 = -1, // "bounds"
    ind_name: i32 = -1, // "index"
    str_name: i32 = -1, // "stride"
    bse_name: i32 = -1, // "base"
    ran_name: i32 = -1, // "range"
    sun_name: i32 = -1, // "sun"
    aml_name: i32 = -1, // "ambientLuminance"
    amc_name: i32 = -1, // "ambientChroma"
    cra_name: i32 = -1, // "colorA"
    crb_name: i32 = -1, // "colorB"
    t0i_name: i32 = -1, // "tex0Index"
    t0o_name: i32 = -1, // "tex0Offset"

};

pub var shaders = asc.AssetCollection(Shader, createShader, destroyShader){};

fn loadShaderModule(shader_source: [:0]const u8, program: u32, module_type: u32) u32 {
    const module: u32 = zgl.createShader(module_type);
    zgl.shaderSource(module, 1, @as([*c]const [*c]const u8, &@as([*c]const u8, shader_source)), null);
    zgl.compileShader(module);
    zgl.attachShader(program, module);

    _ = rnd.checkGLErrorState("Module Processing");
    _ = checkShaderError(module, zgl.COMPILE_STATUS, zgl.getShaderiv, zgl.getShaderInfoLog);

    return module;
}

pub fn checkShaderError(
    module: u32,
    status: u32,
    getIV: *const fn (c_uint, c_uint, [*c]c_int) callconv(.C) void,
    getIL: *const fn (c_uint, c_int, [*c]c_int, [*c]u8) callconv(.C) void,
) bool {
    var is_error = false;
    var result: i32 = 0;
    var length: i32 = 0;
    var info_log: []u8 = undefined;

    getIV(module, status, &result);
    getIV(module, zgl.INFO_LOG_LENGTH, &length);

    if (length > 0) {
        is_error = true;
        info_log = sys.allocator.alloc(u8, @intCast(length + 1)) catch |err| {
            std.log.err("Shader module compilation failed with error, could not retrieve error: {}", .{err});
            return is_error;
        };
        defer sys.allocator.free(info_log);
        getIL(module, length, null, @as([*c]u8, @ptrCast(&info_log[0])));
        std.log.err("Shader compilation failure: {s}", .{info_log});
    }

    return is_error;
}

fn createShader(shader_id: u32) Shader {
    var shader = Shader{ .id = shader_id };
    const program = zgl.createProgram();
    // early returns should results in an undesirable but graceful

    // assignments should be the id-specific onboards
    // identified as seperate files or filepacks
    const v_shader: [:0]const u8 = switch (shader_id) {
        1 => sky_v_shader,
        255 => box_v_shader,
        else => cube_v_shader,
    };
    const g_shader: [:0]const u8 = switch (shader_id) {
        1 => sky_g_shader,
        255 => box_g_shader,
        else => cube_g_shader,
    };
    const f_shader: [:0]const u8 = switch (shader_id) {
        1 => sky_f_shader,
        255 => box_f_shader,
        else => cube_f_shader,
    };

    // Load and compile shader modules from a provided source. Sources will need to be generally retrieved.
    const vert_module = loadShaderModule(v_shader, program, zgl.VERTEX_SHADER);
    defer zgl.deleteShader(vert_module);
    std.log.info("Compiled Vertex Shader: {}", .{vert_module});
    const geom_module = loadShaderModule(g_shader, program, zgl.GEOMETRY_SHADER);
    defer zgl.deleteShader(geom_module);
    std.log.info("Compiled Geometry Shader: {}", .{geom_module});
    const frag_module = loadShaderModule(f_shader, program, zgl.FRAGMENT_SHADER);
    defer zgl.deleteShader(frag_module);
    std.log.info("Compiled Fragment Shader: {}", .{frag_module});

    // Link shader program.
    zgl.linkProgram(program);
    _ = rnd.checkGLErrorState("Link Program");

    if (checkShaderError(program, zgl.LINK_STATUS, zgl.getProgramiv, zgl.getProgramInfoLog))
        return shader;
    std.log.info("Linked Shader Program: {}", .{program});

    shader.program = program;

    // if all went well, assign program to returned struct and grap shader uniforms
    zgl.useProgram(shader.program);
    _ = rnd.checkGLErrorState("Use Shader");

    shader.mtx_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("matrix\x00")));
    shader.mdl_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("model\x00")));
    shader.vpm_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("viewproj\x00")));
    shader.cam_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("camera\x00")));
    shader.rot_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("rotation\x00")));
    shader.pst_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("position\x00")));
    shader.bnd_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("bounds\x00")));
    shader.ind_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("index\x00")));
    shader.str_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("stride\x00")));
    shader.bse_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("base\x00")));
    shader.ran_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("range\x00")));
    shader.sun_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("sun\x00")));
    shader.aml_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("ambientLuminance\x00")));
    shader.amc_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("ambientChroma\x00")));
    shader.cra_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("colorA\x00")));
    shader.crb_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("colorB\x00")));
    shader.t0i_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("tex0Index")));
    shader.t0o_name = zgl.getUniformLocation(shader.program, @as([*c]const u8, @ptrCast("tex0Offset")));

    //if (shader.mtx_name > -1) std.debug.print("shader.mtx_name: {}\n", .{shader.mtx_name});

    shader.subscribers = 1;
    return shader;
}

fn destroyShader(shader: *Shader) void {
    //delet program?
    _ = shader;
}

// TODO account for scale/stride based on *neighbor* scales, not face scales
// for now?
const cube_f_shader =
    \\///CUBE FRAGMENT SHADER
    \\#version 330 core
    \\
    \\out vec4 outColor;
    \\in vec3 fragNormal;
    \\in float fragU;
    \\flat in float fragScaleX;
    \\in float fragV;
    \\flat in float fragScaleY;
    \\
    \\uniform vec4 colorA;
    \\uniform vec4 colorB;
    \\uniform vec3 rotation;
    \\uniform vec4 sun;
    \\
    \\float edge = 0.2f;
    \\
    \\void main()
    \\{
    \\  outColor = 
    \\      ((abs(fragU) > (fragScaleX - edge) || abs(fragV) > (fragScaleY - edge)) ? colorB : colorA) + 
    \\          max(0.0, dot(rotation, fragNormal)) * sun * 0.1f; 
    \\}
;

const cube_g_shader =
    \\///CUBE GEOMETRY SHADER
    \\#version 330 core
    \\
    \\layout(points) in; 
    \\layout(triangle_strip, max_vertices = 72) out; 
    \\
    \\out vec3 fragNormal;
    \\out float fragU;
    \\flat out float fragScaleX;
    \\out float fragV;
    \\flat out float fragScaleY;
    \\
    \\uniform mat4 matrix; 
    \\uniform vec3 stride; //matches scale on cube
    \\
    \\vec3 verts[8] = vec3[]( 
    \\	vec3(-0.5f, -0.5f, -0.5f), vec3(0.5f, -0.5f, -0.5f), 
    \\	vec3(-0.5f, -0.5f, 0.5f), vec3(0.5f, -0.5f, 0.5f), 
    \\	vec3(0.5f, 0.5f, -0.5f), vec3(-0.5f, 0.5f, -0.5f), 
    \\	vec3(0.5f, 0.5f, 0.5f), vec3(-0.5f, 0.5f, 0.5f)
    \\); 
    \\
    \\void BuildFace(int fir, int sec, int thr, int frt, vec3 normal, vec2 scale)
    \\{ 
    \\	gl_Position = matrix * vec4(verts[fir], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy ;
    \\  fragU = -scale.x;
    \\  fragV = scale.y;
    \\  fragScaleX = scale.x;	
    \\  fragScaleY = scale.y;	
    \\  EmitVertex(); 
    \\	gl_Position = matrix * vec4(verts[sec], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy;
    \\  fragU = scale.x;
    \\  fragV = -scale.y;
    \\  fragScaleX = scale.x;	
    \\  fragScaleY = scale.y;
    \\	EmitVertex(); 
    \\	gl_Position = matrix * vec4(verts[thr], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy;
    \\  fragU = scale.x;
    \\  fragV = scale.y;
    \\  fragScaleX = scale.x;	
    \\  fragScaleY = scale.y;
    \\	EmitVertex(); 
    \\	EndPrimitive();
    \\	 
    \\	gl_Position = matrix * vec4(verts[fir], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy;
    \\  fragU = scale.x;
    \\  fragV = -scale.y;
    \\  fragScaleX = scale.x;	
    \\  fragScaleY = scale.y;
    \\	EmitVertex(); 
    \\	gl_Position = matrix * vec4(verts[frt], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy;
    \\  fragU = scale.x;
    \\  fragV = scale.y;
    \\  fragScaleX = scale.x;	
    \\  fragScaleY = scale.y;  
    \\  EmitVertex(); 
    \\	gl_Position = matrix * vec4(verts[sec], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy;
    \\  fragU = -scale.x;
    \\  fragV = scale.y;
    \\  fragScaleX = scale.x;	
    \\  fragScaleY = scale.y;
    \\	EmitVertex(); 
    \\	EndPrimitive(); 
    \\} 
    \\
    \\void main()
    \\{ 
    \\  //draw inside
    \\  BuildFace(3, 0, 2, 1, vec3(0.0f, 1.0f, 0.0f),  stride.zx);
    \\	BuildFace(2, 5, 7, 0, vec3(1.0f, 0.0f, 0.0f),  stride.zy); 
    \\	BuildFace(6, 1, 3, 4, vec3(-1.0f, 0.0f, 0.0f), stride.yz);
    \\	BuildFace(6, 2, 7, 3, vec3(0.0f, 0.0f, -1.0f), stride.yx); 
    \\	BuildFace(1, 5, 0, 4, vec3(0.0f, 0.0f, 1.0f),  stride.yx);
    \\	BuildFace(7, 4, 6, 5, vec3(0.0f, -1.0f, 0.0f), stride.xz);
    \\  
    \\  //draw outside
    \\	BuildFace(0, 3, 2, 1, vec3(0.0f, 1.0f, 0.0f),  stride.zx);
    \\	BuildFace(5, 2, 7, 0, vec3(1.0f, 0.0f, 0.0f),  stride.zy); 
    \\	BuildFace(1, 6, 3, 4, vec3(-1.0f, 0.0f, 0.0f), stride.zy);
    \\	BuildFace(2, 6, 7, 3, vec3(0.0f, 0.0f, -1.0f), stride.yx); 
    \\	BuildFace(5, 1, 0, 4, vec3(0.0f, 0.0f, 1.0f),  stride.yx);
    \\	BuildFace(4, 7, 6, 5, vec3(0.0f, -1.0f, 0.0f), stride.xz);
    \\}
;

const cube_v_shader =
    \\//CUBE VERTEX SHADER
    \\#version 330 core
    \\
    \\void main() 
    \\{
    \\
    \\}
;

const sky_f_shader =
    \\//SKY FRAGMENT SHADER
    \\#version 330 core
    \\
    \\uniform vec4 base;
    \\out vec4 sun_color;
    \\
    \\void main() 
    \\{
    \\  sun_color = base;
    \\}
;

const sky_g_shader =
    \\//SKY GEOMETRY
    \\#version 330 core
    \\
    \\layout(points) in; 
    \\layout(triangle_strip, max_vertices = 6) out; 
    \\
    \\float z_index = 0.99999f;
    \\
    \\void main()
    \\{
    \\  gl_Position = vec4(-1.0f, -1.0f, z_index, 1.0f);
    \\  EmitVertex(); 
    \\  gl_Position = vec4(1.0f, -1.0f, z_index, 1.0f);
    \\  EmitVertex(); 
    \\  gl_Position = vec4(1.0f, 1.0f, z_index, 1.0f);
    \\  EmitVertex(); 
    \\	EndPrimitive();
    \\
    \\  gl_Position = vec4(-1.0f, -1.0f, z_index, 1.0f);
    \\  EmitVertex(); 
    \\  gl_Position = vec4(1.0f, 1.0f, z_index, 1.0f);
    \\  EmitVertex(); 
    \\  gl_Position = vec4(-1.0f, 1.0f, z_index, 1.0f);
    \\  EmitVertex(); 
    \\	EndPrimitive();
    \\}
    \\
;

const sky_v_shader =
    \\//SKY VERTEX SHADER
    \\#version 330 core
    \\
    \\void main() 
    \\{
    \\
    \\}
;

const box_f_shader =
    \\//BOX FRAGMENT SHADER
    \\#version 330 core
    \\
    \\uniform sampler2D tex0Index;
    \\uniform int tex0Offset;
    \\uniform vec4 colorA;
    \\uniform vec4 colorB;
    \\
    \\in vec2 frag_uv;
    \\
    \\out vec4 frag_color;
    \\
    \\void main(){
    \\  frag_color = colorA + texture(tex0Index, frag_uv);
    \\}
;

const box_g_shader =
    \\//BOX GEOMETRY SHADER
    \\#version 330 core
    \\
    \\layout(points) in; 
    \\layout(triangle_strip, max_vertices = 6) out; 
    \\
    \\//xywh
    \\//vvvv
    \\//wxyz
    \\
    \\//xyzw?wxyz?
    \\
    \\uniform vec4 bounds; //box extents in screen-space coords
    \\uniform float base; //layer
    \\uniform vec4 index; //box uvs
    \\
    \\out vec2 frag_uv;
    \\
    \\void main() 
    \\{
    \\  gl_Position = vec4(bounds.xy, base, 1.0f);
    \\  frag_uv = index.xy;
    \\  EmitVertex(); 
    \\  gl_Position = vec4(bounds.x + bounds.z, bounds.y, base, 1.0f);
    \\  frag_uv = index.zy;
    \\  EmitVertex(); 
    \\  gl_Position = vec4(bounds.x + bounds.z, bounds.y + bounds.w, base, 1.0f);
    \\  frag_uv = index.zw;
    \\  EmitVertex(); 
    \\	EndPrimitive();
    \\
    \\  gl_Position = vec4(bounds.xy, base, 1.0f);
    \\  frag_uv = index.xy;
    \\  EmitVertex(); 
    \\  gl_Position = vec4(bounds.x + bounds.z, bounds.y + bounds.w, base, 1.0f);
    \\  frag_uv = index.zw;
    \\  EmitVertex(); 
    \\  gl_Position = vec4(bounds.x, bounds.y + bounds.w, base, 1.0f);
    \\  frag_uv = index.xw;
    \\  EmitVertex(); 
    \\	EndPrimitive();
    \\}
;

const box_v_shader =
    \\//BOX VERTEX SHADER
    \\#version 330 core
    \\
    \\void main(){}
;
