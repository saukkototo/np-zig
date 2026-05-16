const npz = @import("np_zig");

pub fn main() !void{
    try npz.NpCtx.run();
}
