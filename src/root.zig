const std = @import("std");

const str = @import("string.zig");

// const c = @cImport({
//     @cInclude("stdio.h");
// });
const rl = @cImport({
    @cInclude("raylib.h");
    });

/// The program main context struct.
pub const NpCtx = struct{
    w: f64 = 1080.0,
    h: f64 = 720.0,

    font_size: f64 = 128.0,
    border_thickness: f64 = 4.0,

    text_frame_rect: rl.Rectangle = .{
        .x = 0.0,
        .y = 0.0,
        .width = 0.0,
        .height = 0.0,
    },

    colors: Colors = .{},

    const Colors = struct {
        primary: rl.Color = .{
            .r = 255,
            .g = 255,
            .b = 255,
            .a = 255,
        },
        secondary: rl.Color = .{
            .r = 69,
            .g = 60,
            .b = 60,
            .a = 255,
        },
        accent: rl.Color = .{
            .r = 150,
            .g = 50,
            .b = 255,
            .a = 255,
        },
    };

    pub fn run() void {
        var ctx = NpCtx.init();

        while(!ctx.should_stop()){
            ctx.process_user_event();

            ctx.compute();

            ctx.render();
        }

        ctx.deinit();
        return;
    }

    fn init() NpCtx {
        const ctx: NpCtx = .{};

        rl.InitWindow(@round(ctx.w), @round(ctx.h), "Hello World!");
        rl.SetTargetFPS(60);

        return ctx;
    }

    fn should_stop(self: *NpCtx) bool {
        _ = self;
        return rl.WindowShouldClose();
    }
    
    fn process_user_event(self: *NpCtx) void {
        // Get screen size
        self.w = rl.GetScreenWidth();
        self.h = rl.GetScreenHeight();

        // Get character inputs
        var codepoint: i32 = rl.GetCharPressed();
        while (codepoint != 0) : (codepoint = rl.GetCharPressed()) {
            var character = [_]u8{0} ** @sizeOf(@TypeOf(codepoint));
            if (std.unicode.utf8Encode(@intCast(codepoint), &character)) |_| {
                std.debug.print("{s}\n", .{character});
            } else |_| {
                std.debug.print("Error!\n", .{});
            }
        }
    }

    fn compute(self: *NpCtx) void {
        const text_frame_rect_y_offset: f64 = 100;
        self.text_frame_rect = .{
            .x = 0.0,
            .y = @floatCast(text_frame_rect_y_offset),
            .width = @floatCast(self.w),
            .height = @floatCast(self.h - text_frame_rect_y_offset),
        };
    }

    fn render(self: *NpCtx) void {
        rl.BeginDrawing();

        rl.ClearBackground(self.colors.secondary);

        // Draw text frame rectangle
        rl.DrawRectangleLinesEx(
            self.text_frame_rect,
            @floatCast(self.border_thickness),
            self.colors.accent
        );

        const x: f64 = @rem(rl.GetTime() * 0.5 * 1000.0, self.w);
        const y: f64 = (self.h - self.font_size) / 2.0;

        rl.DrawText("Hello Lili!", @round(x), @round(y), @round(self.font_size), self.colors.primary);
    
        rl.EndDrawing();
    }

    fn deinit(self: *NpCtx) void {
        _ = self;
        rl.CloseWindow();
    }
};

pub fn main() void{
    NpCtx.run();
}

