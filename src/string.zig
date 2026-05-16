const std = @import("std");
const assert = std.debug.assert;
const tst = std.testing;


/// A null-terminated string struct to be C compatible
pub const String = struct {
    buffer: ?[:0]u8 = null, // Be sure to be null-terminated
    len: usize = undefined,
    allocator: std.mem.Allocator,

    const Error = error {
        UnsupportedStringType,
    };

    pub fn set_allocated_size(self: *String, size: usize) !void {
        if (self.buffer) |*buffer| {
            // Unfortunatelly, "reallocSentinel" doesn't exist...
            // buffer.* = try self.allocator.reallocSentinel(buffer.*, size);
            var new_buffer = try self.allocator.realloc(buffer.*[0..buffer.*.len], size+1);
            new_buffer[size] = 0;
            buffer.* = new_buffer[0..size :0];
            
        } else {
            // Allocate using "alloc" instead of "allocSentinel" because "reallocSentinel" doesn't exist
            // self.buffer = try self.allocator.allocSentinel(u8, size, 0);
            var buffer = try self.allocator.alloc(u8, size+1);
            buffer[size] = 0;
            self.buffer = buffer[0..size :0];
            
            // The string is empty
            self.len = 0; 
            if(size > 0) {
                self.buffer.?[self.len] = 0;
            }

        }
    }

    pub fn free(self: *String) void {
        if (self.buffer) |buffer| {
            self.allocator.free(buffer);
            self.buffer = null;
        }
    }

    pub fn to_str(self: *String) [:0]const u8 {
        if (self.buffer) |buffer| return buffer[0..self.len :0];
        return "";
    }

    pub fn insert(self: *String, str: []const u8, index: usize) !void {
        if (self.buffer == null) {
            try self.set_allocated_size(str.len);
        }
        
        const new_length = self.len + str.len;
        const buffer = &self.buffer.?;

        if (buffer.*.len < new_length) {
            try self.set_allocated_size(new_length);
        }
 
        // Concatenate
        if (index >= self.len) {
            @memcpy(buffer.*, str);
        } else {
            const len_to_move = self.len-index;
            @memcpy(buffer.*[index..len_to_move], buffer.*[index+str.len..len_to_move]);
        }

        self.len = new_length;
        buffer.*[self.len] = 0;
    }
};

test "set_allocated_size()" {
    const size_1: usize = 6;
    const size_2: usize = 12;
    const size_3: usize = 3;

    var str: String = .{.allocator = std.heap.smp_allocator};
    defer str.free();

    try tst.expect(str.buffer == null);

    try str.set_allocated_size(size_1);

    try tst.expect(str.buffer != null);
    try tst.expectEqual(str.buffer.?.len, size_1);
    try tst.expectEqual(str.len, 0);

    try str.set_allocated_size(size_2);

    try tst.expect(str.buffer != null);
    try tst.expectEqual(str.buffer.?.len, size_2);
    try tst.expectEqual(str.len, 0);

    try str.set_allocated_size(size_3);

    try tst.expect(str.buffer != null);
    try tst.expectEqual(str.buffer.?.len, size_3);
    try tst.expectEqual(str.len, 0);

    std.debug.print("\"{s}\"\n", .{str.to_str()});
}

test "insert()" {
    var str: String = .{.allocator = std.heap.smp_allocator};
    defer str.free();

    try str.insert("Hello World", 0);
    std.debug.print("\"{s}\"\n", .{str.to_str()});
}
