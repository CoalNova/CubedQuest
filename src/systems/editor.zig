//! There's nothing here yet

const lvl = @import("../types/level.zig");

var delta_stack: lvl.Level[256] = undefined; // used to hold on to level structs for undo/redo operations
var delta_count: u8 = 0; // max relevant level structs in stack
var delat_index: u8 = 0; // current struct relation, for tracking redo
