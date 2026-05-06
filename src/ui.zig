const std = @import("std");
const raylib = @import("raylib");

const calc = @import("calculator.zig");
const theme_mod = @import("theme.zig");
const i18n = @import("i18n.zig");

fn drawText(text: []const u8, x: i32, y: i32, size: i32, color: raylib.Color) void {
    var buf: [256]u8 = undefined;
    const z = std.fmt.bufPrintZ(&buf, "{s}", .{text}) catch return;
    raylib.drawText(z, x, y, size, color);
}

pub fn drawDisplay(calculator: *calc.Calculator, t: *const theme_mod.Theme, lang: i18n.Language) void {
    const sw: f32 = @floatFromInt(raylib.getScreenWidth());
    const margin: f32 = 10;
    const display_h: f32 = 100;
    const display_y: f32 = 40;
    const display_w = sw - margin * 2;

    const rect = raylib.Rectangle{ .x = margin, .y = display_y, .width = display_w, .height = display_h };

    raylib.drawRectangleRounded(rect, 0.15, 8, t.display_bg);
    raylib.drawRectangleRoundedLines(rect, 0.15, 8, t.separator);

    const text = calculator.getDisplayText();
    const font_size: i32 = if (text.len > 12) 20 else if (text.len > 8) 28 else 36;

    var buf: [256]u8 = undefined;
    const text_z = std.fmt.bufPrintZ(&buf, "{s}", .{text}) catch return;
    const text_w = raylib.measureText(text_z, font_size);
    const text_x = margin + display_w - @as(f32, @floatFromInt(text_w)) - 15;
    const text_y: i32 = @intFromFloat(display_y + (display_h - @as(f32, @floatFromInt(font_size))) / 2);

    const text_color = if (calculator.error_msg != null) t.error_text else t.display_text;
    drawText(text, @intFromFloat(text_x), text_y, font_size, text_color);

    drawText(i18n.get(lang, .title), @as(i32, @intFromFloat(margin)) + 5, 10, 18, t.display_text);

    const sci_txt = i18n.get(lang, if (calculator.scientific_mode) .scientific else .basic);
    drawText(sci_txt, @intFromFloat(sw - margin - 40), 10, 14, t.status_bar_text);

    if (calculator.use_degrees) {
        raylib.drawText("DEG", @intFromFloat(sw - margin - 80), 10, 14, t.status_bar_text);
    }
}

pub fn drawButtons(calculator: *calc.Calculator, t: *const theme_mod.Theme, lang: i18n.Language) void {
    const sw: f32 = @floatFromInt(raylib.getScreenWidth());
    const margin: f32 = 10;
    const display_bottom: f32 = 145;
    const gap: f32 = 6;

    const cols: i32 = if (calculator.scientific_mode) 5 else 4;
    const btn_w_raw = (sw - margin * @as(f32, @floatFromInt(cols + 1)) - gap * @as(f32, @floatFromInt(cols - 1))) / @as(f32, @floatFromInt(cols));
    const btn_w = @max(btn_w_raw, 20.0);
    const btn_h: f32 = 55;

    if (calculator.scientific_mode) {
        const SciBtn = struct { label: i18n.Label, action: *const fn (*calc.Calculator) void };
        const sci_btns = [_]SciBtn{
            .{ .label = .sin, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("sin");
                }
            }.f },
            .{ .label = .cos, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("cos");
                }
            }.f },
            .{ .label = .tan, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("tan");
                }
            }.f },
            .{ .label = .ln, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("ln");
                }
            }.f },
            .{ .label = .log, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("log");
                }
            }.f },
            .{ .label = .sqrt, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("sqrt");
                }
            }.f },
            .{ .label = .square, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("square");
                }
            }.f },
            .{ .label = .cube, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("cube");
                }
            }.f },
            .{ .label = .pow, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.setOperator(.pow);
                }
            }.f },
            .{ .label = .pi, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("pi");
                }
            }.f },
            .{ .label = .e, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("e");
                }
            }.f },
            .{ .label = .fact, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("fact");
                }
            }.f },
            .{ .label = .inv, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("inv");
                }
            }.f },
            .{ .label = .percent, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("percent");
                }
            }.f },
            .{ .label = .reciprocal, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.applyUnary("negate");
                }
            }.f },
            .{ .label = .clear, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.reset();
                }
            }.f },
            .{ .label = if (calculator.use_degrees) .deg else .rad, .action = struct {
                pub fn f(c: *calc.Calculator) void {
                    c.use_degrees = !c.use_degrees;
                }
            }.f },
        };

        const sci_cols: i32 = 5;
        inline for (sci_btns, 0..) |btn, i| {
            const row: i32 = @intCast(@as(i32, @intCast(i)) / sci_cols);
            const col: i32 = @as(i32, @intCast(i)) % sci_cols;
            const bx = margin + @as(f32, @floatFromInt(col)) * (btn_w + gap);
            const by = display_bottom + @as(f32, @floatFromInt(row)) * (btn_h + gap);

            const mouse = raylib.getMousePosition();
            const r = raylib.Rectangle{ .x = bx, .y = by, .width = btn_w, .height = btn_h };
            const is_hover = raylib.checkCollisionPointRec(mouse, r);

            raylib.drawRectangleRounded(r, 0.2, 8, if (is_hover) t.btn_hover else t.btn_sci_bg);

            const label = i18n.get(lang, btn.label);
            var buf: [16]u8 = undefined;
            const label_z = std.fmt.bufPrintZ(&buf, "{s}", .{label}) catch "";
            const tw = raylib.measureText(label_z, 20);
            const tx = bx + (btn_w - @as(f32, @floatFromInt(tw))) / 2;
            const ty: i32 = @intFromFloat(by + (btn_h - 20) / 2);
            raylib.drawText(label_z, @intFromFloat(tx), ty, 20, t.btn_sci_text);

            if (is_hover and raylib.isMouseButtonPressed(.left)) {
                btn.action(calculator);
            }
        }
    }

    const basic_start_y = if (calculator.scientific_mode)
        display_bottom + btn_h * 4 + gap * 4
    else
        display_bottom + gap;

    const basic_btns = [_]struct { label: [:0]const u8, is_op: bool, is_eq: bool, digit: ?u8 }{
        .{ .label = "7", .is_op = false, .is_eq = false, .digit = 7 },
        .{ .label = "8", .is_op = false, .is_eq = false, .digit = 8 },
        .{ .label = "9", .is_op = false, .is_eq = false, .digit = 9 },
        .{ .label = "÷", .is_op = true, .is_eq = false, .digit = null },
        .{ .label = "4", .is_op = false, .is_eq = false, .digit = 4 },
        .{ .label = "5", .is_op = false, .is_eq = false, .digit = 5 },
        .{ .label = "6", .is_op = false, .is_eq = false, .digit = 6 },
        .{ .label = "×", .is_op = true, .is_eq = false, .digit = null },
        .{ .label = "1", .is_op = false, .is_eq = false, .digit = 1 },
        .{ .label = "2", .is_op = false, .is_eq = false, .digit = 2 },
        .{ .label = "3", .is_op = false, .is_eq = false, .digit = 3 },
        .{ .label = "-", .is_op = true, .is_eq = false, .digit = null },
        .{ .label = "0", .is_op = false, .is_eq = false, .digit = 0 },
        .{ .label = ".", .is_op = false, .is_eq = false, .digit = null },
        .{ .label = "=", .is_op = false, .is_eq = true, .digit = null },
        .{ .label = "+", .is_op = true, .is_eq = false, .digit = null },
    };

    const basic_cols: i32 = 4;
    inline for (basic_btns, 0..) |bb, i| {
        const offset: i32 = if (calculator.scientific_mode) 3 else 0;
        const row: i32 = offset + @as(i32, @intCast(i)) / basic_cols;
        const col: i32 = @as(i32, @intCast(i)) % basic_cols;
        const by = basic_start_y + @as(f32, @floatFromInt(row - offset)) * (btn_h + gap);
        const bx = margin + @as(f32, @floatFromInt(col)) * (btn_w + gap);

        const mouse = raylib.getMousePosition();
        const r = raylib.Rectangle{ .x = bx, .y = by, .width = btn_w, .height = btn_h };
        const is_hover = raylib.checkCollisionPointRec(mouse, r);

        const bg_color = if (bb.is_eq)
            if (is_hover) t.btn_hover else t.btn_eq_bg
        else if (bb.is_op)
            if (is_hover) t.btn_hover else t.btn_op_bg
        else if (is_hover) t.btn_hover else t.btn_bg;
        const txt_color = if (bb.is_eq) t.btn_eq_text else if (bb.is_op) t.btn_op_text else t.btn_text;

        raylib.drawRectangleRounded(r, 0.2, 8, bg_color);

        const tw = raylib.measureText(bb.label, 24);
        const tx = bx + (btn_w - @as(f32, @floatFromInt(tw))) / 2;
        const ty: i32 = @intFromFloat(by + (btn_h - 24) / 2);
        raylib.drawText(bb.label, @intFromFloat(tx), ty, 24, txt_color);

        if (is_hover and raylib.isMouseButtonPressed(.left)) {
            if (bb.digit) |d| {
                calculator.appendDigit(d);
            } else if (bb.is_eq) {
                calculator.evaluate();
            } else if (bb.label[0] == '.') {
                calculator.appendDot();
            } else if (bb.label[0] == '+') {
                calculator.setOperator(.add);
            } else if (bb.label[0] == '-') {
                calculator.setOperator(.sub);
            } else if (bb.label[0] == '×') {
                calculator.setOperator(.mul);
            } else if (bb.label[0] == '÷') {
                calculator.setOperator(.div);
            }
        }
    }
}

pub fn drawHelp(t: *const theme_mod.Theme, lang: i18n.Language) void {
    const sw: f32 = @floatFromInt(raylib.getScreenWidth());
    const sh: f32 = @floatFromInt(raylib.getScreenHeight());

    raylib.drawRectangle(0, 0, @intFromFloat(sw), @intFromFloat(sh), .{ .r = 0, .g = 0, .b = 0, .a = 150 });

    const help_title = i18n.get(lang, .help_title);
    const help_text = i18n.get(lang, .help_text);
    var title_buf: [256]u8 = undefined;
    const title_z = std.fmt.bufPrintZ(&title_buf, "{s}", .{help_title}) catch return;
    const tw = raylib.measureText(title_z, 28);
    raylib.drawText(title_z, @intFromFloat((sw - @as(f32, @floatFromInt(tw))) / 2), 60, 28, t.display_text);

    var text_buf: [512]u8 = undefined;
    const help_z = std.fmt.bufPrintZ(&text_buf, "{s}", .{help_text}) catch return;

    var y: i32 = 110;
    const line_h: i32 = 24;
    var pos: usize = 0;
    while (pos < help_z.len) {
        const end = std.mem.indexOfScalarPos(u8, help_z, pos, '\n') orelse help_z.len;
        const line = help_z[pos..end :0];
        raylib.drawText(line, 40, y, 18, t.display_text);
        y += line_h;
        pos = end;
        if (pos < help_z.len) pos += 1;
        if (y > @as(i32, @intFromFloat(sh)) - 50) break;
    }
}

pub fn drawStatusBar(t: *const theme_mod.Theme, lang: i18n.Language, is_dark: bool) void {
    const sw: f32 = @floatFromInt(raylib.getScreenWidth());
    const bar_h: f32 = 30;
    const bar_y: f32 = @as(f32, @floatFromInt(raylib.getScreenHeight())) - bar_h;

    raylib.drawRectangle(0, @intFromFloat(bar_y), @intFromFloat(sw), @intFromFloat(bar_h), t.status_bar_bg);

    const lang_name = i18n.langName(lang);
    const theme_name = if (is_dark) "Dark" else "Light";
    var sbuf: [128]u8 = undefined;
    const buf = std.fmt.bufPrintZ(&sbuf, "Calctron | {s} | {s}", .{ lang_name, theme_name }) catch return;

    raylib.drawText(buf, 10, @as(i32, @intFromFloat(bar_y)) + 8, 12, t.status_bar_text);
}
