const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;
const k = @import("Classes.zig").CLASS;
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
const Colors = @import("Colors.zig");
const cfg = @import("Config.zig");
const console = @import("Console.zig");

pub var ApplicationWindow:?*Window = null;
var ScreenHeight:c_int = 0;
var WindowSel:usize = 0; // use optional if it behaves weird
var oldFocus:?*Window = null;
var Menus = [_][:0]u8{
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
    if (cfg.config.Border) {
        DialogBox.SetCheckBox(&Dialogs.Display, .ID_BORDER);
    }
    if (cfg.config.Title) {
        DialogBox.SetCheckBox(&Dialogs.Display, .ID_TITLE);
    }
    if (cfg.config.StatusBar) {
        DialogBox.SetCheckBox(&Dialogs.Display, .ID_STATUSBAR);
    }
    if (cfg.config.Texture) {
        DialogBox.SetCheckBox(&Dialogs.Display, .ID_TEXTURE);
    }
    if (cfg.config.mono == 1) {
        radio.PushRadioButton(&Dialogs.Display, .ID_MONO);
    } else if (cfg.config.mono == 2) {
        radio.PushRadioButton(&Dialogs.Display, .ID_REVERSE);
    } else {
        radio.PushRadioButton(&Dialogs.Display, .ID_COLOR);
    }
    if (df.SCREENHEIGHT != cfg.config.ScreenLines) {
        SetScreenHeight(@intCast(cfg.config.ScreenLines));
        if ((win.WindowHeight() == ScreenHeight) or
                (df.SCREENHEIGHT-1 < win.GetBottom()))    {
            win.SetWindowHeight(df.SCREENHEIGHT);
            win.SetBottom(win.GetTop()+win.WindowHeight()-1);
            wnd.*.RestoredRC = win.cWindowRect();
        }
    }
    SelectColors(win);
    SelectBorder(win);
    SelectTitle(win);
    SelectStatusBar(win);

    const rtn = root.BaseWndProc(k.APPLICATION, win, df.CREATE_WINDOW, q.none);
    if (win.extension != null) {
        CreateMenu(win);
    }

    CreateStatusBar(win);

    _ = q.SendMessage(null, df.SHOW_MOUSE, q.none);

    return rtn;
}


// --------- ADDSTATUS Message ----------
// This want to make sure p1 point to a buffer which contain text.
fn AddStatusMsg(win: *Window, p1: []const u8) void {
    if (win.StatusBar) |sb| {
        if (p1.len > 0) {
            _ = sb.sendTextMessage(df.SETTEXT, p1);
        } else {
            _ = sb.sendMessage(df.CLEARTEXT, q.none);
        }
        _ = sb.sendMessage(df.PAINT, .{.paint=.{null, false}});
    }
}

// ------- SIZE Message --------
fn SizeMsg(win:*Window, x:usize, y:usize) void {
    const WasVisible = win.isVisible();
    if (WasVisible)
        _ = win.sendMessage(df.HIDE_WINDOW, q.none);
    var x_new:usize = x;
    if (x < 30 + win.GetLeft())
        x_new = win.GetLeft() + 30;
    _ = root.BaseWndProc(k.APPLICATION, win, df.SIZE, .{.position=.{x_new, y}});
    CreateMenu(win);
    CreateStatusBar(win);
    if (WasVisible)
        _ = win.sendMessage(df.SHOW_WINDOW, q.none);
}

fn KeyboardMsg(win:*Window, p1:u16, p2:u8) bool {
    if (normal.WindowMoving or normal.WindowSizing or (p1 == df.F1))
        return root.BaseWndProc(k.APPLICATION, win, df.KEYBOARD, .{.char=.{p1, p2}});
    switch (p1)  {
        df.ALT_F4 => {
            if (win.TestAttribute(df.CONTROLBOX)) {
                q.PostMessage(win, df.CLOSE_WINDOW, .{.yes=false});
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
        q.PostMessage(mb, df.KEYBOARD, .{.char=.{p1, p2}});
    } // also consider null ?
    return true;
}

// --------- SHIFT_CHANGED Message --------
fn ShiftChangedMsg(win:*Window, p1:u16) void {
    if ((p1 & df.ALTKEY) > 0) {
        df.AltDown = df.TRUE;
    } else if (df.AltDown > 0)    {
        df.AltDown = df.FALSE;
        if (win.MenuBar != Window.inFocus) {
            _ = q.SendMessage(null, df.HIDE_CURSOR, q.none);
        }
        if (win.MenuBar) |mb| {
            _ = mb.sendMessage(df.KEYBOARD, .{.char=.{df.F10, 0}});
        } // also consider null ?
    }
}

// -------- COMMAND Message -------
fn CommandMsg(win:*Window, p1:c, p2:usize) void {
    const cmd:c = p1;
    switch (cmd) {
        .ID_EXIT, .ID_SYSCLOSE => {
            q.PostMessage(win, df.CLOSE_WINDOW, .{.yes=false});
        },
        .ID_HELP => {
            _ = helpbox.DisplayHelp(win, std.mem.span(df.DFlatApplication));
        },
        .ID_HELPHELP => {
            const help = "HelpHelp";
            _ = helpbox.DisplayHelp(win, help);
        },
        .ID_EXTHELP => {
            const help = "ExtHelp";
            _ = helpbox.DisplayHelp(win, help);
        },
        .ID_KEYSHELP => {
            const help = "KeysHelp";
            _ = helpbox.DisplayHelp(win, help);
        },
        .ID_HELPINDEX => {
            const help = "HelpIndex";
            _ = helpbox.DisplayHelp(win, help);
        },
        .ID_LOG => {
            log.MessageLog(win);
        },
        .ID_DOS => {
            ShellDOS(win);
        },
        .ID_DISPLAY => {
            if (DialogBox.create(win, &Dialogs.Display, df.TRUE, null)) {
                if ((Window.inFocus == win.MenuBar) or (Window.inFocus == win.StatusBar)) {
                    oldFocus = ApplicationWindow;
                } else {
                    oldFocus = Window.inFocus;
                }
                _ = win.sendMessage(df.HIDE_WINDOW, q.none);
                SelectColors(win);
                SelectLines(win);
                SelectBorder(win);
                SelectTitle(win);
                SelectStatusBar(win);
                SelectTexture();
                CreateMenu(win);
                CreateStatusBar(win);
                _ = win.sendMessage(df.SHOW_WINDOW, q.none);
                if (oldFocus) |focus| { // cannot sure old focus can be null
                    _ = focus.sendMessage(df.SETFOCUS, .{.yes=true});
                } else {
                    _ = q.SendMessage(null, df.SETFOCUS, .{.yes=true});
                }
            }
        },
        .ID_WINDOW => {
            ChooseWindow(win, if (popdown.CurrentMenuSelection > 2) popdown.CurrentMenuSelection-2 else 0);
        },
        .ID_CLOSEALL => {
            CloseAll(win, false);
        },
        .ID_MOREWINDOWS => {
            MoreWindows(win);
        },
        .ID_SAVEOPTIONS => {
            cfg.Save();
        },
        .ID_SYSRESTORE,
        .ID_SYSMINIMIZE,
        .ID_SYSMAXIMIZE,
        .ID_SYSMOVE,
        .ID_SYSSIZE => {
            _ = root.BaseWndProc(k.APPLICATION, win, df.COMMAND, .{.command = .{p1, p2}});
        },
        else => {
            if ((Window.inFocus != win.MenuBar) and (Window.inFocus != win)) {
                q.PostMessage(Window.inFocus, df.COMMAND, .{.command = .{p1, p2}});
            }
        }
    }
}

// --------- CLOSE_WINDOW Message --------
fn CloseWindowMsg(win:*Window) bool {
    CloseAll(win, true);
    WindowSel = 0;
    q.PostMessage(null, df.STOP, q.none);

    const rtn = root.BaseWndProc(k.APPLICATION, win, df.CLOSE_WINDOW, .{.yes=false});
    if (ScreenHeight != df.SCREENHEIGHT)
        SetScreenHeight(ScreenHeight);

    df.UnLoadHelpFile();
    ApplicationWindow = null;
    return rtn;
}

pub fn ApplicationProc(win:*Window, msg: df.MESSAGE, params:q.Params) bool {
    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win);
        },
        df.HIDE_WINDOW => {
            if (win == Window.inFocus)
                Window.inFocus = null;
        },
        df.ADDSTATUS => {
            AddStatusMsg(win, params.slice);
            return true;
        },
        df.SETFOCUS => {
            const p1 = params.yes;
            if (p1 == (Window.inFocus != win)) {
                SetFocusMsg(win, p1);
                return true;
            }
        },
        df.SIZE => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            SizeMsg(win, p1, p2);
            return true;
        },
        df.MINIMIZE => {
            return true;
        },
        df.KEYBOARD => {
            const p1 = params.char[0];
            const p2 = params.char[1];
            return KeyboardMsg(win, p1, p2);
        },
        df.SHIFT_CHANGED => {
            const p1 = params.char[0];
            ShiftChangedMsg(win, p1);
            return true;
        },
        df.PAINT => {
            const p1:?df.RECT = params.paint[0];
            if (win.isVisible())    {
                const cl:u8 = if (cfg.config.Texture) df.APPLCHAR else ' ';
                win.ClearWindow(p1, cl);
            }
            return true;
        },
        df.COMMAND => {
            const p1:c = params.command[0];
            const p2:usize = params.command[1];
            CommandMsg(win, p1, p2);
            return true;
        },
        df.CLOSE_WINDOW => {
            return CloseWindowMsg(win);
        },
        else => {
        }
    }
    return root.BaseWndProc(k.APPLICATION, win, msg, params);
}

// ----- Close all document windows -----
fn CloseAll(win:*Window, closing:bool) void {
    _ = win.sendMessage(df.SETFOCUS, .{.yes=true});
    var win1 = win.lastWindow();
    while (win1) |w1| {
        if (w1.isVisible() and
                       (w1.getClass() != k.MENUBAR) and
                       (w1.getClass() != k.STATUSBAR)) {
            w1.ClearVisible();
            _ = w1.sendMessage(df.CLOSE_WINDOW, .{.yes=false});
        }
        win1 = w1.prevWindow();
    }

    if (closing == false)
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
}

// -------- SETFOCUS Message --------
fn SetFocusMsg(win:*Window, p1:bool) void {
    if (p1) {
        if (Window.inFocus) |focus| {
            _ = focus.sendMessage(df.SETFOCUS, .{.yes=false});
        }
    }
    Window.inFocus = if (p1) win else null;
    _ = q.SendMessage(null, df.HIDE_CURSOR, q.none);

    if (win.isVisible()) {
        _ = win.sendMessage(df.BORDER, .{.paint=.{null, false}});
    } else {
        _ = win.sendMessage(df.SHOW_WINDOW, q.none);
    }
}

// -------- return the name of a document window -------
fn WindowName(win:*Window) ?[:0]const u8 {
    if (win.title) |title| {
        return title;
    } else {
        if (win.Class == k.DIALOG) {
            if (win.extension) |extension| {
                const dbox:*Dialogs.DBOX = extension.dbox;
                return dbox.*.HelpName;
            }
        } else {
            return "Untitled";
        }
    }
    return null;
}

// ----------- Prepare the Window menu ------------
// FIXME: All "more windows" functsion are not tested. it does not work as expected now.
pub fn PrepWindowMenu(w:?*Window, mnu:*menus.MENU) void {
    if (w) |win| {
        const p0 = &mnu.*.Selections[0];
        var pd = &mnu.*.Selections[2];
        var MenuNo:usize = 0;
        mnu.*.Selection = 0;
        oldFocus = null;
        if (win.getClass() != k.APPLICATION)    {
            oldFocus = win;
            // ----- point to the APPLICATION window -----
            if (ApplicationWindow) |awin| {
                var cwin = awin.firstWindow();
                // ----- get the first 9 document windows -----
                for (0..9) |idx| {
                    MenuNo = idx;
                    if (cwin) |cw| {
                        if (cw.isVisible() and cw.getClass() != k.MENUBAR and
                                cw.getClass() != k.STATUSBAR) {
                            // --- add the document window to the menu ---
                            // strncpy(Menus[MenuNo]+4, WindowName(cwnd), 20); //for MSDOS ?
                            pd.*.SelectionTitle = Menus[MenuNo];
                            if (cw == oldFocus) {
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

fn WindowPrep(win:*Window,msg:df.MESSAGE,params:q.Params) bool {
    const wnd = win.win;
    switch (msg) {
        df.INITIATE_DIALOG => {
            if (DialogBox.ControlWindow(&Dialogs.Windows,.ID_WINDOWLIST)) |cwin| {
                var sel:usize = 0;
                if (ApplicationWindow) |awin| {
                    var win1 = awin.firstWindow();
                    while (win1) |w1| {
                        const wnd1 = w1.win;
                        if (w1.isVisible() and (wnd1 != wnd) and
                                        (w1.getClass() != k.MENUBAR) and
                                        w1.getClass() != k.STATUSBAR) {
                            if (w1 == oldFocus)
                                WindowSel = sel;
    
                            const name = WindowName(w1);
                            if (name) |n| {
                                _ = cwin.sendTextMessage(df.ADDTEXT, n);
                            }
    
                            sel += 1;
                        }
                        win1 = w1.nextWindow();
                    }
                } else {
                    // do something ?
                } 
                _ = cwin.sendMessage(df.LB_SETSELECTION, .{.select=.{WindowSel, 0}});
                cwin.AddAttribute(df.VSCROLLBAR);
                q.PostMessage(cwin, df.SHOW_WINDOW, q.none);
            } else {
                return false;
            }
        },
        df.COMMAND => {
            const cmd:c = params.command[0];
            const p2:usize = params.command[1];
            switch (cmd) {
                .ID_OK => {
                    if (p2 == 0) {
                        const val:?usize = null;
                        const control = DialogBox.ControlWindow(&Dialogs.Windows, .ID_WINDOWLIST);
                        if (control) |cwin| {
                            _ = cwin.sendMessage(df.LB_CURRENTSELECTION, .{.usize_addr=@constCast(&val)});
                            WindowSel = val orelse 0;
                        }

                    }
                },
                .ID_WINDOWLIST => {
                    if (p2 == df.LB_CHOOSE)
                        _ = win.sendCommandMessage(.ID_OK, 0);
                },
                else => {
                }
            }
        },
        else => {
        }
    }
    return root.DefaultWndProc(win, msg, params);
}
        

// ---- the More Windows command on the Window menu ----
fn MoreWindows(win:*Window) void {
    if (DialogBox.create(win, &Dialogs.Windows, df.TRUE, WindowPrep))
        ChooseWindow(win, WindowSel);
}

// ----- user chose a window from the Window menu
//        or the More Window dialog box ----- 
fn ChooseWindow(win:*Window, WindowNo:usize) void {
    var counter = WindowNo;
    var cwin = win.firstWindow();
    while (cwin) |cw| {
        if (cw.isVisible() and
                        cw.getClass() != k.MENUBAR and
                        cw.getClass() != k.STATUSBAR) {
            if (counter == 0)
                break;
            counter -= 1;
        }
        cwin = cw.nextWindow();
    }
    if (cwin) |cw| {
        _ = cw.sendMessage(df.SETFOCUS, .{.yes=true});
        if (cw.condition == .ISMINIMIZED)
            _ = cw.sendMessage(df.RESTORE, q.none);
    }
}

fn DoWindowColors(win:*Window) void {
    win.InitWindowColors();
    var cwin = win.firstWindow();
    while (cwin) |cw| {
        const cwnd = cw.win;
        DoWindowColors(cw);
        if ((cw.getClass() == k.TEXT) and df.GetText(cwnd) != null) {
            _ = cw.sendMessage(df.CLEARTEXT, q.none);
        }
        cwin = cw.nextWindow();
    }
}

// ----- set up colors for the application window ------
fn SelectColors(win: *Window) void {
    if (radio.RadioButtonSetting(&Dialogs.Display, .ID_MONO)) {
        cfg.config.mono = 1;   // mono
    } else if (radio.RadioButtonSetting(&Dialogs.Display, .ID_REVERSE)) {
        cfg.config.mono = 2;   // mono reverse
    } else {
        cfg.config.mono = 0;   // color
    }

    if (cfg.config.mono == 1) {
//        @memcpy(&cfg.config.clr, &Colors.bw);
        cfg.config.clr = Colors.bw;
    } else if (cfg.config.mono == 2) {
//        @memcpy(&cfg.config.clr, &Colors.reverse);
        cfg.config.clr = Colors.reverse;
    } else {
//        @memcpy(&cfg.config.clr, &Colors.color);
        cfg.config.clr = Colors.color;
    }
    DoWindowColors(win);
}

// ---- select screen lines ----
fn SelectLines(win:*Window) void {
    cfg.config.ScreenLines = @intCast(df.SCREENHEIGHT);
    if (df.SCREENHEIGHT != cfg.config.ScreenLines) {
        SetScreenHeight(@intCast(cfg.config.ScreenLines));
        // ---- re-maximize ----
        if (win.condition == .ISMAXIMIZED) {
            _ = win.sendMessage(df.SIZE, .{.position=.{win.GetRight(), @intCast(df.SCREENHEIGHT-1)}});
            return;
        }
        // --- adjust if current size does not fit ---
        if (win.WindowHeight() > df.SCREENHEIGHT) {
            _ = win.sendMessage(df.SIZE, .{.position=.{win.GetRight(),
                win.GetTop()+@as(usize, @intCast(df.SCREENHEIGHT-1))}});
        }
        // --- if window is off-screen, move it on-screen ---
        if (win.GetTop() >= df.SCREENHEIGHT-1) {
            _ = win.sendMessage(df.MOVE, .{.position=.{win.GetLeft(),
                    @as(usize, @intCast(df.SCREENHEIGHT))-win.WindowHeight()}});
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
    cfg.config.Texture = checkbox.CheckBoxSetting(&Dialogs.Display, .ID_TEXTURE);
}

// -- select whether the application screen has a border --
fn SelectBorder(win: *Window) void {
    cfg.config.Border = checkbox.CheckBoxSetting(&Dialogs.Display, .ID_BORDER);
    if (cfg.config.Border) {
        win.AddAttribute(df.HASBORDER);
    } else {
        win.ClearAttribute(df.HASBORDER);
    }
}

// select whether the application screen has a status bar
fn SelectStatusBar(win: *Window) void {
    cfg.config.StatusBar = checkbox.CheckBoxSetting(&Dialogs.Display, .ID_STATUSBAR);
    if (cfg.config.StatusBar) {
        win.AddAttribute(df.HASSTATUSBAR);
    } else {
        win.ClearAttribute(df.HASSTATUSBAR);
    }
}

// select whether the application screen has a title bar
fn SelectTitle(win: *Window) void {
    cfg.config.Title = checkbox.CheckBoxSetting(&Dialogs.Display, .ID_TITLE);
    if (cfg.config.Title) {
        win.AddAttribute(df.HASTITLEBAR);
    } else {
        win.ClearAttribute(df.HASTITLEBAR);
    }
}

// -------- Create the menu bar --------
fn CreateMenu(win: *Window) void {
    win.AddAttribute(df.HASMENUBAR);
    if (win.MenuBar) |mb| {
        _ = mb.sendMessage(df.CLOSE_WINDOW, .{.yes=false});
    }
    var mwnd = Window.create(k.MENUBAR,
                        null,
                        win.GetClientLeft(),
                        win.GetClientTop()-1,
                        1,
                        win.ClientWidth(),
                        null,
                        win,
                        null,
                        0, .{});

    win.MenuBar = mwnd;

    if (win.extension) |extension| {
        _ = mwnd.sendMessage(df.BUILDMENU, .{.menubar=extension.menubar});
    }
    mwnd.AddAttribute(df.VISIBLE);
}


// ----------- Create the status bar -------------
fn CreateStatusBar(win: *Window) void {
    if (win.StatusBar) |sb| {
        _ = sb.sendMessage(df.CLOSE_WINDOW, .{.yes=false});
        win.StatusBar = null;
    }
    if (win.TestAttribute(df.HASSTATUSBAR)) {
        var sbar = Window.create(k.STATUSBAR,
                            null,
                            win.GetClientLeft(),
                            win.GetBottom(),
                            1,
                            win.ClientWidth(),
                            null,
                            win,
                            null,
                            0, .{});
        win.StatusBar = sbar;
        sbar.AddAttribute(df.VISIBLE);
    }
}

// SHELLDOS
fn SwitchCursor() void {
    _ = q.SendMessage(null, df.SAVE_CURSOR, q.none);
    console.SwapCursorStack();
    _ = q.SendMessage(null, df.RESTORE_CURSOR, q.none);
}

// ------- Shell out to DOS ----------
fn ShellDOS(win:*Window) void {
    oldFocus = Window.inFocus;
    _ = win.sendMessage(df.HIDE_WINDOW, q.none);
    SwitchCursor();
    if (ScreenHeight != df.SCREENHEIGHT)
        SetScreenHeight(ScreenHeight);
    _ = q.SendMessage(null, df.HIDE_MOUSE, q.none);
    _ = df.fflush(df.stdout);
    df.tty_restore();
    _ = df.runshell();
    df.tty_enable_unikey();

    if (df.SCREENHEIGHT != cfg.config.ScreenLines)
        SetScreenHeight(@intCast(cfg.config.ScreenLines));
    SwitchCursor();
    _ = win.sendMessage(df.SHOW_WINDOW, q.none);
    if (oldFocus) |focus| {
        _ = focus.sendMessage(df.SETFOCUS, .{.yes=true});
    }
    _ = q.SendMessage(null, df.SHOW_MOUSE, q.none);
}
