const std = @import("std");
const raylib = @import("raylib");

const i18n = @import("i18n.zig");
const calc = @import("calculator.zig");
const theme = @import("theme.zig");
const ui = @import("ui.zig");

const ScreenWidth = 480;
const ScreenHeight = 720;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    raylib.setConfigFlags(.{ .window_resizable = true });
    raylib.initWindow(ScreenWidth, ScreenHeight, "Calctron");
    defer raylib.closeWindow();

    raylib.setTargetFPS(60);

    var calculator = calc.Calculator.init(allocator);
    defer calculator.deinit();

    var is_dark = true;
    var show_help = false;
    var current_lang: i18n.Language = .en;

    while (!raylib.windowShouldClose()) {
        calculator.handleInput();

        // R = toggle theme (only if not during other input)
        if (raylib.isKeyPressed(.r)) {
            is_dark = !is_dark;
        }

        // H = toggle help
        if (raylib.isKeyPressed(.h)) {
            show_help = !show_help;
        }

        // Language shortcuts: 1-EN, 2-TR, 3-ES, 4-FR, 5-DE
        // Only when not actively typing digits (avoid conflict with number input)
        if (calc.Calculator.strLen(calculator.current_input) == 0) {
            const lang_keys = [_]struct { key: raylib.KeyboardKey, lang: i18n.Language }{
                .{ .key = .one, .lang = .en },
                .{ .key = .two, .lang = .tr },
                .{ .key = .three, .lang = .es },
                .{ .key = .four, .lang = .fr },
                .{ .key = .five, .lang = .de },
            };
            for (lang_keys) |lk| {
                if (raylib.isKeyPressed(lk.key)) {
                    current_lang = lk.lang;
                }
            }
        }

        const t = if (is_dark) &theme.Dark else &theme.Light;

        raylib.beginDrawing();
        raylib.clearBackground(t.*.background);

        ui.drawDisplay(&calculator, t, current_lang);
        ui.drawButtons(&calculator, t, current_lang);

        if (show_help) {
            ui.drawHelp(t, current_lang);
        }

        ui.drawStatusBar(t, current_lang, is_dark);

        raylib.endDrawing();
    }
}
