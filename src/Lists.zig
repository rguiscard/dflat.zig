const std = @import("std");
const df = @import("ImportC.zig").df;
const k = @import("Classes.zig").CLASS;
const Window = @import("Window.zig");

// ----- set focus to the next sibling -----
pub fn SetNextFocus() void {
    if (Window.inFocus) |focus| {
        var win1:?*Window = focus;
	var pwin:?*Window = null;
        while (true) {
            if (win1) |w| {
                pwin = w.parent;
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
                if (w.getClass() == k.STATUSBAR or w.getClass() == k.MENUBAR) {
                    continue;
                }
                // isVisible is true when win is null in original code.
                // not sure it is correct behavior
                if (w.isVisible()) {
                    break;
                }
            }
        }
        if (win1) |w| {
            var ww1:*Window = w;
            while (ww1.childfocus) |w1| {
                ww1 = w1;
            }
            if (ww1.condition != .ISCLOSING) {
                _ = ww1.sendMessage(df.SETFOCUS, .{.yes=true});
            }
        }
    }
}

// ----- set focus to the previous sibling -----
pub fn SetPrevFocus() void {
    if (Window.inFocus) |focus| {
        var win1:?*Window = focus;
	var pwin:?*Window = null;
        while (true) {
            if (win1) |w| {
                pwin = w.parent;
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
                if (w.getClass() == k.STATUSBAR or w.getClass() == k.MENUBAR) {
                    continue;
                }
                // isVisible is true when win is null in original code.
                // not sure it is correct behavior
                if (w.isVisible()) {
                    break;
                }
            }
        }
        if (win1) |w| {
            var ww1:*Window = w;
            while (ww1.childfocus) |w1| {
                ww1 = w1;
            }
            if (ww1.condition != .ISCLOSING) {
                _ = ww1.sendMessage(df.SETFOCUS, .{.yes=true});
            }
        }
    }
}

// ------- move a window to the end of its parents list -----
pub fn ReFocus(win:*Window) void {
    if (win.parent) |pw| {
        RemoveWindow(win);
        AppendWindow(win);
        ReFocus(pw);
    }
}

// ---- remove a window from the linked list ----
pub fn RemoveWindow(win:?*Window) void {
    if (win) |w| {
        if (w.prevWindow()) |pw| {
            pw.nextsibling = w.nextWindow();
        }
        if (w.nextWindow()) |nw| {
            nw.prevsibling = w.prevWindow();
        }
        if (w.parent) |pwin| {
            if (w == pwin.firstWindow()) {
                pwin.firstchild = w.nextWindow();
            }
            if (w == pwin.lastWindow()) {
                pwin.lastchild = w.prevWindow();
            }
        }
    }
}

// ---- append a window to the linked list ----
pub fn AppendWindow(win:?*Window) void {
    if (win) |w| {
        if (w.parent) |pwin| {
            if (pwin.firstWindow() == null) {
                pwin.firstchild = w;
            }
            if (pwin.lastWindow()) |lw| {
                lw.nextsibling = w;
            }
            w.prevsibling = pwin.lastWindow();
            pwin.lastchild = w;
        }
        w.nextsibling = null;
    }
}

// ----- if document windows and statusbar or menubar get the focus,
//              pass it on -------
pub fn SkipApplicationControls() void {
    var EmptyAppl = false;
    var ct:isize = 0;
    while (!EmptyAppl and (Window.inFocus != null))	{
        const cl = Window.inFocus.?.getClass();
        if (cl == k.MENUBAR or cl == k.STATUSBAR) {
	    SetPrevFocus();
            EmptyAppl = ((cl == k.MENUBAR) and (ct > 0));
	    ct += 1;
        } else {
            break;
        }
    }
}
