const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const colors = @import("Colors.zig");
const Window = @import("Window.zig");
const mouse = @import("Mouse.zig");
const video = @import("Video.zig");

//static int near cursorpos[MAXSAVES];
//static int near cursorshape[MAXSAVES];
//static int cs;

//var cx:c_int = -1;
//var cy:c_int = -1;

pub fn cursor(x:usize, y:usize) void {
    df.cx = @intCast(x);
    df.cy = @intCast(y);
}

pub fn curr_cursor(x:*usize, y:*usize) void {
    x.* = @as(usize, @intCast(df.cx));
    y.* = @as(usize, @intCast(df.cy));
}

pub fn hidecursor() void {
    df.cy = -1;
}

pub fn unhidecursor() void {
}

pub fn savecursor() void {
//    if (cs < MAXSAVES)    {
//        //getcursor();
//        //cursorshape[cs] = regs.x.cx;
//        //cursorpos[cs] = regs.x.dx;
//        cs++;
//    }
}

pub fn restorecursor() void {
//#if 0
//    if (cs)    {
//        --cs;
//        //videomode();
//        //regs.x.dx = cursorpos[cs];
//        //regs.h.ah = SETCURSOR;
//        //regs.x.bx = video_page;
//        //int86(VIDEO, &regs, &regs);
//        //set_cursor_type(cursorshape[cs]);
//    }
}

pub fn normalcursor() void {
}

pub fn set_cursor_type(t:c_uint) void {
    _ = t;
}

// clear line y from x1 up to and including x2 to attribute attr
fn clear_line(x1:c_int, x2:c_int, y:c_int, attr:c_int) void {
    const va16_ptr:[*]u16 = @ptrCast(@alignCast(df.video_address));
    for (@intCast(x1)..@intCast(x2+1)) |x| {
        const offset:usize = @as(usize, @intCast(y)) * video.SCREENWIDTH + x;
        const c:[*]u16 = va16_ptr+offset;
        c[0] = @intCast(' ' | (attr << 8));
    }

//    for (x = x1; x <= x2; x++) {
//        *(unsigned short *)&video_address[(y * SCREENWIDTH + x) * 2] = ' ' | (attr << 8);
//    }
}

// scroll video RAM up from line y1 up to and including line y2
fn scrollup(y1:c_int, x1:c_int, y2:c_int, x2:c_int, attr:c_int) void {
    const pitch:c_int = @intCast(video.SCREENWIDTH * 2);
    const width = (x2 - x1 + 1) * 2;
//    unsigned char *vid = video_address + y1 * pitch + x1 * 2;
    var y = y1;

    while (y < y2) {
        const vid = y * pitch + x1 * 2;
        const begin:usize = @intCast(vid);
        const end:usize = @intCast(vid+width);
        const shift:usize = @intCast(pitch);
        @memcpy (df.video_address[begin..end], df.video_address[begin+shift..end+shift]);
        y += 1;
    }
    clear_line (x1, x2, y2, attr);
}

// scroll video RAM down from line y1 up to and including line y2
fn scrolldn(y1:c_int, x1:c_int, y2:c_int, x2:c_int, attr:c_int) void {
    const pitch:c_int = @intCast(video.SCREENWIDTH * 2);
    const width = (x2 - x1 + 1) * 2;
//    var vid = y2 * pitch + x1 * 2;
    var y = y2;

    while (y > y1) {
        const vid = y * pitch + x1 * 2;
        const begin:usize = @intCast(vid);
        const end:usize = @intCast(vid+width);
        const shift:usize = @intCast(pitch);
        @memcpy (df.video_address[begin..end], df.video_address[begin-shift..end-shift]);
        y -= 1;
    }
    clear_line (x1, x2, y1, attr);
}

fn scroll_video(up:c_int, n:c_int, at:c_int, y1:c_int, x1:c_int, y2:c_int, x2:c_int) void {
    if (n == 0 or n >= video.SCREENHEIGHT) {
        clear_line(x1, x2, y1, at);
    } else if (y1 != y2) {
        var nn = n;
        while (nn > 0) {
            if (up>0) {
                scrollup(y1, x1, y2, x2, at);
            } else {
                scrolldn(y1, x1, y2, x2, at);
            }
            nn -= 1;
        }
    }
}

// --------- scroll the window. d: 1 = up, 0 = dn ----------
pub fn scroll_window(win:*Window, rc:df.RECT, d:c_int) void {
    if (rc.tp != rc.bt) {
        mouse.hide_mousecursor();
//        scroll_video(d, 1, colors.WndForeground(win) | (colors.WndBackground(win) << 4),
//                     rc.tp, rc.lf, rc.bt, rc.rt);
        scroll_video(d, 1, video.clr(colors.WndForeground(win), colors.WndBackground(win)),
                     rc.tp, rc.lf, rc.bt, rc.rt);
        mouse.show_mousecursor();
    }
}

pub fn SwapCursorStack() void {
//    if (cs > 1) {
//        swap(cursorpos[cs-2], cursorpos[cs-1]);
//        swap(cursorshape[cs-2], cursorshape[cs-1]);
//    }
}

pub fn AltConvert(c:u16) c_int {
    if (c >= df.kAltA and c <= df.kAltZ)
        return @as(c_int, @intCast(c)) - df.kAltA + 'a';
    if (c >= df.kAlt0 and c <= df.kAlt9)
        return @as(c_int, @intCast(c)) - df.kAlt0 + '0';
    return c;
}

// only called from AllocationError, wait on keyboard read to exit
pub export fn getkey() c_int {
    var buf = [_]u8{0}**32;

    df.convert_screen_to_ansi();
    while(true) {
        const n = df.readansi(0, &buf, 32);
        if (n < 0)
            break;
        const e = df.ansi_to_unikey(&buf, n);
        if (e != -1)
            return e;
        // not keystroke, ignore mouse
    }
    return -1;
}

pub fn waitformouse() void {
    var mx:c_int = 0;
    var my:c_int = 0;
    var modkeys:c_int = 0;
    var e:c_int = 0;

    var buf = [_]u8{0}**32;

    if (df.mouse_button != df.kMouseLeftDown and df.mouse_button != df.kMouseLeftDoubleClick)
        return;
    while(true) {
        var n = df.readansi(0, &buf, 32);
        if (n < 0)
            break;

        n = df.ansi_to_unimouse(&buf, n, &mx, &my, &modkeys, &e);
        if (n != -1) {
            if (n == df.kMouseLeftUp)
                return;
        }
        // ignore keystrokes
    }
}

// ---------- read the keyboard shift status ---------
pub fn getshift() c_int {
    return 0;
}

pub fn beep() void {
}
