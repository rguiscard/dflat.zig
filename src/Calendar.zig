const std = @import("std");
const df = @import("ImportC.zig").df;
const c = @import("Commands.zig").Command;
const k = @import("Classes.zig").CLASS;
const root = @import("root.zig");
const Window = @import("Window.zig");
const pict = @import("PictureBox.zig");
const helpbox = @import("HelpBox.zig");
const q = @import("Message.zig");

const ctime = @cImport({
    @cInclude("time.h");
});

const CALHEIGHT = 17;
const CALWIDTH = 33;

var DyMo = [_]isize{31,28,31,30,31,30,31,31,30,31,30,31};
var ttm:ctime.tm = undefined;
var dys: [42]isize = .{0} ** 42;
var Cwnd:?*Window = null;

fn FixDate() void {
    // ---- adjust Feb for leap year ----
    DyMo[1] = if (@rem(ttm.tm_year, 4) > 0) 28 else 29;
    ttm.tm_mday = @intCast(@min(ttm.tm_mday, DyMo[@intCast(ttm.tm_mon)]));
}

// ---- build calendar dates array ----
fn BuildDateArray() void {
    var offset:isize = 0;
    FixDate();
    // ----- compute the weekday for the 1st -----
    offset = @rem(((ttm.tm_mday-1) - ttm.tm_wday), 7);
    if (offset < 0)
        offset += 7;
    if (offset > 0)
        offset = (offset - 7) * -1;
    // ----- build the dates into the array ----
    for (0..@intCast(DyMo[@intCast(ttm.tm_mon)])) |dy| {
        dys[@intCast(offset)] = @intCast(dy+1);
        offset += 1;
    }
}

fn CreateWindowMsg(win:*Window) void {
    var x:isize = 5;
    var y:isize = 4;
    pict.DrawBox(win, 1, 2, CALHEIGHT-4, CALWIDTH-4);
    while(x < CALWIDTH-4) : (x += 4) {
        pict.DrawVector(win, @intCast(x), 2, CALHEIGHT-4, df.FALSE);
    }
    while(y < CALHEIGHT-3) : (y += 2) {
        pict.DrawVector(win, 1, @intCast(y), CALWIDTH-4, df.TRUE);
    }
}

// remove requirement for strftime()
const months = [_][]const u8{
    "January", "February", "March", "April", "May", "June", "July",
    "August", "September", "October", "November", "December"
};

fn DisplayDates(win:*Window) void {
    const wnd = win.win;
    var dyln:[10]u8 = .{0} ** 10;
//    int offset;
//    char banner[CALWIDTH-1];
    var banner:[CALWIDTH-1]u8 = undefined;
    var banner1:[30]u8 = undefined;

    df.SetStandardColor(wnd);
    const weeks = "Sun Mon Tue Wed Thu Fri Sat";
    df.PutWindowLine(wnd, @constCast(@ptrCast(weeks.ptr)), 2, 1);
    @memset(&banner, '-');
    @memset(&banner1, 0);
    if (std.fmt.bufPrint(&banner1, "{s} {d}", .{months[@intCast(ttm.tm_mon)], ttm.tm_year+1900})) |_| {
    } else |_| { // err
    }
    const b = std.mem.sliceTo(&banner1, 0);
    if (std.fmt.bufPrint(&banner, "{s: ^32}", .{b})) |_| {
        // FIXME: currently use hardcoded 32. Should use CALWIDTH.
    } else |_| { // err
    }
//    sprintf(banner1, "%s %d", months[ttm.tm_mon], ttm.tm_year+1900);
//    offset = (CALWIDTH-2 - strlen(banner1)) / 2;
//    strcpy(banner+offset, banner1);
//    strcat(banner, "    ");
    df.PutWindowLine(wnd, @constCast(@ptrCast(&banner)), 0, 0);
    BuildDateArray();
    for (0..6) |week| {
        for (0..7) |day| {
            const dy = dys[week*7+day];
            if (dy == 0) {
                if (std.fmt.bufPrint(&dyln, "   ", .{})) |_| {
                } else |_| { // err
                }
            } else {
//                if (dy == ttm.tm_mday)
//                    sprintf(dyln, "%c%c%c%2d %c",
//                        CHANGECOLOR,
//                        SelectForeground(wnd)+0x80,
//                        SelectBackground(wnd)+0x80,
//                        dy, RESETCOLOR);
//                else
                if (std.fmt.bufPrint(&dyln, "{d}", .{dy})) |_| {
                } else |_| { // err
                }
            }
            df.SetStandardColor(wnd);
            df.PutWindowLine(wnd, @constCast(@ptrCast(&dyln)), @intCast(2 + day * 4), @intCast(3 + week*2));
        }
    }
}

//static int KeyboardMsg(WINDOW wnd, PARAM p1)
//{
//    switch ((int)p1)    {
//        case BS:
//        case UP:
//        case PGUP:
//            if (ttm.tm_mon == 0)    {
//                ttm.tm_mon = 12;
//                ttm.tm_year--;
//            }
//            ttm.tm_mon--;
//            FixDate();
//            mktime(&ttm);
//            DisplayDates(wnd);
//            return TRUE;
//        case FWD:
//        case DN:
//        case PGDN:
//            ttm.tm_mon++;
//            if (ttm.tm_mon == 12)    {
//                ttm.tm_mon = 0;
//                ttm.tm_year++;
//            }
//            FixDate();
//            mktime(&ttm);
//            DisplayDates(wnd);
//            return TRUE;
//        default:
//            break;
//    }
//    return FALSE;
//}


pub fn CalendarProc(win:*Window, msg: df.MESSAGE, params:q.Params) bool {
    const p1 = params.legacy[0];
    switch (msg) {
        df.CREATE_WINDOW => {
            _ = root.DefaultWndProc(win, msg, params);
            CreateWindowMsg(win);
            return true;
        },
        df.KEYBOARD => {
//            if (KeyboardMsg(wnd, p1))
//                return true;
        },
        df.PAINT => {
            _ = root.DefaultWndProc(win, msg, params);
            DisplayDates(win);
            return true;
        },
        df.COMMAND => {
            const cmd:c = @enumFromInt(p1);
            if (cmd == c.ID_HELP) {
                _ = helpbox.DisplayHelp(win, "Calendar");
                return true;
            }
        },
        df.CLOSE_WINDOW => {
            Cwnd = null;
        },
        else => {
        }
    }
    return root.DefaultWndProc(win, msg, params);
}

pub fn Calendar(pwin: *Window) void {
    if (Cwnd == null)    {
        const tim = ctime.time(null);
        ttm = ctime.localtime(&tim).*;
        Cwnd = Window.create(k.PICTUREBOX,
            "Calendar",
            -1, -1, CALHEIGHT, CALWIDTH,
            null, pwin, CalendarProc,
            df.SHADOW     |
            df.MINMAXBOX  |
            df.CONTROLBOX |
            df.MOVEABLE   |
            df.HASBORDER
        );
    }
    if (Cwnd) |cc| {
        var win = cc;
        _ = win.sendMessage(df.SETFOCUS, .{.legacy=.{df.TRUE, 0}});
    }
}
