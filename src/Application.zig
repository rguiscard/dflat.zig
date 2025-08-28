const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const lists = @import("Lists.zig");

var ScreenHeight:c_int = 0;
var WindowSel:c_int = 0;

// --------------- CREATE_WINDOW Message --------------
fn CreateWindowMsg(win: *Window) c_int {
    const wnd = win.win;
    df.ApplicationWindow = wnd;
    ScreenHeight = df.SCREENHEIGHT;

    // INCLUDE_WINDOWOPTIONS
    if (df.cfg.Border > 0) {
        df.SetCheckBox(&df.Display, df.ID_BORDER);
    }
    if (df.cfg.Title > 0) {
        df.SetCheckBox(&df.Display, df.ID_TITLE);
    }
    if (df.cfg.StatusBar > 0) {
        df.SetCheckBox(&df.Display, df.ID_STATUSBAR);
    }
    if (df.cfg.Texture > 0) {
        df.SetCheckBox(&df.Display, df.ID_TEXTURE);
    }
    if (df.cfg.mono == 1) {
        df.PushRadioButton(&df.Display, df.ID_MONO);
    } else if (df.cfg.mono == 2) {
        df.PushRadioButton(&df.Display, df.ID_REVERSE);
    } else {
        df.PushRadioButton(&df.Display, df.ID_COLOR);
    }
    if (df.SCREENHEIGHT != df.cfg.ScreenLines) {
        df.SetScreenHeight(df.cfg.ScreenLines); // This method currently does nothing.
        if ((win.WindowHeight() == ScreenHeight) or
                (df.SCREENHEIGHT-1 < win.GetBottom()))    {
            win.SetWindowHeight(df.SCREENHEIGHT);
            win.SetBottom(win.GetTop()+win.WindowHeight()-1);
            wnd.*.RestoredRC = win.WindowRect();
        }
    }
    df.SelectColors(wnd);
    // INCLUDE_WINDOWOPTIONS
    df.SelectBorder(wnd);
    df.SelectTitle(wnd);
    df.SelectStatusBar(wnd);

    const rtn = root.zBaseWndProc(df.APPLICATION, win, df.CREATE_WINDOW, 0, 0);
    if (wnd.*.extension != null) {
        df.CreateMenu(wnd);
    }

    df.CreateStatusBar(wnd);

    _ = q.SendMessage(null, df.SHOW_MOUSE, 0, 0);
    return rtn;
}


// --------- ADDSTATUS Message ----------
// This want to make sure p1 point to a buffer which contain text.
fn AddStatusMsg(win: *Window, p1: df.PARAM) void {
    const wnd = win.win;
    if (wnd.*.StatusBar) |status_bar| {
        var text:?[]const u8 = null;
        if (p1 > 0) {
            const p:usize = @intCast(p1);
            const t:[*c]u8 = @ptrFromInt(p);
            const tt = std.mem.span(t);
            text = if (tt.len == 0) null else tt;
        }
        if (text) |_| {
            _ = q.SendMessage(status_bar, df.SETTEXT, p1, 0);
        } else {
            _ = q.SendMessage(status_bar, df.CLEARTEXT, 0, 0);
        }
        _ = q.SendMessage(status_bar, df.PAINT, 0, 0);
    }
}

// ------- SIZE Message --------
fn SizeMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    const WasVisible = (df.isVisible(wnd) > 0);
    if (WasVisible)
        _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    var p1_new = p1;
    if (p1-win.GetLeft() < 30)
        p1_new = win.GetLeft() + 30;
    _ = root.zBaseWndProc(df.APPLICATION, win, df.SIZE, p1_new, p2);
    df.CreateMenu(wnd);
    df.CreateStatusBar(wnd);
    if (WasVisible)
        _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
}

fn KeyboardMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) c_int {
    const wnd = win.win;
    if ((df.WindowMoving > 0) or (df.WindowSizing>0) or (p1 == df.F1))
        return root.zBaseWndProc(df.APPLICATION, win, df.KEYBOARD, p1, p2);
    switch (p1)  {
        df.ALT_F4 => {
            if (win.TestAttribute(df.CONTROLBOX)) {
                q.PostMessage(wnd, df.CLOSE_WINDOW, 0, 0);
            }
            return df.TRUE;
        },
        df.ALT_F6 => {
            lists.SetNextFocus();
            return df.TRUE;
        },
        df.ALT_HYPHEN => {
            if (win.TestAttribute(df.CONTROLBOX)) {
                df.BuildSystemMenu(wnd);
            }
            return df.TRUE;
        },
        else => {
        }
    }
    q.PostMessage(wnd.*.MenuBarWnd, df.KEYBOARD, p1, p2);
    return df.TRUE;
}

// --------- SHIFT_CHANGED Message --------
fn ShiftChangedMsg(win:*Window, p1:df.PARAM) void {
    const wnd = win.win;
    if ((p1 & df.ALTKEY) > 0) {
        df.AltDown = df.TRUE;
    } else if (df.AltDown > 0)    {
        df.AltDown = df.FALSE;
        if (wnd.*.MenuBarWnd != df.inFocus) {
            _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
        }
        _ = q.SendMessage(wnd.*.MenuBarWnd, df.KEYBOARD, df.F10, 0);
    }
}

// -------- COMMAND Message -------
fn CommandMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    switch (p1) {
//        df.ID_EXIT, df.ID_SYSCLOSE => {
//            df.PostMessage(wnd, df.CLOSE_WINDOW, 0, 0);
//        },
        df.ID_HELP => {
            _ = df.DisplayHelp(wnd, df.DFlatApplication);
        },
//        df.ID_HELPHELP => {
//            _ = helpbox.DisplayHelp(wnd, "HelpHelp");
//        },
//        df.ID_EXTHELP => {
//            _ = helpbox.DisplayHelp(wnd, "ExtHelp");
//        },
//        df.ID_KEYSHELP => {
//            _ = helpbox.DisplayHelp(wnd, "KeysHelp");
//        },
//        df.ID_HELPINDEX => {
//            _ = helpbox.DisplayHelp(wnd, "HelpIndex");
//        },
//        df.ID_LOG => {
//            log.MessageLog(wnd);
//        },
//        df.ID_DOS => {
//-            df.ShellDOS(wnd);
//        },
//        df.ID_DISPLAY => {
//            const box = Dialogs.Display;
//            var dialog = DialogBox.init(@constCast(&box));
//            if (dialog.create(wnd, true, null)) {
//                                if (inFocus == wnd->MenuBarWnd || inFocus == wnd->StatusBar)
//                                        oldFocus = ApplicationWindow;
//                                else
//                                        oldFocus = inFocus;
//                SendMessage(wnd, HIDE_WINDOW, 0, 0);
//                SelectColors(wnd);
//                SelectLines(wnd);

// INCLUDE_WINDOWOPTIONS
//                SelectBorder(wnd);
//                SelectTitle(wnd);
//                SelectStatusBar(wnd);
//                SelectTexture();
//                CreateMenu(wnd);
//                CreateStatusBar(wnd);
//                SendMessage(wnd, SHOW_WINDOW, 0, 0);
//                            SendMessage(oldFocus, SETFOCUS, TRUE, 0);
//            }
//        },
//        df.ID_WINDOW => {
//-            df.ChooseWindow(wnd, df.CurrentMenuSelection-2);
//        },
//        df.ID_CLOSEALL => {
//            CloseAll(win, false);
//        },
//        df.ID_MOREWINDOWS => {
//-            df.MoreWindows(wnd);
//        },
//        df.ID_SAVEOPTIONS => {
//-            df.SaveConfig();
//        },
        df.ID_SYSRESTORE,
        df.ID_SYSMINIMIZE,
        df.ID_SYSMAXIMIZE,
        df.ID_SYSMOVE,
        df.ID_SYSSIZE => {
            _ = root.zBaseWndProc(df.APPLICATION, win, df.COMMAND, p1, p2);
        },
        else => {
//            if ((df.inFocus != wnd.*.MenuBarWnd) and (df.inFocus != wnd)) {
//                df.PostMessage(df.inFocus, df.COMMAND, p1, p2);
//            }
        }
    }
}

// --------- CLOSE_WINDOW Message --------
fn CloseWindowMsg(win:*Window) c_int {
    const wnd = win.win;
    _ = wnd;
//    CloseAll(win, true);
    WindowSel = 0;
    q.PostMessage(null, df.STOP, 0, 0);

    const rtn = root.zBaseWndProc(df.APPLICATION, win, df.CLOSE_WINDOW, 0, 0);
//    if (ScreenHeight != df.SCREENHEIGHT)
//        SetScreenHeight(ScreenHeight);

    // UnLoadHelpFile();
    df.ApplicationWindow = null;
    return rtn;
}

pub fn ApplicationProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const wnd = win.win;

    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win);
        },
        df.HIDE_WINDOW => {
            if (wnd == df.inFocus)
                df.inFocus = null;
        },
        df.ADDSTATUS => {
            AddStatusMsg(win, p1);
            return df.TRUE;
        },
        df.SETFOCUS => {
            const p1b = (p1 > 0);
            if (p1b == (df.inFocus != wnd)) {
                SetFocusMsg(win, p1b);
                return df.TRUE;
            }
        },
        df.SIZE => {
            SizeMsg(win, p1, p2);
            return df.TRUE;
        },
        df.MINIMIZE => {
            return df.TRUE;
        },
        df.KEYBOARD => {
            return KeyboardMsg(win, p1, p2);
        },
        df.SHIFT_CHANGED => {
            ShiftChangedMsg(win, p1);
            return df.TRUE;
        },
        df.PAINT => {
            if (df.isVisible(wnd) > 0)    {
                const cl:u8 = if (df.cfg.Texture > 0) df.APPLCHAR else ' ';
                const pptr:usize = @intCast(p1);
                df.ClearWindow(wnd, @ptrFromInt(pptr), cl);
            }
            return df.TRUE;
        },
        df.COMMAND => {
            CommandMsg(win, p1, p2);
            return df.TRUE;
        },
        df.CLOSE_WINDOW => {
            return CloseWindowMsg(win);
        },
        else => {
            return df.cApplicationProc(wnd, msg, p1, p2);
        }
    }
    return root.zBaseWndProc(df.APPLICATION, win, msg, p1, p2);
}

// -------- SETFOCUS Message --------
fn SetFocusMsg(win:*Window, p1:bool) void {
    const wnd = win.win;
    if (p1) {
        _ = q.SendMessage(df.inFocus, df.SETFOCUS, df.FALSE, 0);
    }
    df.inFocus = if (p1) wnd else null;
    _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);

    if (df.isVisible(wnd)>0) {
        _ = win.sendMessage(df.BORDER, 0, 0);
    } else {
        _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
    }
}
