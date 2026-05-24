const std = @import("std");
const str = @import("string.zig");
const c_std = @cImport({@cInclude("stdio.h");});

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

    text: str.String = .{.allocator = std.heap.smp_allocator},

    font_size: f64 = 24.0,

    text_layout: ItemRenderLayout = .{
        .border = .{.xl = 8.0, .xr = 8.0, .yu = 8.0, .yd = 8.0},
        .padding = .{.xl = 4.0, .xr = 4.0, .yu = 4.0, .yd = 4.0},
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

    const ItemRenderLayout = struct {
        rect: rl.Rectangle = .{
            .x = 0.0,
            .y = 0.0,
            .width = 0.0,
            .height = 0.0,
        },
        margin: RectThickness = .{}, 
        border: RectThickness = .{}, 
        padding: RectThickness = .{}, 

        pub fn get_inner_rect(self: *ItemRenderLayout) rl.Rectangle {
            const thick_left = self.border.xl + self.padding.xl;
            const thick_right = self.border.xr + self.padding.xr;
            const thick_up = self.border.yu + self.padding.yu;
            const thick_down = self.border.yd + self.padding.yd;
            
            return .{
                .x = self.rect.x + thick_left,
                .y = self.rect.y + thick_up,
                .width = self.rect.width - thick_left - thick_right,
                .height = self.rect.height - thick_up - thick_down,
            };
        }

        pub fn draw_border(self: *ItemRenderLayout, color: rl.Color) void {
            //
            //  p1-----------------------p2
            //  |                        |
            //  |  p5-----------------p6 |
            //  |  |                  |  |
            //  |  |                  |  |
            //  |  p8-----------------p7 |
            //  p4-----------------------p3
            //
            const p1: rl.Vector2 = .{
                .x = self.rect.x,
                .y = self.rect.y,
            };
            const p2: rl.Vector2 = .{
                .x = self.rect.x + self.rect.width,
                .y = self.rect.y
            };
            const p3: rl.Vector2 = .{
                .x = self.rect.x + self.rect.width,
                .y = self.rect.y + self.rect.height
            };
            const p4: rl.Vector2 = .{
                .x = self.rect.x,
                .y = self.rect.y + self.rect.height,
            };
            const p5: rl.Vector2 = .{
                .x = p1.x + self.border.xl,
                .y = p1.y + self.border.yu,
            };
            const p6: rl.Vector2 = .{
                .x = p2.x - self.border.xr,
                .y = p2.y + self.border.yu,
            };
            const p7: rl.Vector2 = .{
                .x = p3.x - self.border.xr,
                .y = p3.y - self.border.yd,
            };
            const p8: rl.Vector2 = .{
                .x = p4.x + self.border.xl,
                .y = p4.y - self.border.yd,
            };

            if (self.border.yu > 0.0) {
                var tri_up = [_]rl.Vector2{
                    p6,
                    p2,
                    p1,
                    p5,
                    p6,
                };
                rl.DrawTriangleStrip(&tri_up, tri_up.len, color);
            }

            if (self.border.xr > 0.0) {
                var tri_right = [_]rl.Vector2{
                    p7,
                    p3,
                    p2,
                    p6,
                    p7,
                };
                rl.DrawTriangleStrip(&tri_right, tri_right.len, color);
            }

            if (self.border.yd > 0.0) {
                var tri_down = [_]rl.Vector2{
                    p8,
                    p4,
                    p3,
                    p7,
                    p8,
                };
                rl.DrawTriangleStrip(&tri_down, tri_down.len, color);
            }

            if (self.border.xl > 0.0) {
                var tri_left = [_]rl.Vector2{
                    p5,
                    p1,
                    p4,
                    p8,
                    p5,
                };
                rl.DrawTriangleStrip(&tri_left, tri_left.len, color);
            }
        }
    };

    const RectThickness = struct {
        xl: f32 = 0.0, // X Left
        xr: f32 = 0.0, // X Right
        yu: f32 = 0.0, // Y Up
        yd: f32 = 0.0, // Y Down
    };

    pub fn run() !void {
        var ctx = try NpCtx.init();

        while(!ctx.should_stop()){
            try ctx.process_user_event();

            ctx.compute();

            ctx.render();
        }

        ctx.deinit();
        return;
    }

    fn init() !NpCtx {
        var ctx: NpCtx = .{};

        try ctx.text.set_allocated_size(10);

        rl.InitWindow(@round(ctx.w), @round(ctx.h), "Hello World!");
        rl.SetTargetFPS(60);

        return ctx;
    }

    fn should_stop(self: *NpCtx) bool {
        _ = self;
        return rl.WindowShouldClose();
    }
    
    fn process_user_event(self: *NpCtx) !void {
        // Get screen size
        self.w = rl.GetScreenWidth();
        self.h = rl.GetScreenHeight();

        // Get character inputs
        var codepoint: u32 = @bitCast(rl.GetCharPressed());
        while (codepoint != 0) : (codepoint = @bitCast(rl.GetCharPressed())) {
            try self.text.insert_codepoints(
                (&@as(u21, @intCast(codepoint)))[0..1],
                self.text.len
            );
        }

        if (rl.IsKeyPressed(rl.KEY_ENTER)) {
            try self.text.concat("\n");
        }

        if (rl.IsKeyPressed(rl.KEY_BACKSPACE)) {
            _ = self.text.pop_back();
        }
    }

    fn compute(self: *NpCtx) void {
        const text_frame_rect_y_offset: f64 = 100;
        self.text_layout.rect = .{
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
        self.text_layout.draw_border(self.colors.accent);

        // Draw scrolling text
        const x: f64 = @rem(rl.GetTime() * 0.5 * 1000.0, self.w);
        const y: f64 = (self.h - self.font_size) / 2.0;
        rl.DrawText("Hello Lili!", @round(x), @round(y), 128, self.colors.primary);

        // Draw text
        const text_draw_area = self.text_layout.get_inner_rect();

        rl.SetTextLineSpacing(@round(self.font_size));
        rl.DrawTextEx(
            rl.GetFontDefault(),
            self.text.as_literal(),
            .{
                .x = text_draw_area.x,
                .y = text_draw_area.y,
            },
            @floatCast(self.font_size),
            10.0,
            self.colors.primary
        );

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

