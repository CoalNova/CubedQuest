const std = @import("std");
const mth = @import("zmath");
const csm = @import("../systems/csmath.zig");
const euc = @import("../types/euclid.zig");
const wnd = @import("../types/window.zig");

pub const Camera = struct {
    euclid: euc.Euclid = .{},
    field_of_view: f32 = 90.0,
    near_plane: f32 = 0.01,
    far_plane: f32 = 10000.0,
    forward: mth.F32x4 = undefined,
    upward: mth.F32x4 = undefined,
    view_matrix: mth.Mat = undefined,
    projection_matrix: mth.Mat = undefined,
    horizon_matrix: mth.Mat = undefined,
    rotation_matrix: mth.Mat = undefined,
    vp_matrix: mth.Mat = undefined,

    /// Calculates View and Projection Matrices
    /// TODO handle 'forward' modifiers for camera -> worldspace inputs
    pub fn calculateMatrices(self: *Camera, window: *wnd.Window) void {
        // self.render_index = idx.Index32_4{
        //     .w = 0,
        //     .x = @truncate(u8, @intCast(u64, self.euclid.position.index().x)),
        //     .y = @truncate(u8, @intCast(u64, self.euclid.position.index().y)),
        //     .z = @truncate(u8, @intCast(u64, self.euclid.position.index().z)),
        // };

        const tmp_pos = self.euclid.position.getAxial();
        const cam_pos = mth.f32x4(tmp_pos.x, tmp_pos.y, tmp_pos.z, 1);
        const cam_eul = csm.vec3ToH(csm.convQuatToEul(self.euclid.rotation));
        self.forward = mth.normalize4(mth.mul(mth.quatToMat(self.euclid.rotation), mth.f32x4(0, 1, 0, 1)));
        const right = mth.normalize4(mth.mul(mth.quatToMat(self.euclid.rotation), mth.f32x4(1, 0, 0, 1)));
        self.upward = mth.normalize4(mth.cross3(right, self.forward));

        //TODO allow adjustment of this for leaining
        //self.upward = csm.Vec4{ 0, 0, 1, 1 };

        self.horizon_matrix = csm.convQuatToMat4(csm.convEulToQuat(csm.Vec3{ 0, 0, (cam_eul[2] + 90) * std.math.pi / 180 }));
        self.rotation_matrix = csm.convQuatToMat4(csm.convEulToQuat(csm.Vec3{ (cam_eul[0]) * std.math.pi / 180, 0, (cam_eul[2] + 90) * std.math.pi / 180 }));

        self.view_matrix = mth.lookAtRh(
            cam_pos,
            cam_pos + self.forward,
            self.upward,
        );

        self.projection_matrix =
            mth.perspectiveFovRhGl(
            self.field_of_view,
            @as(f32, @floatFromInt(window.size.x)) / @as(f32, @floatFromInt(window.size.y)),
            self.near_plane,
            self.far_plane,
        );

        self.vp_matrix = mth.mul(self.view_matrix, self.projection_matrix);
    }
};
