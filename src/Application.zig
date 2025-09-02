const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const lists = @import("Lists.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const helpbox = @import("HelpBox.zig");
const sysmenu = @import("SystemMenu.zig");

var ScreenHeight:c_int = 0;
var WindowSel:c_int = 0;
var oldFocus:df.WINDOW = null;

// --------------- CREATE_WINDOW Message --------------
fn CreateWindowMsg(win: *Window) bool {
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
        SetScreenHeight(df.cfg.ScreenLines);
        if ((win.WindowHeight() == ScreenHeight) or
                (df.SCREENHEIGHT-1 < win.GetBottom()))    {
            win.SetWindowHeight(df.SCREENHEIGHT);
            win.SetBottom(win.GetTop()+win.WindowHeight()-1);
            wnd.*.RestoredRC = win.WindowRect();
        }
    }
    df.SelectColors(wnd);
    df.SelectBorder(wnd);
    df.SelectTitle(wnd);
    df.SelectStatusBar(wnd);

    const rtn = root.zBaseWndProc(df.APPLICATION, win, df.CREATE_WINDOW, 0, 0);
    if (wnd.*.extension != null) {
        CreateMenu(win);
    }

    CreateStatusBar(win);

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
    CreateMenu(win);
    CreateStatusBar(win);
    if (WasVisible)
        _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
}

fn KeyboardMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    if ((df.WindowMoving > 0) or (df.WindowSizing>0) or (p1 == df.F1))
        return root.zBaseWndProc(df.APPLICATION, win, df.KEYBOARD, p1, p2);
    switch (p1)  {
        df.ALT_F4 => {
            if (win.TestAttribute(df.CONTROLBOX)) {
                q.PostMessage(wnd, df.CLOSE_WINDOW, 0, 0);
            }
            return true;
        },
        df.ALT_F6 => {
            lists.SetNextFocus();
            return true;
        },
        df.ALT_HYPHEN => {
            if (win.TestAttribute(df.CONTROLBOX)) {
                sysmenu.BuildSystemMenu(win);
            }
            return true;
        },
        else => {
        }
    }
    q.PostMessage(wnd.*.MenuBarWnd, df.KEYBOARD, p1, p2);
    return true;
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
        df.ID_EXIT, df.ID_SYSCLOSE => {
            q.PostMessage(wnd, df.CLOSE_WINDOW, 0, 0);
        },
        df.ID_HELP => {
            _ = helpbox.DisplayHelp(win, std.mem.span(df.DFlatApplication));
        },
        df.ID_HELPHELP => {
            const help = "HelpHelp";
            _ = helpbox.DisplayHelp(win, help);
        },
        df.ID_EXTHELP => {
            const help = "ExtHelp";
            _ = helpbox.DisplayHelp(win, help);
        },
        df.ID_KEYSHELP => {
            const help = "KeysHelp";
            _ = helpbox.DisplayHelp(win, help);
        },
        df.ID_HELPINDEX => {
            const help = "HelpIndex";
            _ = helpbox.DisplayHelp(win, help);
        },
        df.ID_LOG => {
            df.MessageLog(wnd);
        },
        df.ID_DOS => {
            ShellDOS(win);
        },
        df.ID_DISPLAY => {
            if (DialogBox.DialogBox(wnd, &df.Display, df.TRUE, null)>0) {
                if ((df.inFocus == wnd.*.MenuBarWnd) or (df.inFocus == wnd.*.StatusBar)) {
                    oldFocus = df.ApplicationWindow;
                } else {
                    oldFocus = df.inFocus;
                }
                _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
                df.SelectColors(wnd);
                df.SelectLines(wnd);
                df.SelectBorder(wnd);
                df.SelectTitle(wnd);
                df.SelectStatusBar(wnd);
                df.SelectTexture();
                CreateMenu(win);
                CreateStatusBar(win);
                _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
                if (oldFocus) |focus| { // cannot sure old focus can be null
                    _ = q.SendMessage(focus, df.SETFOCUS, df.TRUE, 0);
                } else {
                    _ = q.SendMessage(null, df.SETFOCUS, df.TRUE, 0);
                }
            }
        },
        df.ID_WINDOW => {
//-            df.ChooseWindow(wnd, df.CurrentMenuSelection-2);
        },
        df.ID_CLOSEALL => {
            CloseAll(win, false);
        },
        df.ID_MOREWINDOWS => {
//-            df.MoreWindows(wnd);
        },
        df.ID_SAVEOPTIONS => {
            df.SaveConfig();
        },
        df.ID_SYSRESTORE,
        df.ID_SYSMINIMIZE,
        df.ID_SYSMAXIMIZE,
        df.ID_SYSMOVE,
        df.ID_SYSSIZE => {
            _ = root.zBaseWndProc(df.APPLICATION, win, df.COMMAND, p1, p2);
        },
        else => {
            if ((df.inFocus != wnd.*.MenuBarWnd) and (df.inFocus != wnd)) {
                q.PostMessage(df.inFocus, df.COMMAND, p1, p2);
            }
        }
    }
}

// --------- CLOSE_WINDOW Message --------
fn CloseWindowMsg(win:*Window) bool {
    CloseAll(win, true);
    WindowSel = 0;
    q.PostMessage(null, df.STOP, 0, 0);

    const rtn = root.zBaseWndProc(df.APPLICATION, win, df.CLOSE_WINDOW, 0, 0);
    if (ScreenHeight != df.SCREENHEIGHT)
        SetScreenHeight(ScreenHeight);

    df.UnLoadHelpFile();
    df.ApplicationWindow = null;
    return rtn;
}

pub fn ApplicationProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
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
            return true;
        },
        df.SETFOCUS => {
            const p1b = (p1 > 0);
            if (p1b == (df.inFocus != wnd)) {
                SetFocusMsg(win, p1b);
                return true;
            }
        },
        df.SIZE => {
            SizeMsg(win, p1, p2);
            return true;
        },
        df.MINIMIZE => {
            return true;
        },
        df.KEYBOARD => {
            return KeyboardMsg(win, p1, p2);
        },
        df.SHIFT_CHANGED => {
            ShiftChangedMsg(win, p1);
            return true;
        },
        df.PAINT => {
            if (df.isVisible(wnd) > 0)    {
                const cl:u8 = if (df.cfg.Texture > 0) df.APPLCHAR else ' ';
                const pptr:usize = @intCast(p1);
                df.ClearWindow(wnd, @ptrFromInt(pptr), cl);
            }
            return true;
        },
        df.COMMAND => {
            CommandMsg(win, p1, p2);
            return true;
        },
        df.CLOSE_WINDOW => {
            return CloseWindowMsg(win);
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.APPLICATION, win, msg, p1, p2);
}

// ----- Close all document windows -----
fn CloseAll(win:*Window, closing:bool) void {
    const wnd = win.win;
    _ = win.sendMessage(df.SETFOCUS, df.TRUE, 0);

    var wnd1 = Window.LastWindow(wnd);
    while (wnd1) |w1| {
        const wnd2 = Window.PrevWindow(w1);
        if ((df.isVisible(w1)>0) and
                                (df.GetClass(w1) != df.MENUBAR) and 
                                        (df.GetClass(w1) != df.STATUSBAR)) {
            if (Window.get_zin(w1)) |zin| {
                zin.ClearVisible();
                _ = zin.sendMessage(df.CLOSE_WINDOW, 0, 0);
            }
        }
        wnd1 = wnd2;
    }

    if (closing == false)
        _ = win.sendMessage(df.PAINT, 0, 0);
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

// ---- set the screen height in the video hardware ----
fn SetScreenHeight(height: c_int) void {
    _ = height;
    // not implemented originally
//#if 0   /* display size changes not supported */
//        SendMessage(NULL, SAVE_CURSOR, 0, 0);
//
//        /* change display size here */
//
//        SendMessage(NULL, RESTORE_CURSOR, 0, 0);
//        SendMessage(NULL, RESET_MOUSE, 0, 0);
//        SendMessage(NULL, SHOW_MOUSE, 0, 0);
//    }
//#endif
}

// -------- Create the menu bar --------
fn CreateMenu(win: *Window) void {
    const wnd = win.win;
    win.AddAttribute(df.HASMENUBAR);
    if (wnd.*.MenuBarWnd != null) {
        _ = q.SendMessage(wnd.*.MenuBarWnd, df.CLOSE_WINDOW, 0, 0);
    }
    var mwnd = Window.create(df.MENUBAR,
                        null,
                        @intCast(win.GetClientLeft()),
                        @intCast(win.GetClientTop()-1),
                        1,
                        @intCast(win.ClientWidth()),
                        null,
                        wnd,
                        null,
                        0);

    win.win.*.MenuBarWnd = mwnd.win;

    const ext:df.PARAM = @intCast(@intFromPtr(wnd.*.extension));
    _ = mwnd.sendMessage(df.BUILDMENU, ext,0);
    mwnd.AddAttribute(df.VISIBLE);
}


// ----------- Create the status bar -------------
fn CreateStatusBar(win: *Window) void {
    const wnd = win.win;
    if (wnd.*.StatusBar != null)    {
        _ = q.SendMessage(wnd.*.StatusBar, df.CLOSE_WINDOW, 0, 0);
        win.win.*.StatusBar = null;
    }
    if (win.TestAttribute(df.HASSTATUSBAR)) {
        var sbar = Window.create(df.STATUSBAR,
                            null,
                            @intCast(win.GetClientLeft()),
                            @intCast(win.GetBottom()),
                            1,
                            @intCast(win.ClientWidth()),
                            null,
                            wnd,
                            null,
                            0);
        win.win.*.StatusBar = sbar.win;
        sbar.AddAttribute(df.VISIBLE);
    }
}

// SHELLDOS
fn SwitchCursor() void {
    _ = q.SendMessage(null, df.SAVE_CURSOR, 0, 0);
    df.SwapCursorStack();
    _ = q.SendMessage(null, df.RESTORE_CURSOR, 0, 0);
}

// ------- Shell out to DOS ----------
fn ShellDOS(win:*Window) void {
    oldFocus = df.inFocus;
    _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    SwitchCursor();
    if (ScreenHeight != df.SCREENHEIGHT)
        SetScreenHeight(ScreenHeight);
    _ = q.SendMessage(null, df.HIDE_MOUSE, 0, 0);
    _ = df.fflush(df.stdout);
    df.tty_restore();
    _ = df.runshell();
    df.tty_enable_unikey();

    if (df.SCREENHEIGHT != df.cfg.ScreenLines)
        SetScreenHeight(df.cfg.ScreenLines);
    SwitchCursor();
    _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
    _ = q.SendMessage(oldFocus, df.SETFOCUS, df.TRUE, 0);
    _ = q.SendMessage(null, df.SHOW_MOUSE, 0, 0);
}
