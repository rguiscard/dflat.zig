const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const rect = @import("Rect.zig");

pub export fn CharInView(wnd:df.WINDOW, x:c_int, y:c_int) callconv(.c) df.BOOL {
    if (Window.get_zin(wnd)) |win| {
        const x1:c_int = @intCast(win.GetLeft()+x);
        const y1:c_int = @intCast(win.GetTop()+y);

        if (win.TestAttribute(df.VISIBLE) == false)
            return df.FALSE;

        if (win.TestAttribute(df.NOCLIP) == false) {
            var wnd1 = df.GetParent(wnd);
            while (wnd1 != null) {
                if (Window.get_zin(wnd1)) |win1| {
                    // --- clip character to parent's borders --
                    if (win1.TestAttribute(df.VISIBLE) == false)
                        return df.FALSE;
                    if (rect.InsideRect(x1, y1, rect.ClientRect(win1)) == false)
                        return df.FALSE;
                }
                wnd1 = df.GetParent(wnd1);
            }
        }

        var nwin = win.nextWindow();
        while (nwin) |nw| {
            if (nw.isHidden() == false) { //  && !isAncestor(wnd, nwnd)
                var rc = nw.WindowRect();
                if (nw.TestAttribute(df.SHADOW)) {
                    rc.bt += 1;
                    rc.rt += 1;
                }
                if (nw.TestAttribute(df.NOCLIP) == false) {
                    var pwnd = nw.win;
                    while (df.GetParent(pwnd) != null) {
                        pwnd = df.GetParent(pwnd);
                        if (Window.get_zin(pwnd)) |pwin| {
                            rc = df.subRectangle(rc, rect.ClientRect(pwin));
                        }
                    }
                }
                if (rect.InsideRect(x1,y1,rc))
                    return df.FALSE;
            }
             nwin = nw.nextWindow();
        }
        return if ((x1 < df.SCREENWIDTH and y1 < df.SCREENHEIGHT)) df.TRUE else df.FALSE;
    }
    return df.FALSE;
}
