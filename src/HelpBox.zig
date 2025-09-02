const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const WndProc = @import("WndProc.zig");
const q = @import("Message.zig");

const MAXHEIGHT  = df.SCREENHEIGHT-10;
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
    const dbox:*df.DBOX = @ptrCast(@alignCast(wnd.*.extension));
    const cwnd = df.ControlWindow(dbox, df.ID_HELPTEXT);
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
                df.SelectHelp(wnd, df.FirstHelp+prevhlp, df.TRUE);
            }
            return true;
        },
        df.ID_NEXT => {
            if (df.ThisHelp != null) {
                const nexthlp:usize = @intCast(df.ThisHelp.*.nexthlp);
                df.SelectHelp(wnd, df.FirstHelp+nexthlp, df.TRUE);
            }
            return true;
        },
        df.ID_BACK => {
            if (df.stacked > 0) {
                df.stacked -= 1;
                const stacked:usize = @intCast(df.stacked);
                const helpstack:usize = @intCast(df.HelpStack[stacked]);
                df.SelectHelp(wnd, df.FirstHelp+helpstack, df.FALSE);
            }
            return true;
        },
        else => {
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
                if (df.HelpBoxKeyboardMsg(wnd, p1) > 0)
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
pub fn DisplayHelp(win:*Window, Help:[]const u8) c_int {
    const wnd = win.win;
    var buffer:[30]u8 = undefined;
    var rtn = df.FALSE;

    @memset(&buffer, 0);

    if (df.Helping > 0)
        return df.TRUE;

    const FixedHelp = StripTildes(Help, &buffer);

    wnd.*.isHelping += 1;
    df.ThisHelp = df.FindHelp(@constCast(FixedHelp.ptr));
    if (df.ThisHelp) |thisHelp| {
        _ = thisHelp;
        df.helpfp = df.OpenHelpFile(&df.HelpFileName, "rb");
        if (df.helpfp) |_| {
            df.BuildHelpBox(wnd);
            df.DisableButton(&Dialogs.HelpBox, df.ID_BACK);

            // ------- display the help window -----
            _ = DialogBox.DialogBox(null, &Dialogs.HelpBox, df.TRUE, HelpBoxProc);

            df.free(Dialogs.HelpBox.dwnd.title);
            Dialogs.HelpBox.dwnd.title = null;
            _ = df.fclose(df.helpfp);
            df.helpfp = null;
            rtn = df.TRUE;
        }
    }
    wnd.*.isHelping -= 1;
    return rtn;
}
