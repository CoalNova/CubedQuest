const std = @import("std");
const sys = @import("../systems/system.zig");

// Shorthands
const Mutex = std.Thread.Mutex;
const Instant = std.time.Instant;

/// Will contain unique clocks for the separate threads, threads will need to compare against own
/// Separated to help avoid lock congestion
var then: Instant = undefined;
var lock: Mutex = .{};
var delta: f32 = 1.0;

/// Initialize clocks collection, clock count should match number of used threads *including* main thread
pub fn init() !void {
    then = try Instant.now();
    fps_then = try Instant.now();
}

/// Frees used element storage
pub fn deinit() void {
    // currently nothing?
}

/// Updates frame start time
pub fn proc() !void {
    fps_tick +|= 1;
    lock.lock();
    defer lock.unlock();
    const now = try Instant.now();
    delta = @as(f32, @floatFromInt(Instant.since(now, then))) * 1e-9;
    then = now;
}

/// Time since frame logical update, with 1.0 as one second
/// Requires thread number for isolation
/// Note: inaccuracy coincides with Update() complexity/cost
pub fn frameDelta() f32 {
    return delta;
}

var fps_then: Instant = undefined;
var fps_tick: u64 = 0;

pub fn pollFPSCounter(per_second_divisor: u64) !u64 {
    var fps: u64 = 0;
    const fps_cap = @as(u64, 1e9) / per_second_divisor;
    const fps_now = try Instant.now();
    const fps_delta = Instant.since(fps_now, fps_then);
    if (fps_delta > fps_cap) {
        fps_then = fps_now;
        fps = fps_tick;
        fps_tick = 0;
    }
    return fps;
}
