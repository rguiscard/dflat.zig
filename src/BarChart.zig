const std = @import("std");
const df = @import("ImportC.zig").df;
const c = @import("Commands.zig").Command;
const k = @import("Classes.zig").CLASS;
const q = @import("Message.zig");
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

fn BarChartProc(win:*Window, message: df.MESSAGE, params:q.Params) bool {
    switch (message) {
        df.COMMAND => {
            const p1 = params.legacy[0];
            const cmd:c = @enumFromInt(p1);
            if (cmd == c.ID_HELP) {
                _ = helpbox.DisplayHelp(win, "BarChart");
                return true;
            }
        },
        df.CLOSE_WINDOW => {
            Bwnd = null;
        },
        else => {
        }
    }
    return root.DefaultWndProc(win, message, params);
}

pub fn BarChart(pwin: *Window) void {
    const pct = ProjChart.len;

    if (Bwnd == null) {
        Bwnd = Window.create(k.PICTUREBOX,
                    "BarChart",
                    -1, -1, BCHEIGHT, BCWIDTH,
                    null, pwin, BarChartProc,
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
                const sel:usize = 1+(i%4);
                pict.DrawBar(win, @enumFromInt(sel),
                           @intCast(11 + proj[1] * COLWIDTH), @intCast(2+i),
                           @intCast((1 + proj[2]-proj[1]) * COLWIDTH),
                           df.TRUE);
            }
            _ = win.sendTextMessage(df.ADDTEXT, "", 0);
            _ = win.sendTextMessage(df.ADDTEXT, @constCast(Months), 0);
            pict.DrawBox(win, 10, 1, pct+2, 25);
        }
    }
    if (Bwnd) |w| {
        var win = w;
        _ = win.sendMessage(df.SETFOCUS, .{.legacy=.{df.TRUE, 0}});
    }
}
