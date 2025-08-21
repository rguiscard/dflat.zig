const std = @import("std");
const df = @import("ImportC.zig").df;

// ----- set focus to the next sibling -----
pub export fn SetNextFocus() callconv(.c) void {
    if (df.inFocus != null)    {
        var wnd1 = df.inFocus;
	var pwnd:df.WINDOW = null;
        while (true) {
            pwnd = df.GetParent(wnd1);
            if (wnd1.*.nextsibling != null) {
                wnd1 = wnd1.*.nextsibling;
            } else if (pwnd != null) {
                wnd1 = pwnd.*.firstchild;
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
            while (wnd1.*.childfocus != null) {
                wnd1 = wnd1.*.childfocus;
            }
            if (wnd1.*.condition != df.ISCLOSING) {
                _ = df.SendMessage(wnd1, df.SETFOCUS, df.TRUE, 0);
            }
        }
    }
}

// ----- set focus to the previous sibling -----
pub export fn SetPrevFocus() callconv(.c) void {
    if (df.inFocus != null) {
        var wnd1 = df.inFocus;
	var pwnd:df.WINDOW = null;
        while (true) {
            pwnd = df.GetParent(wnd1);
            if (wnd1.*.prevsibling != null) {
                wnd1 = wnd1.*.prevsibling;
            } else if (pwnd != null) {
                wnd1 = pwnd.*.lastchild;
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
            while (wnd1.*.childfocus != null) {
                wnd1 = wnd1.*.childfocus;
            }
            if (wnd1.*.condition != df.ISCLOSING) {
                _ = df.SendMessage(wnd1, df.SETFOCUS, df.TRUE, 0);
            }
        }
    }
}

// ------- move a window to the end of its parents list -----
pub export fn ReFocus(wnd:df.WINDOW) callconv(.c) void {
	if (df.GetParent(wnd) != null)	{
		RemoveWindow(wnd);
		AppendWindow(wnd);
		ReFocus(df.GetParent(wnd));
	}
}

// ---- remove a window from the linked list ----
pub export fn RemoveWindow(wnd:df.WINDOW) callconv(.c) void {
    if (wnd != null)    {
        const pwnd = df.GetParent(wnd);
        if (wnd.*.prevsibling != null) {
            const pw = wnd.*.prevsibling;
	    pw.*.nextsibling = wnd.*.nextsibling;
        }
        if (wnd.*.nextsibling != null) {
            const nw = wnd.*.nextsibling;
	    nw.*.prevsibling = wnd.*.prevsibling;
        }
        if (pwnd != null) {
            if (wnd == pwnd.*.firstchild) {
		pwnd.*.firstchild = wnd.*.nextsibling;
            }
            if (wnd == pwnd.*.lastchild) {
		pwnd.*.lastchild = wnd.*.prevsibling;
            }
        }
    }
}

// ---- append a window to the linked list ----
pub export fn AppendWindow(wnd:df.WINDOW) callconv(.c) void {
    if (wnd != null) {
        const pwnd = df.GetParent(wnd);
        if (pwnd != null) {
            if (pwnd.*.firstchild == null) {
            	pwnd.*.firstchild = wnd;
            }
            if (pwnd.*.lastchild != null) {
                const lw = pwnd.*.lastchild;
		lw.*.nextsibling = wnd;
            }
            wnd.*.prevsibling = pwnd.*.lastchild;
	    pwnd.*.lastchild = wnd;
        }
	wnd.*.nextsibling = null;
    }
}

// ----- if document windows and statusbar or menubar get the focus,
//              pass it on -------
pub export fn SkipApplicationControls() callconv(.c) void {
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
