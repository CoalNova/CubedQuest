const box = @import("../render/screenbox.zig");

const ScreenType = enum {
    start_landing,
    start_main,
    level_select,
    level_load,
    play_start,
    play_pause,
    play_playing,
    play_succedd,
    play_failure,
    settings_controls,
    settings_graphics,
    settings_accessibility,
};

const Screen = struct {
    screen_type: ScreenType,
    boxes: []box.ScreenBox,
};
