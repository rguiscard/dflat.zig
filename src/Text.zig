const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");

fn drawText(win:*Window) void {
    const wnd = win.win;
    const ct = df.GetControl(wnd);
    if (ct == null)
        return;
    if ((ct.*.itext == null) or (wnd.*.text != null))
        return;

    const height:usize = @intCast(ct.*.dwnd.h);
    var idx:usize = 0;

    const ptr = @as([*:0]u8, ct.*.itext);
    const content = std.mem.span(ptr);
    var iter = std.mem.splitScalar(u8, content, '\n');
    while (iter.next()) |line| {
        _ = win.sendTextMessage(df.ADDTEXT, @constCast(line), 0);
        if (idx >= height)
            break;
        idx += 1;
    }

    // original code check shortcut in text. not sure why ?
    //
    //          mlen = strlen(cp);
    //          printf("mlen %d\n", mlen);
    //          while ((cp1=strchr(cp1,SHORTCUTCHAR)) != NULL) {
    //              mlen += 3;
    //              cp1++;
    //          }
    //          ...
    //          txt = DFmalloc(mlen+1);
    //          CopyCommand(txt, cp, FALSE, WndBackground(wnd));
    //          txt[mlen] = '\0';

}

pub fn TextProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    switch (msg)    {
        df.SETFOCUS => {
            return true;
        },
        df.LEFT_BUTTON => {
            return true;
        },
        df.PAINT => {
            drawText(win);
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.TEXT, win, msg, p1, p2);
}
