const std = @import("std");
const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");

// ----- set focus to the next sibling -----
pub fn SetNextFocus() void {
    if (Window.inFocus) |focus| {
        var win1:?*Window = focus;
	var pwnd:df.WINDOW = null;
	var pwin:?*Window = null;
        while (true) {
            if (win1) |w| {
                pwnd = Window.GetParent(w.win);
                if (Window.get_zin(pwnd)) |p| {
                    pwin = p;
                }
            }
            if ((win1 != null) and (win1.?.nextWindow() != null)) {
                win1 = win1.?.nextWindow();
            } else if (pwin) |pw| {
                win1 = pw.firstWindow();
            }
            if (win1 == null or win1 == focus) {
                win1 = pwin;
                break;
            }
            if (win1) |w| {
                if (df.GetClass(w.win) == df.STATUSBAR or df.GetClass(w.win) == df.MENUBAR) {
                    continue;
                }
                // isVisible is true when win is null in original code.
                // not sure it is correct behavior
                if (df.isVisible(w.win)>0) {
                    break;
                }
            }
        }
        if (win1) |w| {
            var ww1:*Window = w;
            while (ww1.*.childfocus) |w1| {
                ww1 = w1;
            }
            if (ww1.win.*.condition != df.ISCLOSING) {
                _ = ww1.sendMessage(df.SETFOCUS, df.TRUE, 0);
            }
        }
    }
}

// ----- set focus to the previous sibling -----
pub fn SetPrevFocus() void {
    if (Window.inFocus) |focus| {
        var win1:?*Window = focus;
	var pwnd:df.WINDOW = null;
	var pwin:?*Window = null;
        while (true) {
            if (win1) |w| {
                pwnd = Window.GetParent(w.win);
                if (Window.get_zin(pwnd)) |p| {
                    pwin = p;
                }
            }
            if ((win1 != null) and (win1.?.prevWindow() != null)) {
                win1 = win1.?.prevWindow();
            } else if (pwin) |pw| {
                win1 = pw.lastWindow();
            }
            if (win1 == null or win1 == focus) {
                win1 = pwin;
                break;
            }
            if (win1) |w| {
                if (df.GetClass(w.win) == df.STATUSBAR or df.GetClass(w.win) == df.MENUBAR) {
                    continue;
                }
                // isVisible is true when win is null in original code.
                // not sure it is correct behavior
                if (df.isVisible(w.win)>0) {
                    break;
                }
            }
        }
        if (win1) |w| {
            var ww1:*Window = w;
            while (ww1.*.childfocus) |w1| {
                ww1 = w1;
            }
            if (ww1.win.*.condition != df.ISCLOSING) {
                _ = ww1.sendMessage(df.SETFOCUS, df.TRUE, 0);
            }
        }
    }
}

// ------- move a window to the end of its parents list -----
pub fn ReFocus(win:*Window) void {
    const wnd = win.win;
    if (df.GetParent(wnd) != null) {
        RemoveWindow(win);
        AppendWindow(win);
        const pwnd = df.GetParent(wnd);
        if (Window.get_zin(pwnd)) |pwin| {
            ReFocus(pwin);
        }
    }
}

// ---- remove a window from the linked list ----
pub fn RemoveWindow(win:?*Window) void {
    if (win) |w| {
        const wnd = w.win;
        const pwnd = df.GetParent(wnd);
        if (w.prevWindow()) |pw| {
            pw.*.nextsibling = w.nextWindow();
        }
        if (w.nextWindow()) |nw| {
            nw.*.prevsibling = w.prevWindow();
        }
        if (Window.get_zin(pwnd)) |pwin| { // pwnd != null
            if (w == pwin.firstWindow()) {
                pwin.*.firstchild = w.nextWindow();
            }
            if (w == pwin.lastWindow()) {
                pwin.*.lastchild = w.prevWindow();
            }
        }
    }
}

// ---- append a window to the linked list ----
pub fn AppendWindow(win:?*Window) void {
    if (win) |w| {
        const wnd = w.win;
        const pwnd = df.GetParent(wnd);
        if (Window.get_zin(pwnd)) |pwin| { // pwnd != null
            if (pwin.firstWindow() == null) {
                pwin.*.firstchild = w;
            }
            if (pwin.lastWindow()) |lw| {
                lw.*.nextsibling = w;
            }
            w.*.prevsibling = pwin.lastWindow();
            pwin.*.lastchild = w;
        }
        w.*.nextsibling = null;
    }
}

// ----- if document windows and statusbar or menubar get the focus,
//              pass it on -------
pub fn SkipApplicationControls() void {
    var EmptyAppl = false;
    var ct:isize = 0;
    while (!EmptyAppl and (Window.inFocus != null))	{
        const cl = df.GetClass(Window.inFocusWnd());
        if (cl == df.MENUBAR or cl == df.STATUSBAR) {
	    SetPrevFocus();
            EmptyAppl = ((cl == df.MENUBAR) and (ct > 0));
	    ct += 1;
        } else {
            break;
        }
    }
}
