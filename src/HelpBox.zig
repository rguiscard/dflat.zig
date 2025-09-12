const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const WndProc = @import("WndProc.zig");
const q = @import("Message.zig");
const lists = @import("Lists.zig");

//const MAXHEIGHT = df.SCREENHEIGHT-10;
const MAXHELPKEYWORDS = 50; // --- maximum keywords in a window ---
const MAXHELPSTACK = 100;

// ------------- CREATE_WINDOW message ------------
fn CreateWindowMsg(win:*Window) void {
    const wnd = win.win;
    df.Helping = df.TRUE;
    wnd.*.Class = df.HELPBOX;
    df.InitWindowColors(wnd);
    if (df.ThisHelp != null)
        df.ThisHelp.*.hwnd = wnd;
}

// -------- read the help text into the editbox -------
pub export fn ReadHelp(wnd:df.WINDOW) callconv(.c) void {
    const dbox:*Dialogs.DBOX = @ptrCast(@alignCast(wnd.*.extension));
    const cwnd = DialogBox.ControlWindow(dbox, df.ID_HELPTEXT);
    if (cwnd == null)
        return;
    if (Window.get_zin(cwnd)) |cwin| {
        cwin.wndproc = HelpTextProc;
    }
    _ = q.SendMessage(cwnd, df.CLEARTEXT, 0, 0);
    df.cReadHelp(wnd, cwnd);
}

// ------------- COMMAND message ------------
fn CommandMsg(win: *Window, p1:df.PARAM) bool {
    const wnd = win.win;
    switch (p1) {
        df.ID_PREV => {
            if (df.ThisHelp != null) {
                const prevhlp:usize = @intCast(df.ThisHelp.*.prevhlp);
                SelectHelp(wnd, df.FirstHelp+prevhlp, df.TRUE);
            }
            return true;
        },
        df.ID_NEXT => {
            if (df.ThisHelp != null) {
                const nexthlp:usize = @intCast(df.ThisHelp.*.nexthlp);
                SelectHelp(wnd, df.FirstHelp+nexthlp, df.TRUE);
            }
            return true;
        },
        df.ID_BACK => {
            if (df.stacked > 0) {
                df.stacked -= 1;
                const stacked:usize = @intCast(df.stacked);
                const helpstack:usize = @intCast(df.HelpStack[stacked]);
                SelectHelp(wnd, df.FirstHelp+helpstack, df.FALSE);
            }
            return true;
        },
        else => {
        }
    }
    return false;
}

fn HelpBoxKeyboardMsg(win: *Window, p1: df.PARAM) bool {
    const wnd = win.win;
    if (wnd.*.extension) |ext| {
        const dbox:*Dialogs.DBOX = @ptrCast(@alignCast(ext));
        const ctl_wnd = DialogBox.ControlWindow(dbox, df.ID_HELPTEXT);
        if (ctl_wnd) |cwnd| {
            if (df.inFocus == cwnd) {
                return if (df.cHelpBoxKeyboardMsg(wnd, cwnd, p1) == df.TRUE) true else false;
            }
        }
    }
    return false;
}

pub fn HelpBoxProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            CreateWindowMsg(win);
        },
        df.INITIATE_DIALOG => {
            ReadHelp(wnd);
        },
        df.COMMAND => {
            if (p2 == 0) {
                if (CommandMsg(win, p1))
                    return true;
            }
        },
        df.KEYBOARD => {
            if (df.WindowMoving == 0) {
                if (HelpBoxKeyboardMsg(win, p1))
                    return true;
            }
        },
        df.CLOSE_WINDOW => {
            if (df.ThisHelp != null)
                df.ThisHelp.*.hwnd = null;
            df.Helping = df.FALSE;
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.HELPBOX, win, msg, p1, p2);
}

// --- window processing module for HELPBOX's text EDITBOX --
pub fn HelpTextProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.KEYBOARD => {
        },
        df.PAINT => {
            return if (df.HelpTextPaintMsg(wnd, p1, p2) == df.TRUE) true else false;
        },
        df.LEFT_BUTTON => {
            return if (df.HelpTextLeftButtonMsg(wnd, p1, p2) == df.TRUE) true else false;
        },
        df.DOUBLE_CLICK => {
            q.PostMessage(wnd, df.KEYBOARD, '\r', 0);
        },
        else => {
        }
    }
    return root.zDefaultWndProc(win, msg, p1, p2);
}

// ---- strip tildes from the help name ----
fn StripTildes(input: []const u8, buffer: *[30]u8) []const u8 {
    const tilde = '~';
    var i: usize = 0;

    for (input) |c| {
        if (c != tilde) {
            buffer[i] = c;
            i += 1;
        }
    }
    return buffer[0..i];
}

// ---------- display help text -----------
pub fn DisplayHelp(win:*Window, Help:[]const u8) bool {
    const wnd = win.win;
    var buffer:[30]u8 = undefined;
    var rtn = false;

    @memset(&buffer, 0);

    if (df.Helping > 0)
        return true;

    const FixedHelp = StripTildes(Help, &buffer);

    wnd.*.isHelping += 1;
    df.ThisHelp = df.FindHelp(@constCast(FixedHelp.ptr));
    if (df.ThisHelp) |thisHelp| {
        _ = thisHelp;
        df.helpfp = df.OpenHelpFile(&df.HelpFileName, "rb");
        if (df.helpfp) |_| {
            BuildHelpBox(win);
            DialogBox.DisableButton(&Dialogs.HelpBox, df.ID_BACK);

            // ------- display the help window -----
            _ = DialogBox.create(null, &Dialogs.HelpBox, df.TRUE, HelpBoxProc);

//            df.free(Dialogs.HelpBox.dwnd.title);
            if (Dialogs.HelpBox.dwnd.title) |ttl| {
                root.global_allocator.free(ttl);
                Dialogs.HelpBox.dwnd.title = null;
            }
            _ = df.fclose(df.helpfp);
            df.helpfp = null;
            rtn = true;
        }
    }
    wnd.*.isHelping -= 1;
    return rtn;
}

fn BuildHelpBox(win:?*Window) void {
    const MAXHEIGHT = df.SCREENHEIGHT-10;

    // -- seek to the first line of the help text --
    df.SeekHelpLine(df.ThisHelp.*.hptr, df.ThisHelp.*.bit);

    // ----- read the title -----
    _ = df.GetHelpLine(&df.hline);
    const len:usize = df.strlen(&df.hline);
    df.hline[len-1] = 0;

    // FIXME: should replace with zig allocator
    if (Dialogs.HelpBox.dwnd.title) |ttl| {
        root.global_allocator.free(ttl);
        Dialogs.HelpBox.dwnd.title = null;
    }

    if (root.global_allocator.dupeZ(u8, df.hline[0..len])) |buf| {
        Dialogs.HelpBox.dwnd.title = buf;
    } else |_| {
    }

//    df.free(Dialogs.HelpBox.dwnd.title);
//    Dialogs.HelpBox.dwnd.title = @ptrCast(@alignCast(df.DFmalloc(len+1)));
//    _ = df.strcpy(Dialogs.HelpBox.dwnd.title, &df.hline);

    // ----- set the height and width -----
    Dialogs.HelpBox.dwnd.h = @min(df.ThisHelp.*.hheight, MAXHEIGHT)+7;
    Dialogs.HelpBox.dwnd.w = @max(45, df.ThisHelp.*.hwidth+6);

    // ------ position the help window -----
    if (win) |w| {
        BestFit(w, &Dialogs.HelpBox.dwnd);
    }
    // ------- position the command buttons ------ 
    Dialogs.HelpBox.ctl[0].dwnd.w = @max(40, df.ThisHelp.*.hwidth+2);
    Dialogs.HelpBox.ctl[0].dwnd.h =
                @min(df.ThisHelp.*.hheight, MAXHEIGHT)+2;
    const offset = @divFloor(Dialogs.HelpBox.dwnd.w-40, 2);
    for (1..5) |i| {
        const ii:c_int = @intCast(i);
        Dialogs.HelpBox.ctl[i].dwnd.y =
                        @min(df.ThisHelp.*.hheight, MAXHEIGHT)+3;
        Dialogs.HelpBox.ctl[i].dwnd.x = (ii-1) * 10 + offset;
    }

    // ---- disable ineffective buttons ----
    if (df.ThisHelp.*.nexthlp == -1) {
        DialogBox.DisableButton(&Dialogs.HelpBox, df.ID_NEXT);
    } else {
        DialogBox.EnableButton(&Dialogs.HelpBox, df.ID_NEXT);
    }
    if (df.ThisHelp.*.prevhlp == -1) {
        DialogBox.DisableButton(&Dialogs.HelpBox, df.ID_PREV);
    } else {
        DialogBox.EnableButton(&Dialogs.HelpBox, df.ID_PREV);
    }
}

// ----- select a new help window from its name -----
pub export fn SelectHelp(wnd:df.WINDOW, newhelp:[*c]df.helps, recall:df.BOOL) callconv(.c) void {
    if (newhelp != null) {
        if (Window.get_zin(wnd)) |win| {
            _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
            if (recall>0 and df.stacked < df.MAXHELPSTACK) {
                df.HelpStack[@intCast(df.stacked)] = @intCast(df.ThisHelp-df.FirstHelp);
                df.stacked += 1;
            }
            df.ThisHelp = newhelp;
            _ = win.getParent().sendMessage(df.DISPLAY_HELP, @intCast(@intFromPtr(df.ThisHelp.*.hname)), 0);
            if (df.stacked>0) {
                DialogBox.EnableButton(&Dialogs.HelpBox, df.ID_BACK);
            } else {
                DialogBox.DisableButton(&Dialogs.HelpBox, df.ID_BACK);
            }
            BuildHelpBox(null);
            if (Dialogs.HelpBox.dwnd.title) |ttl| {
                df.AddTitle(wnd, ttl.ptr);
            } // handle null title ?
            // --- reposition and resize the help window ---
            Dialogs.HelpBox.dwnd.x = @divFloor(df.SCREENWIDTH-Dialogs.HelpBox.dwnd.w, 2);
            Dialogs.HelpBox.dwnd.y = @divFloor(df.SCREENHEIGHT-Dialogs.HelpBox.dwnd.h, 2);
            _ = win.sendMessage(df.MOVE, Dialogs.HelpBox.dwnd.x, Dialogs.HelpBox.dwnd.y);
            _ = win.sendMessage(df.SIZE,
                                        Dialogs.HelpBox.dwnd.x + Dialogs.HelpBox.dwnd.w - 1,
                                        Dialogs.HelpBox.dwnd.y + Dialogs.HelpBox.dwnd.h - 1);
            // --- reposition the controls ---
            for (0..5) |i| {
                const cwnd:df.WINDOW = @ptrCast(@alignCast(Dialogs.HelpBox.ctl[i].wnd));
                var x = Dialogs.HelpBox.ctl[i].dwnd.x+win.GetClientLeft();
                var y = Dialogs.HelpBox.ctl[i].dwnd.y+win.GetClientTop();
                _ = q.SendMessage(cwnd, df.MOVE, x, y);
                if (i == 0) {
                    x += Dialogs.HelpBox.ctl[i].dwnd.w - 1;
                    y += Dialogs.HelpBox.ctl[i].dwnd.h - 1;
                    _ = q.SendMessage(cwnd, df.SIZE, x, y);
                }
            }
            // --- read the help text into the help window ---
            df.ReadHelp(wnd);
            lists.ReFocus(win);
            _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
        }
    }
}

fn OverLap(a: c_int, b: c_int) c_int {
    const ov = a - b;
    return if (ov < 0) 0 else ov;
//    if (ov < 0)
//        ov = 0;
//    return ov;
}


// ----- compute the best location for a help dialogbox -----
fn BestFit(win:*Window, dwnd:*Dialogs.DIALOGWINDOW) void {
    const wnd = win.win;
    if (df.GetClass(wnd) == df.MENUBAR or
                df.GetClass(wnd) == df.APPLICATION) {
        dwnd.*.x = -1;
        dwnd.*.y = -1;
        return;
    }

    // --- compute above overlap ----
    const above:c_int = OverLap(dwnd.*.h, @intCast(win.GetTop()));
    // --- compute below overlap ----
    const below:c_int = OverLap(@intCast(win.GetBottom()), df.SCREENHEIGHT-dwnd.*.h);
    // --- compute right overlap ----
    const right:c_int = OverLap(@intCast(win.GetRight()), df.SCREENWIDTH-dwnd.*.w);
    // --- compute left  overlap ----
    const left:c_int = OverLap(dwnd.*.w, @intCast(win.GetLeft()));

    if (above < below) {
        dwnd.*.y = @intCast(@max(0, win.GetTop()-dwnd.*.h-2));
    } else {
        dwnd.*.y = @intCast(@min(df.SCREENHEIGHT-dwnd.*.h, win.GetBottom()+2));
    }
    if (right < left) {
        dwnd.*.x = @intCast(@min(win.GetRight()+2, df.SCREENWIDTH-dwnd.*.w));
    } else {
        dwnd.*.x = @intCast(@max(0, win.GetLeft()-dwnd.*.w-2));
    }

    if (dwnd.*.x == win.GetRight()+2 or
            dwnd.*.x == win.GetLeft()-dwnd.*.w-2) {
        dwnd.*.y = -1;
    }
    if (dwnd.*.y == win.GetTop()-dwnd.*.h-2 or
            dwnd.*.y == win.GetBottom()+2) {
        dwnd.*.x = -1;
    }
}
 
