const std = @import("std");
const zgl = @import("zopengl");
const asc = @import("../assets/assetcollection.zig");
const sys = @import("../systems/system.zig");
const rnd = @import("../systems/renderer.zig");

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

};

pub var shaders = asc.AssetCollection(Shader, addShader, remShader){};

fn loadShaderModule(shader_source: [:0]const u8, program: u32, module_type: u32) u32 {
    var module: u32 = zgl.createShader(module_type);
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

fn addShader(shader_id: u32) Shader {
    var shader = Shader{ .id = shader_id };
    const program = zgl.createProgram();
    //Early returns should results in an undesirable but graceful

    // Load and compile shader modules from a provided source. Sources will need to be generally retrieved.
    const vert_module = loadShaderModule(cube_v_shader, program, zgl.VERTEX_SHADER);
    defer zgl.deleteShader(vert_module);
    std.log.info("Compiled Vertex Shader: {}", .{vert_module});
    const geom_module = loadShaderModule(cube_g_shader, program, zgl.GEOMETRY_SHADER);
    defer zgl.deleteShader(geom_module);
    std.log.info("Compiled Geometry Shader: {}", .{geom_module});
    const frag_module = loadShaderModule(cube_f_shader, program, zgl.FRAGMENT_SHADER);
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

    return shader;
}

fn remShader(shader: *Shader) void {
    //delet program?
    _ = shader;
}

//for now?
const cube_f_shader =
    \\///CUBE FRAGMENT SHADER
    \\#version 330 core
    \\
    \\out vec4 outColor;
    \\in vec2 fragUV;
    \\in vec3 fragNormal;
    \\
    \\uniform vec4 colorA;
    \\uniform vec4 colorB;
    \\uniform vec3 rotation;
    \\uniform vec4 sun;
    \\
    \\void main()
    \\{
    \\  outColor = 
    \\      ((step(0.4f, abs(fragUV.x)) == 1 || step(0.4f, abs(fragUV.y)) == 1) ? colorB : colorA) + 
    \\          max(0.0, dot(rotation, fragNormal)) * sun * 0.1f; 
    \\}
;

const cube_g_shader =
    \\///CUBE GEOMETRY SHADER
    \\#version 330 core
    \\
    \\layout(points) in; 
    \\layout(triangle_strip, max_vertices = 36) out; 
    \\
    \\out vec2 fragUV;
    \\out vec3 fragNormal;
    \\
    \\uniform mat4 matrix; 
    \\
    \\
    \\vec3 verts[8] = vec3[]( 
    \\	vec3(-0.5f, -0.5f, -0.5f), vec3(0.5f, -0.5f, -0.5f), 
    \\	vec3(-0.5f, -0.5f, 0.5f), vec3(0.5f, -0.5f, 0.5f), 
    \\	vec3(0.5f, 0.5f, -0.5f), vec3(-0.5f, 0.5f, -0.5f), 
    \\	vec3(0.5f, 0.5f, 0.5f), vec3(-0.5f, 0.5f, 0.5f)
    \\); 
    \\
    \\void BuildFace(int fir, int sec, int thr, int frt, vec3 normal)
    \\{ 
    \\	gl_Position = matrix * vec4(verts[fir], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy ;
    \\  fragUV = vec2(-0.5f, 0.5f);	
    \\  EmitVertex(); 
    \\	gl_Position = matrix * vec4(verts[sec], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy;
    \\  fragUV = vec2(0.5f, -0.5f);	
    \\	EmitVertex(); 
    \\	gl_Position = matrix * vec4(verts[thr], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy;
    \\  fragUV = vec2(0.5f, 0.5f);	
    \\	EmitVertex(); 
    \\	EndPrimitive();
    \\	 
    \\	gl_Position = matrix * vec4(verts[fir], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy;
    \\  fragUV = vec2(0.5f, -0.5f);	
    \\	EmitVertex(); 
    \\	gl_Position = matrix * vec4(verts[frt], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy;
    \\  fragUV = vec2(0.5f, 0.5f);	
    \\	EmitVertex(); 
    \\	gl_Position = matrix * vec4(verts[sec], 1.0f);
    \\  fragNormal = (matrix * vec4(normal, 1.0f)).wxy;
    \\  fragUV = vec2(-0.5f, 0.5f);	
    \\	EmitVertex(); 
    \\	EndPrimitive(); 
    \\} 
    \\
    \\void main()
    \\{ 
    \\	BuildFace(0, 3, 2, 1, vec3(0.0, 1.0f, 0.0f));
    \\	BuildFace(5, 2, 7, 0, vec3(1.0f, 0.0f, 0.0f)); 
    \\	BuildFace(1, 6, 3, 4, vec3(-1.0f, 0.0f, 0.0f));
    \\	BuildFace(2, 6, 7, 3, vec3(0.0f, 0.0f, -1.0f)); 
    \\	BuildFace(5, 1, 0, 4, vec3(0.0f, 0.0f, 1.0f));
    \\	BuildFace(4, 7, 6, 5, vec3(0.0f, -1.0f, 0.0f));
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
