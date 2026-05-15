const std = @import("std");

pub const String = struct {
    buffer: []u8 = undefined,
    size: usize = 0,

    pub fn append(self: String, s: []u8) !void {
        
    }
}
