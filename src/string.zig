const std = @import("std");
const tst = std.testing;

/// A null-terminated string struct to be C compatible
pub const String = struct {
    buffer: ?[:0]u8 = null, // Be sure to be null-terminated
    str_size: usize = 0, // Called "str_size" to not missinterpret it as buffer size
    allocator: std.mem.Allocator,

    pub fn set_allocated_size(self: *String, size: usize) !void {
        const alloc_type = @typeInfo(
            @typeInfo(
                @TypeOf(self.buffer)
            ).optional.child
        ).pointer.child;

        if (self.buffer) |buffer| {
            _ = buffer;

        } else {
            var buffer = try self.allocator.allocSentinel(alloc_type, size, 0);
            self.str_size = 0; // The string is of size 0
            buffer[self.str_size] = 0; // null-terminate the string
            self.buffer = buffer;
        }
    }
    // pub fn append(self: String, s: []u8) !void {
    //
    // }
    //
    // pub fn free(self: String) void {
    //
    // }
};

test "set_allocated_size()" {
    var str: String = .{.allocator = std.heap.smp_allocator};

    try tst.expect(str.buffer == null);
    try tst.expectEqual(str.str_size, 0);

    try str.set_allocated_size(1);

    std.debug.print("{x}\n", .{str.buffer.?});
}
