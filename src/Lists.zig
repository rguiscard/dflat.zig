const std = @import("std");
const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");

// temperory function for porting
fn set_first_window(wnd:df.WINDOW, child:df.WINDOW) void {
    if (Window.get_zin(wnd)) |zin| {
        if (Window.get_zin(child)) |cin| {
            zin.firstchild = cin;
        } else {
            zin.firstchild = null;
        }
    }
}

fn set_last_window(wnd:df.WINDOW, child:df.WINDOW) void {
    if (Window.get_zin(wnd)) |zin| {
        if (Window.get_zin(child)) |cin| {
            zin.lastchild = cin;
        } else {
            zin.lastchild = null;
        }
    }
}

fn set_next_window(wnd:df.WINDOW, child:df.WINDOW) void {
    if (Window.get_zin(wnd)) |zin| {
        if (Window.get_zin(child)) |cin| {
            zin.nextsibling = cin;
        } else {
            zin.nextsibling = null;
        }
    }
}

fn set_prev_window(wnd:df.WINDOW, child:df.WINDOW) void {
    if (Window.get_zin(wnd)) |zin| {
        if (Window.get_zin(child)) |cin| {
            zin.prevsibling = cin;
        } else {
            zin.prevsibling = null;
        }
    }
}

// ----- set focus to the next sibling -----
pub fn SetNextFocus() void {
    if (df.inFocus != null)    {
        var wnd1 = df.inFocus;
	var pwnd:df.WINDOW = null;
        while (true) {
            pwnd = df.GetParent(wnd1);
            if (Window.NextWindow(wnd1) != null) {
                wnd1 = Window.NextWindow(wnd1);
            } else if (pwnd != null) {
                wnd1 = Window.FirstWindow(pwnd);
            }
            if (wnd1 == null or wnd1 == df.inFocus) {
                wnd1 = pwnd;
                break;
            }
            if (df.GetClass(wnd1) == df.STATUSBAR or df.GetClass(wnd1) == df.MENUBAR) {
                continue;
            }
            if (df.isVisible(wnd1)>0) {
                break;
            }
        }
        if (wnd1 != null) {
//            while (wnd1.*.childfocus != null) {
//                wnd1 = wnd1.*.childfocus;
//            }
            var win1:*Window = Window.get_zin(wnd1).?;
            while (win1.*.childfocus) |w1| {
                win1 = w1;
                wnd1 = w1.win;
            }
            if (wnd1.*.condition != df.ISCLOSING) {
                _ = df.SendMessage(wnd1, df.SETFOCUS, df.TRUE, 0);
            }
        }
    }
}

// ----- set focus to the previous sibling -----
pub fn SetPrevFocus() void {
    if (df.inFocus != null) {
        var wnd1 = df.inFocus;
	var pwnd:df.WINDOW = null;
        while (true) {
            pwnd = df.GetParent(wnd1);
            if (Window.PrevWindow(wnd1) != null) {
                wnd1 = Window.PrevWindow(wnd1);
            } else if (pwnd != null) {
                wnd1 = Window.LastWindow(pwnd);
            }
            if (wnd1 == null or wnd1 == df.inFocus) {
                wnd1 = pwnd;
                break;
            }
            if (df.GetClass(wnd1) == df.STATUSBAR) {
                continue;
            }
            if (df.isVisible(wnd1)>0) {
                break;
            }
        }
        if (wnd1 != null) {
//            while (wnd1.*.childfocus != null) {
//                wnd1 = wnd1.*.childfocus;
//            }
            var win1:*Window = Window.get_zin(wnd1).?;
            while (win1.*.childfocus) |w1| {
                win1 = w1;
                wnd1 = w1.win;
            }
            if (wnd1.*.condition != df.ISCLOSING) {
                _ = df.SendMessage(wnd1, df.SETFOCUS, df.TRUE, 0);
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
    while (!EmptyAppl and (df.inFocus != null))	{
        const cl = df.GetClass(df.inFocus);
        if (cl == df.MENUBAR or cl == df.STATUSBAR) {
	    SetPrevFocus();
            EmptyAppl = ((cl == df.MENUBAR) and (ct > 0));
	    ct += 1;
        } else {
            break;
        }
    }
}
