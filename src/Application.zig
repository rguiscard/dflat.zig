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
const log = @import("Log.zig");
const radio = @import("RadioButton.zig");
const checkbox = @import("CheckBox.zig");
const normal = @import("Normal.zig");
const menus = @import("Menus.zig");
const popdown = @import("PopDown.zig");

pub var ApplicationWindow:?*Window = null;
var ScreenHeight:c_int = 0;
var WindowSel:c_int = 0;
var oldFocus:df.WINDOW = null;
var Menus = [_][]u8{
    @constCast("~1.                      "),
    @constCast("~2.                      "),
    @constCast("~3.                      "),
    @constCast("~4.                      "),
    @constCast("~5.                      "),
    @constCast("~6.                      "),
    @constCast("~7.                      "),
    @constCast("~8.                      "),
    @constCast("~9.                      "),
};

// --------------- CREATE_WINDOW Message --------------
fn CreateWindowMsg(win: *Window) bool {
    const wnd = win.win;
    ApplicationWindow = win;
    ScreenHeight = df.SCREENHEIGHT;

    // INCLUDE_WINDOWOPTIONS
    if (df.cfg.Border > 0) {
        DialogBox.SetCheckBox(&Dialogs.Display, df.ID_BORDER);
    }
    if (df.cfg.Title > 0) {
        DialogBox.SetCheckBox(&Dialogs.Display, df.ID_TITLE);
    }
    if (df.cfg.StatusBar > 0) {
        DialogBox.SetCheckBox(&Dialogs.Display, df.ID_STATUSBAR);
    }
    if (df.cfg.Texture > 0) {
        DialogBox.SetCheckBox(&Dialogs.Display, df.ID_TEXTURE);
    }
    if (df.cfg.mono == 1) {
        radio.PushRadioButton(&Dialogs.Display, df.ID_MONO);
    } else if (df.cfg.mono == 2) {
        radio.PushRadioButton(&Dialogs.Display, df.ID_REVERSE);
    } else {
        radio.PushRadioButton(&Dialogs.Display, df.ID_COLOR);
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
    SelectColors(win);
    SelectBorder(win);
    SelectTitle(win);
    SelectStatusBar(win);

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
    if (win.StatusBar) |sb| {
        var text:?[]const u8 = null;
        if (p1 > 0) {
            const p:usize = @intCast(p1);
            const t:[*c]u8 = @ptrFromInt(p);
            const tt = std.mem.span(t);
            text = if (tt.len == 0) null else tt;
        }
        if (text) |_| {
            _ = sb.sendMessage(df.SETTEXT, p1, 0);
        } else {
            _ = sb.sendMessage(df.CLEARTEXT, 0, 0);
        }
        _ = sb.sendMessage(df.PAINT, 0, 0);
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
    if (win.MenuBar) |mb| {
        q.PostMessage(mb.win, df.KEYBOARD, p1, p2);
    } // also consider null ?
    return true;
}

// --------- SHIFT_CHANGED Message --------
fn ShiftChangedMsg(win:*Window, p1:df.PARAM) void {
    if ((p1 & df.ALTKEY) > 0) {
        df.AltDown = df.TRUE;
    } else if (df.AltDown > 0)    {
        df.AltDown = df.FALSE;
        if (win.MenuBar != Window.inFocus) {
            _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
        }
        if (win.MenuBar) |mb| {
            _ = mb.sendMessage(df.KEYBOARD, df.F10, 0);
        } // also consider null ?
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
            log.MessageLog(win);
        },
        df.ID_DOS => {
            ShellDOS(win);
        },
        df.ID_DISPLAY => {
            if (DialogBox.create(win, &Dialogs.Display, df.TRUE, null)) {
                if ((Window.inFocus == win.MenuBar) or (Window.inFocus == win.StatusBar)) {
                    oldFocus = ApplicationWindow.?.win;
                } else {
                    oldFocus = Window.inFocusWnd();
                }
                _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
                SelectColors(win);
                SelectLines(win);
                SelectBorder(win);
                SelectTitle(win);
                SelectStatusBar(win);
                SelectTexture();
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
            ChooseWindow(win, popdown.CurrentMenuSelection-2);
        },
        df.ID_CLOSEALL => {
            CloseAll(win, false);
        },
        df.ID_MOREWINDOWS => {
            MoreWindows(win);
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
            if ((Window.inFocus != win.MenuBar) and (Window.inFocus != win)) {
                q.PostMessage(Window.inFocusWnd(), df.COMMAND, p1, p2);
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
    ApplicationWindow = null;
    return rtn;
}

pub fn ApplicationProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;

    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win);
        },
        df.HIDE_WINDOW => {
            if (win == Window.inFocus)
                Window.inFocus = null;
        },
        df.ADDSTATUS => {
            AddStatusMsg(win, p1);
            return true;
        },
        df.SETFOCUS => {
            const p1b = (p1 > 0);
            if (p1b == (Window.inFocus != win)) {
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
            if (normal.isVisible(win))    {
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
    _ = win.sendMessage(df.SETFOCUS, df.TRUE, 0);
    var win1 = win.lastWindow();
    while (win1) |w1| {
        const wnd1 = w1.win;
        if ((df.isVisible(wnd1)>0) and
                       (w1.getClass() != df.MENUBAR) and
                       (w1.getClass() != df.STATUSBAR)) {
            w1.ClearVisible();
            _ = w1.sendMessage(df.CLOSE_WINDOW, 0, 0);
        }
        win1 = w1.prevWindow();
    }

    if (closing == false)
        _ = win.sendMessage(df.PAINT, 0, 0);
}

// -------- SETFOCUS Message --------
fn SetFocusMsg(win:*Window, p1:bool) void {
    const wnd = win.win;
    if (p1) {
        if (Window.inFocus) |focus| {
            _ = focus.sendMessage(df.SETFOCUS, df.FALSE, 0);
        }
    }
    Window.inFocus = if (p1) win else null;
    _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);

    if (df.isVisible(wnd)>0) {
        _ = win.sendMessage(df.BORDER, 0, 0);
    } else {
        _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
    }
}

// -------- return the name of a document window -------
fn WindowName(wnd:df.WINDOW) ?[]const u8 {
    if (df.GetTitle(wnd) == null) {
        if (df.GetClass(wnd) == df.DIALOG) {
            if (wnd.*.extension) |ext| {
                const dbox:*Dialogs.DBOX = @ptrCast(@alignCast(ext));
                return dbox.*.HelpName;
            }
        } else {
            return "Untitled";
        }
    } else {
        return std.mem.span(df.GetTitle(wnd));
    }
    return null;
}

// ----------- Prepare the Window menu ------------
// FIXME: All "more windows" functsion are not tested. it does not work as expected now.
pub fn PrepWindowMenu(w:?*anyopaque, mnu:*menus.MENU) void {
    if (w) |ww| {
        const wnd:df.WINDOW = @ptrCast(@alignCast(ww));
        const p0 = &mnu.*.Selections[0];
        var pd = &mnu.*.Selections[2];
//        const ca = &mnu.*.Selections[13];
        var MenuNo:usize = 0;
        mnu.*.Selection = 0;
        oldFocus = null;
        if (df.GetClass(wnd) != df.APPLICATION)    {
            oldFocus = wnd;
            // ----- point to the APPLICATION window -----
            if (ApplicationWindow) |awin| {
                var cwin = awin.firstWindow();
                // ----- get the first 9 document windows -----
                for (0..9) |idx| {
                    MenuNo = idx;
                    if (cwin) |cw| {
                        const cwnd = cw.win;
                        if (df.isVisible(cwnd)>0 and cw.getClass() != df.MENUBAR and
                                cw.getClass() != df.STATUSBAR) {
                            // --- add the document window to the menu ---
                            // strncpy(Menus[MenuNo]+4, WindowName(cwnd), 20); //for MSDOS ?
                            pd.*.SelectionTitle = Menus[MenuNo];
                            if (cwnd == oldFocus) {
                                // -- mark the current document --
                                pd.*.Attrib.CHECKED = true;
                                mnu.*.Selection = @intCast(MenuNo+2);
                            } else {
                                pd.*.Attrib.CHECKED = false;
                            }
                            pd = &mnu.*.Selections[idx+2];
                        }
                        cwin = cw.nextWindow();
                    } else {
                        break;
                    }
                }
            } else {
                return;
            }
        }
        if (MenuNo > 0) {
            p0.*.SelectionTitle = "~Close all";
        } else {
            p0.*.SelectionTitle = null;
        }
        if (MenuNo >= 9) {
// FIXME
//            *pd++ = *ca;
//            if (mnu.*.Selection == 0)
//                mnu.*.Selection = 11;
        }
        pd.*.SelectionTitle = null;
    }
}

fn WindowPrep(win:*Window,msg:df.MESSAGE,p1:df.PARAM,p2:df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.INITIATE_DIALOG => {
            if (DialogBox.ControlWindow(&Dialogs.Windows,df.ID_WINDOWLIST)) |cwin| {
                var sel:c_int = 0;
                if (ApplicationWindow) |awin| {
                    var win1 = awin.firstWindow();
                    while (win1) |w1| {
                        const wnd1 = w1.win;
                        if (df.isVisible(wnd1)>0 and (wnd1 != wnd) and
                                        (w1.getClass() != df.MENUBAR) and
                                        w1.getClass() != df.STATUSBAR) {
                            if (wnd1 == oldFocus)
                                WindowSel = sel;
    
                            const name = WindowName(wnd1);
                            if (name) |n| {
                                _ = cwin.sendMessage(df.ADDTEXT, @intCast(@intFromPtr(n.ptr)), 0);
                            }
    
                            sel += 1;
                        }
                        win1 = w1.nextWindow();
                    }
                } else {
                    // do something ?
                } 
                _ = cwin.sendMessage(df.LB_SETSELECTION, WindowSel, 0);
                cwin.AddAttribute(df.VSCROLLBAR);
                q.PostMessage(cwin.win, df.SHOW_WINDOW, 0, 0);
            } else {
                return false;
            }
        },
        df.COMMAND => {
            switch (p1) {
                df.ID_OK => {
                    if (p2 == 0) {
                        const val:c_int = -1;
                        const control = DialogBox.ControlWindow(&Dialogs.Windows, df.ID_WINDOWLIST);
                        if (control) |cwin| {
                            _ = cwin.sendMessage(df.LB_CURRENTSELECTION, 
                                                @intCast(@intFromPtr(&val)), 0);
                            WindowSel = val;
                        }

                    }
                },
                df.ID_WINDOWLIST => {
                    if (p2 == df.LB_CHOOSE)
                        _ = win.sendMessage(df.COMMAND, df.ID_OK, 0);
                },
                else => {
                }
            }
        },
        else => {
        }
    }
    return root.zDefaultWndProc(win, msg, p1, p2);
}
        

// ---- the More Windows command on the Window menu ----
fn MoreWindows(win:*Window) void {
    if (DialogBox.create(win, &Dialogs.Windows, df.TRUE, WindowPrep))
        ChooseWindow(win, WindowSel);
}

// ----- user chose a window from the Window menu
//        or the More Window dialog box ----- 
fn ChooseWindow(win:*Window, WindowNo:c_int) void {
    var counter = WindowNo;
    var cwin = win.firstWindow();
    while (cwin) |cw| {
        const cwnd = cw.win;
        if (df.isVisible(cwnd)>0 and
                        cw.getClass() != df.MENUBAR and
                        cw.getClass() != df.STATUSBAR) {
            if (counter == 0)
                break;
            counter -= 1;
        }
        cwin = cw.nextWindow();
    }
    if (cwin) |cw| {
        _ = cw.sendMessage(df.SETFOCUS, df.TRUE, 0);
        if (cw.win.*.condition == df.ISMINIMIZED)
            _ = cw.sendMessage(df.RESTORE, 0, 0);
    }
}

fn DoWindowColors(win:*Window) void {
    const wnd = win.win;
    df.InitWindowColors(wnd);
    var cwin = win.firstWindow();
    while (cwin) |cw| {
        const cwnd = cw.win;
        DoWindowColors(cw);
        if ((cw.getClass() == df.TEXT) and df.GetText(cwnd) != null) {
            _ = cw.sendMessage(df.CLEARTEXT, 0, 0);
        }
        cwin = cw.nextWindow();
    }
}

// ----- set up colors for the application window ------
fn SelectColors(win: *Window) void {
    if (radio.RadioButtonSetting(&Dialogs.Display, df.ID_MONO)) {
        df.cfg.mono = 1;   // mono
    } else if (radio.RadioButtonSetting(&Dialogs.Display, df.ID_REVERSE)) {
        df.cfg.mono = 2;   // mono reverse
    } else {
        df.cfg.mono = 0;   // color
    }

    if (df.cfg.mono == 1) {
        @memcpy(&df.cfg.clr, &df.bw);
    } else if (df.cfg.mono == 2) {
        @memcpy(&df.cfg.clr, &df.reverse);
    } else {
        @memcpy(&df.cfg.clr, &df.color);
    }
    DoWindowColors(win);
}

// ---- select screen lines ----
fn SelectLines(win:*Window) void {
    const wnd = win.win;
    df.cfg.ScreenLines = df.SCREENHEIGHT;
    if (df.SCREENHEIGHT != df.cfg.ScreenLines) {
        SetScreenHeight(df.cfg.ScreenLines);
        // ---- re-maximize ----
        if (wnd.*.condition == df.ISMAXIMIZED) {
            _ = win.sendMessage(df.SIZE, @intCast(win.GetRight()), @intCast(df.SCREENHEIGHT-1));
            return;
        }
        // --- adjust if current size does not fit ---
        if (win.WindowHeight() > df.SCREENHEIGHT) {
            _ = win.sendMessage(df.SIZE, @intCast(win.GetRight()),
                @intCast(win.GetTop()+df.SCREENHEIGHT-1));
        }
        // --- if window is off-screen, move it on-screen ---
        if (win.GetTop() >= df.SCREENHEIGHT-1) {
            _ = win.sendMessage(df.MOVE, @intCast(win.GetLeft()),
                    @intCast(df.SCREENHEIGHT-win.WindowHeight()));
        }
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

// ----- select the screen texture -----
fn SelectTexture() void {
    df.cfg.Texture = checkbox.CheckBoxSetting(&Dialogs.Display, df.ID_TEXTURE);
}

// -- select whether the application screen has a border --
fn SelectBorder(win: *Window) void {
    df.cfg.Border = checkbox.CheckBoxSetting(&Dialogs.Display, df.ID_BORDER);
    if (df.cfg.Border > 0) {
        win.AddAttribute(df.HASBORDER);
    } else {
        win.ClearAttribute(df.HASBORDER);
    }
}

// select whether the application screen has a status bar
fn SelectStatusBar(win: *Window) void {
    df.cfg.StatusBar = checkbox.CheckBoxSetting(&Dialogs.Display, df.ID_STATUSBAR);
    if (df.cfg.StatusBar > 0) {
        win.AddAttribute(df.HASSTATUSBAR);
    } else {
        win.ClearAttribute(df.HASSTATUSBAR);
    }
}

// select whether the application screen has a title bar
fn SelectTitle(win: *Window) void {
    df.cfg.Title = checkbox.CheckBoxSetting(&Dialogs.Display, df.ID_TITLE);
    if (df.cfg.Title > 0) {
        win.AddAttribute(df.HASTITLEBAR);
    } else {
        win.ClearAttribute(df.HASTITLEBAR);
    }
}

// -------- Create the menu bar --------
fn CreateMenu(win: *Window) void {
    const wnd = win.win;
    win.AddAttribute(df.HASMENUBAR);
    if (win.MenuBar) |mb| {
        _ = mb.sendMessage(df.CLOSE_WINDOW, 0, 0);
    }
    var mwnd = Window.create(df.MENUBAR,
                        null,
                        @intCast(win.GetClientLeft()),
                        @intCast(win.GetClientTop()-1),
                        1,
                        @intCast(win.ClientWidth()),
                        null,
                        win,
                        null,
                        0);

    win.MenuBar = mwnd;

    const ext:df.PARAM = @intCast(@intFromPtr(wnd.*.extension));
    _ = mwnd.sendMessage(df.BUILDMENU, ext,0);
    mwnd.AddAttribute(df.VISIBLE);
}


// ----------- Create the status bar -------------
fn CreateStatusBar(win: *Window) void {
    if (win.StatusBar) |sb| {
        _ = sb.sendMessage(df.CLOSE_WINDOW, 0, 0);
        win.StatusBar = null;
    }
    if (win.TestAttribute(df.HASSTATUSBAR)) {
        var sbar = Window.create(df.STATUSBAR,
                            null,
                            @intCast(win.GetClientLeft()),
                            @intCast(win.GetBottom()),
                            1,
                            @intCast(win.ClientWidth()),
                            null,
                            win,
                            null,
                            0);
        win.StatusBar = sbar;
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
    oldFocus = Window.inFocusWnd();
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
