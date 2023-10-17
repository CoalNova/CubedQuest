pub const Point2 = struct {
    x: i32 = 0,
    y: i32 = 0,
    pub inline fn init(x: i32, y: i32) Point2 {
        return Point2{ .x = x, .y = y };
    }
    pub inline fn toSIMD(this: Point2) @Vector(2, i32) {
        return @Vector(2, i32){ this.x, this.y };
    }
    pub inline fn fromSIMD(this: *Point2, simd: @Vector(2, i32)) void {
        this.x = simd[0];
        this.y = simd[1];
    }
};
pub const Point3 = struct {
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,
    pub inline fn init(x: i32, y: i32, z: i32) Point3 {
        return Point3{ .x = x, .y = y, .z = z };
    }
    pub inline fn toSIMD(this: Point3) @Vector(3, i32) {
        return @Vector(3, i32){ this.x, this.y, this.z };
    }
    pub inline fn fromSIMD(this: *Point3, simd: @Vector(3, i32)) void {
        this.x = simd[0];
        this.y = simd[1];
        this.z = simd[2];
    }
};
pub const Point4 = struct {
    w: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,
    pub inline fn init(w: i32, x: i32, y: i32, z: i32) Point4 {
        return Point4{ .w = w, .x = x, .y = y, .z = z };
    }
    pub inline fn toSIMD(this: Point4) @Vector(4, i32) {
        return @Vector(4, i32){ this.w, this.x, this.y, this.z };
    }
    //transverse probably wrong word, anyway swaps order for affine and matrix calcs
    pub inline fn toSIMDTransverse(this: Point4) @Vector(4, i32) {
        return @Vector(4, i32){ this.x, this.y, this.z, this.w };
    }
    pub inline fn fromSIMD(this: *Point4, simd: @Vector(4, i32)) void {
        this.w = simd[0];
        this.x = simd[1];
        this.y = simd[2];
        this.z = simd[3];
    }
    pub inline fn fromSIMDTransverse(this: *Point4, simd: @Vector(4, i32)) void {
        this.w = simd[3];
        this.x = simd[0];
        this.y = simd[1];
        this.z = simd[2];
    }
};
pub const Point6 = struct {
    u: i32 = 0,
    v: i32 = 0,
    w: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,
    pub inline fn init(u: i32, v: i32, w: i32, x: i32, y: i32, z: i32) Point6 {
        return Point6{ .u = u, .v = v, .w = w, .x = x, .y = y, .z = z };
    }
    pub inline fn toSIMD(this: Point6) @Vector(6, i32) {
        return @Vector(6, i32){ this.u, this.v, this.w, this.x, this.y, this.z };
    }
    pub inline fn fromSIMD(this: *Point4, simd: @Vector(4, i32)) void {
        this.w = simd[0];
        this.x = simd[1];
        this.y = simd[2];
        this.z = simd[3];
    }
};

pub const Float2 = struct {
    x: f32 = 0,
    y: f32 = 0,
    pub inline fn init(x: f32, y: f32) Float2 {
        return Float2{ .x = x, .y = y };
    }
    pub inline fn toSIMD(this: Float2) @Vector(2, f32) {
        return @Vector(2, f32){ this.x, this.y };
    }
    pub inline fn fromSIMD(this: *Float2, simd: @Vector(2, f32)) void {
        this.x = simd[0];
        this.y = simd[1];
    }
};
pub const Float3 = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    pub inline fn init(x: f32, y: f32, z: f32) Float3 {
        return Float3{ .x = x, .y = y, .z = z };
    }
    pub inline fn toSIMD(this: Float3) @Vector(3, f32) {
        return @Vector(3, f32){ this.x, this.y, this.z };
    }
    pub inline fn fromSIMD(this: *Float3, simd: @Vector(3, f32)) void {
        this.x = simd[0];
        this.y = simd[1];
        this.z = simd[2];
    }
    pub inline fn toArray(this: Float3) [3]f32 {
        return [3]f32{ this.x, this.y, this.z };
    }
    pub inline fn initFromArray(array: [3]f32) Float3 {
        return Float3{ .x = array[0], .y = array[1], .z = array[2] };
    }
    pub inline fn fromUIntArray(this: *Float3, array: [3]u8, divisor: f32) void {
        this.x = @as(f32, @floatFromInt(array[0])) / divisor;
        this.y = @as(f32, @floatFromInt(array[1])) / divisor;
        this.z = @as(f32, @floatFromInt(array[2])) / divisor;
    }
};
pub const Float4 = struct {
    w: f32 = 0,
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    pub inline fn init(w: f32, x: f32, y: f32, z: f32) Float4 {
        return Float4{ .w = w, .x = x, .y = y, .z = z };
    }
    pub inline fn toSIMD(this: Float4) @Vector(4, f32) {
        return @Vector(4, f32){ this.w, this.x, this.y, this.z };
    }
    //transverse probably wrong word, anyway swaps order for affine and matrix calcs
    pub inline fn toSIMDTransverse(this: Float4) @Vector(4, f32) {
        return @Vector(4, f32){ this.x, this.y, this.z, this.w };
    }
    pub inline fn fromSIMD(this: *Float4, simd: @Vector(4, f32)) void {
        this.w = simd[0];
        this.x = simd[1];
        this.y = simd[2];
        this.z = simd[3];
    }
    pub inline fn fromSIMDTransverse(this: *Float4, simd: @Vector(4, f32)) void {
        this.w = simd[3];
        this.x = simd[0];
        this.y = simd[1];
        this.z = simd[2];
    }
    pub inline fn toArray(this: Float4) [4]f32 {
        return [4]f32{ this.w, this.x, this.y, this.z };
    }
    pub inline fn fromUIntArray(this: *Float4, array: [4]u8, divisor: f32) void {
        this.w = @as(f32, @floatFromInt(array[0])) / divisor;
        this.x = @as(f32, @floatFromInt(array[1])) / divisor;
        this.y = @as(f32, @floatFromInt(array[2])) / divisor;
        this.z = @as(f32, @floatFromInt(array[3])) / divisor;
    }
};
pub const Float6 = struct {
    u: f32 = 0,
    v: f32 = 0,
    w: f32 = 0,
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    pub inline fn init(u: f32, v: f32, w: f32, x: f32, y: f32, z: f32) Float6 {
        return Float4{ .u = u, .v = v, .w = w, .x = x, .y = y, .z = z };
    }
    pub inline fn toSIMD(this: Point6) @Vector(6, i32) {
        return @Vector(6, i32){ this.u, this.v, this.w, this.x, this.y, this.z };
    }
    pub inline fn fromSIMD(this: *Point4, simd: @Vector(4, i32)) void {
        this.w = simd[0];
        this.x = simd[1];
        this.y = simd[2];
        this.z = simd[3];
    }
};
