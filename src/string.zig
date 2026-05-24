const std = @import("std");
const assert = std.debug.assert;
const tst = std.testing;
const uni = std.unicode;


const allocator = std.testing.allocator;
// const allocator = std.heap.smp_allocator;

/// A null-terminated string struct to be C compatible
pub const String = struct {
    buffer: ?[:0]u8 = null, // UTF8 encoded codepoints
    len: usize = 0, // Number of UTF8 bytes
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

    // Release the string allocated memory
    // The string can still be used after being free, it'll just be empty.
    // Inserting stuff inside will allocate a new memory space.
    pub fn free(self: *String) void {
        self.len = 0;
        if (self.buffer) |buffer| {
            self.allocator.free(buffer);
            self.buffer = null;
        }
    }

    /// Returns the string as a literal
    pub fn as_literal(self: *String) [:0]const u8 {
        if (self.buffer) |buffer| return buffer[0..self.len :0];
        return "";
    }

    /// Insert str at index
    /// WARNING! Doesn't check if index makes sense in term of UT8 codepoint
    pub fn insert(self: *String, str: []const u8, index: usize) !void {
        if (self.buffer == null) {
            try self.set_allocated_size(str.len);
        }
        
        // index can't be > str.len
        const valid_index = if (index > self.len) self.len else index;
        const new_length = self.len + str.len;
        const buffer = &self.buffer.?;

        if (buffer.*.len < new_length) {
            try self.set_allocated_size(new_length);
        }
 
        if (valid_index < self.len) {
            // We need to move what's after index
            const src_begin = valid_index;
            const src_end = self.len;
            const dst_begin = src_begin + str.len;
            const dst_end = dst_begin + src_end - src_begin;
            @memcpy(buffer.*[dst_begin..dst_end],buffer.*[src_begin..src_end]);
        }

        @memcpy(buffer.*[valid_index..valid_index+str.len], str);

        self.len = new_length;
        buffer.*[self.len] = 0;
    }

    /// Insert str at the end of string
    pub fn concat(self: *String, str: []const u8) !void {
        try self.insert(str, self.len);
    }

    pub fn insert_codepoints(self: *String, codepoints: []const u21, index: usize) !void {
        // TODO: create a buffer of size 4*codepoints.len and append utf8_char into it
        // then, at the function end, insert the resulting buffer into the string
        // OR pre-compute the required capacity and use set_allocated_size() before inserting it
        var offset: usize = 0;
        for (codepoints) |codepoint| {
            var utf8_char = [_]u8{0} ** 4; // UTF-8 can take up to 4 bytes
            const utf8_len = try uni.utf8Encode(codepoint, &utf8_char);
            try self.insert(utf8_char[0..utf8_len], index+offset);
            offset += utf8_len;
        }
    }

    pub fn concat_codepoints(self: *String, codepoints: []const u21) !void {
        try self.insert_codepoints(codepoints, self.len);
    }

    /// Remove the last UTF8 char in a string. Returns True if a char has been removed, else returns False.
    pub fn pop_back(self: *String) bool {
        if (self.len < 1) return false;

        if (self.buffer) |*buffer| {
            // From string end, check each byte until we get a successful UTF8 length.
            // It means we're at the beginning of a valid UTF8 character.
            while(self.len > 0) {
                const utf8_len = uni.utf8ByteSequenceLength(buffer.*[self.len - 1]);
                self.len -= 1;
                if (utf8_len) |_| { // UT8 char start byte
                    buffer.*[self.len] = 0; // null-terminated
                    break;
                } else |_| {}
            }
            // If utf8ByteSequenceLength() never succeed, we still return true
            // since we erased some bytes.
            return true;
        } else return false;
    }
};

test "set_allocated_size()" {
    const size_1: usize = 6;
    const size_2: usize = 12;
    const size_3: usize = 3;

    var str: String = .{.allocator = allocator};
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

    std.debug.print("\"{s}\"\n", .{str.as_literal()});
}

test "insert()" {
    var str: String = .{.allocator = allocator};
    defer str.free();

    try str.insert("Hello", 0);
    std.debug.print("\"{s}\"\n", .{str.as_literal()});

    try str.insert(" World!", str.len);
    std.debug.print("\"{s}\"\n", .{str.as_literal()});

    try str.insert(" Wonderful", 5);
    std.debug.print("\"{s}\"\n", .{str.as_literal()});
}
