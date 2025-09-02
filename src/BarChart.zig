const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const pict = @import("PictureBox.zig");
const helpbox = @import("HelpBox.zig");

const BCHEIGHT = 12;
const BCWIDTH = 44;
const COLWIDTH = 4;

var Bwnd:?*Window = null;

// ------- project schedule array -------
const ProjChart = [_]struct{[]const u8, isize, isize} {
    .{"Center St", 0, 3},
    .{"City Hall", 0, 5},
    .{"Rt 395   ", 1, 4},
    .{"Sky Condo", 2, 3},
    .{"Out Hs   ", 0, 4},
    .{"Bk Palace", 1, 5},
};

const Title =  "              PROJECT SCHEDULE";
const Months = "           Jan Feb Mar Apr May Jun";

fn BarChartProc(win:*Window, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message) {
        df.COMMAND => {
            if (p1 == df.ID_HELP) {
                _ = helpbox.DisplayHelp(win, "BarChart");
                return df.TRUE;
            }
        },
        df.CLOSE_WINDOW => {
            Bwnd = null;
        },
        else => {
        }
    }
    return root.zDefaultWndProc(win, message, p1, p2);
}

pub export fn BarChart(pwin: *Window) void {
    const pwnd = pwin.win;
    const pct = ProjChart.len;

    if (Bwnd == null) {
        Bwnd = Window.create(df.PICTUREBOX,
                    "BarChart",
                    -1, -1, BCHEIGHT, BCWIDTH,
                    null, pwnd, BarChartProc,
                    df.SHADOW     |
                    df.CONTROLBOX |
                    df.MOVEABLE   |
                    df.HASBORDER
        );
        if (Bwnd) |w| {
            var win = w;
            _ = win.sendTextMessage(df.ADDTEXT, @constCast(Title), 0);
            _ = win.sendTextMessage(df.ADDTEXT, "", 0);
            for(ProjChart, 0..) |proj, i| {
                _ = win.sendTextMessage(df.ADDTEXT, @constCast(proj[0]), 0);
                pict.DrawBar(win.win, @intCast(df.SOLIDBAR+(i%4)),
                           @intCast(11 + proj[1] * COLWIDTH), @intCast(2+i),
                           @intCast((1 + proj[2]-proj[1]) * COLWIDTH),
                           df.TRUE);
            }
            _ = win.sendTextMessage(df.ADDTEXT, "", 0);
            _ = win.sendTextMessage(df.ADDTEXT, @constCast(Months), 0);
            pict.DrawBox(win.win, 10, 1, pct+2, 25);
        }
    }
    if (Bwnd) |w| {
        var win = w;
        _ = win.sendMessage(df.SETFOCUS, df.TRUE, 0);
    }
}
