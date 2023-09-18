const std = @import("std");

/// The General Asset Management Metastruct
pub fn AssetCollection(
    comptime T: type,
    comptime add_asset: fn (asset_id: u32) T,
    comptime remove_asset: fn (asset: *T) void,
) type {
    return struct {
        const Self = @This();
        _collection: std.ArrayList(T) = undefined,
        comptime _add: fn (asset_id: u32) T = add_asset,
        comptime _remove: fn (asset: *T) void = remove_asset,
        pub fn init(this: *Self, allocator: std.mem.Allocator) void {
            this._collection = std.ArrayList(T).init(allocator);
        }
        pub fn deinit(this: *Self) void {
            for (this._collection.items) |*a|
                this._remove(a);
            this._collection.deinit();
        }
        pub fn fetch(this: *Self, asset_id: u32) !usize {
            //firstly see if it already exists
            for (0..this._collection.items.len) |i| {
                if (this._collection.items[i].id == asset_id) {
                    this._collection.items[i].subscribers += 1;
                    return i;
                }
            }
            //else see if there is one we can overwrite
            for (this._collection.items, 0..) |a, i| {
                if (a.subscribers < 1) {
                    this._collection.items[i] = this._add(asset_id);
                    this._collection.items[i].subscribers += 1;
                    return i;
                }
            }
            //otherwise jam it in at the end
            const asset = this._add(asset_id);
            try this._collection.append(asset);
            return this._collection.items.len - 1;
        }

        pub fn release(this: *Self, asset_id: u32) void {
            for (this._collection.items) |*a| {
                if (a.id == asset_id)
                    a.subscribers -|= 1;
            }
        }
        pub fn peek(this: *Self, asset_index: usize) *T {
            return &this._collection.items[asset_index];
        }
    };
}
