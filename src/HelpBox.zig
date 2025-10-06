const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const WndProc = @import("WndProc.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;
const k = @import("Classes.zig").CLASS;
const lists = @import("Lists.zig");
const normal = @import("Normal.zig");

const MAXHELPKEYWORDS = 50; // --- maximum keywords in a window ---
const MAXHELPSTACK = 100;

var HelpStack = [_]usize{0}**MAXHELPSTACK;
var stacked:usize = 0;

var ThisHelp:?*df.helps = null;

// ------------- CREATE_WINDOW message ------------
fn CreateWindowMsg(win:*Window) void {
    const wnd = win.win;
    df.Helping = df.TRUE;
    win.Class = k.HELPBOX;
    win.InitWindowColors();
    if (ThisHelp) |help| {
        help.*.hwnd = wnd;
    }
}

// -------- read the help text into the editbox -------
pub export fn ReadHelp(wnd:df.WINDOW) callconv(.c) void {
    const dbox:*Dialogs.DBOX = @ptrCast(@alignCast(wnd.*.extension));
    if (DialogBox.ControlWindow(dbox, c.ID_HELPTEXT)) |cwin| {
        cwin.wndproc = HelpTextProc;
        _ = cwin.sendMessage(df.CLEARTEXT, 0, 0);
        df.cReadHelp(wnd, cwin.win);
    }
}

// ------------- COMMAND message ------------
fn CommandMsg(win: *Window, p1:df.PARAM) bool {
    const wnd = win.win;
    const cmd:c = @enumFromInt(p1);
    switch (cmd) {
        c.ID_PREV => {
            if (ThisHelp) |help| {
                const prevhlp:usize = @intCast(help.*.prevhlp);
                SelectHelp(wnd, df.FirstHelp+prevhlp, df.TRUE);
            }
            return true;
        },
        c.ID_NEXT => {
            if (ThisHelp) |help| {
                const nexthlp:usize = @intCast(help.*.nexthlp);
                SelectHelp(wnd, df.FirstHelp+nexthlp, df.TRUE);
            }
            return true;
        },
        c.ID_BACK => {
            if (stacked > 0) {
                stacked -= 1;
                const stked:usize = stacked;
                const helpstack:usize = HelpStack[stked];
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
        if (DialogBox.ControlWindow(dbox, c.ID_HELPTEXT)) |cwin| {
            if (Window.inFocus == cwin) {
                return if (df.cHelpBoxKeyboardMsg(wnd, cwin.win, p1) == df.TRUE) true else false;
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
            if (normal.WindowMoving == false) {
                if (HelpBoxKeyboardMsg(win, p1))
                    return true;
            }
        },
        df.CLOSE_WINDOW => {
            if (ThisHelp) |help| {
                help.*.hwnd = null;
            }
            df.Helping = df.FALSE;
        },
        else => {
        }
    }
    return root.BaseWndProc(k.HELPBOX, win, msg, p1, p2);
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

    for (input) |cc| {
        if (cc != tilde) {
            buffer[i] = cc;
            i += 1;
        }
    }
    return buffer[0..i];
}

// --- return the comment associated with a help window ---
// not in use, should be private
fn HelpComment(Help:[]const u8) [*c]u8 {
    var buffer:[30]u8 = undefined;
    @memset(&buffer, 0);

    const FixedHelp = StripTildes(Help, &buffer);
    ThisHelp = df.FindHelp(@constCast(FixedHelp.ptr));
    if (ThisHelp) |help| {
        return help.*.comment;
    }
    return null;
}

// ---------- display help text -----------
pub fn DisplayHelp(win:*Window, Help:[]const u8) bool {
    var buffer:[30]u8 = undefined;
    var rtn = false;

    @memset(&buffer, 0);

    if (df.Helping > 0)
        return true;

    const FixedHelp = StripTildes(Help, &buffer);

    win.isHelping += 1;
    ThisHelp = df.FindHelp(@constCast(FixedHelp.ptr));
    if (ThisHelp) |thisHelp| {
        _ = thisHelp;
        df.helpfp = df.OpenHelpFile(&df.HelpFileName, "rb");
        if (df.helpfp) |_| {
            BuildHelpBox(win);
            DialogBox.DisableButton(&Dialogs.HelpBox, c.ID_BACK);

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
    win.isHelping -= 1;
    return rtn;
}

// ------- display a definition window --------- 
// This one does not work properly from origin
pub export fn DisplayDefinition(wnd:df.WINDOW, def:[*c]u8) void { // should be private
    const MAXHEIGHT = df.SCREENHEIGHT-10;
    const HoldThisHelp = ThisHelp;
    var hwnd = wnd;

    if (Window.get_zin(wnd)) |win| {
        if (win.Class == k.POPDOWNMENU) {
            hwnd = if (win.parent) |pw| pw.win else null;
        }
    }

    ThisHelp = df.FindHelp(def);
    if (Window.get_zin(hwnd)) |hwin| {
        const y:c_int = if (hwin.Class == k.MENUBAR) 2 else 1;
        if (ThisHelp) |help| {
            const dwnd = df.CreateWindow(
                        @intFromEnum(k.TEXTBOX),
                        null,
                        @intCast(hwin.GetClientLeft()),
                        @intCast(hwin.GetClientTop()+y),
                        @min(help.*.hheight, MAXHEIGHT)+3,
                        @intCast(help.*.hwidth+2),
                        null,
                        wnd,
                        df.HASBORDER | df.NOCLIP | df.SAVESELF);
            if (dwnd != null) {
//                df.clearBIOSbuffer(); // no function
                // ----- read the help text -------
                df.SeekHelpLine(help.*.hptr, help.*.bit);
                while (true) {
//                    df.clearBIOSbuffer(); // no function
                    if (df.GetHelpLine(&df.hline) == null)
                        break;
                    if (df.hline[0] == '<')
                        break;
                    const len:usize = df.strlen(&df.hline);
                    df.hline[len] = 0;
                    _ = q.SendMessage(dwnd,df.ADDTEXT, @intCast(@intFromPtr(&df.hline)),0);
                }
                _ = q.SendMessage(dwnd, df.SHOW_WINDOW, 0, 0);
                _ = q.SendMessage(null, df.WAITKEYBOARD, 0, 0);
                _ = q.SendMessage(null, df.WAITMOUSE, 0, 0);
                _ = q.SendMessage(dwnd, df.CLOSE_WINDOW, 0, 0);
            }
        }
    }
    ThisHelp = HoldThisHelp;
}

fn BuildHelpBox(win:?*Window) void {
    const MAXHEIGHT = df.SCREENHEIGHT-10;

    if (ThisHelp) |help| {
        // -- seek to the first line of the help text --
        df.SeekHelpLine(help.*.hptr, help.*.bit);

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
        Dialogs.HelpBox.dwnd.h = @min(help.*.hheight, MAXHEIGHT)+7;
        Dialogs.HelpBox.dwnd.w = @max(45, help.*.hwidth+6);

        // ------ position the help window -----
        if (win) |w| {
            BestFit(w, &Dialogs.HelpBox.dwnd);
        }
        // ------- position the command buttons ------ 
        Dialogs.HelpBox.ctl[0].dwnd.w = @max(40, help.*.hwidth+2);
        Dialogs.HelpBox.ctl[0].dwnd.h =
                    @min(help.*.hheight, MAXHEIGHT)+2;
        const offset = @divFloor(Dialogs.HelpBox.dwnd.w-40, 2);
        for (1..5) |i| {
            const ii:c_int = @intCast(i);
            Dialogs.HelpBox.ctl[i].dwnd.y =
                            @min(help.*.hheight, MAXHEIGHT)+3;
            Dialogs.HelpBox.ctl[i].dwnd.x = (ii-1) * 10 + offset;
        }

        // ---- disable ineffective buttons ----
        if (help.*.nexthlp == -1) {
            DialogBox.DisableButton(&Dialogs.HelpBox, c.ID_NEXT);
        } else {
            DialogBox.EnableButton(&Dialogs.HelpBox, c.ID_NEXT);
        }
        if (help.*.prevhlp == -1) {
            DialogBox.DisableButton(&Dialogs.HelpBox, c.ID_PREV);
        } else {
            DialogBox.EnableButton(&Dialogs.HelpBox, c.ID_PREV);
        }
    }
}

// ----- select a new help window from its name -----
pub export fn SelectHelp(wnd:df.WINDOW, newhelp:[*c]df.helps, recall:df.BOOL) callconv(.c) void {
    if (newhelp != null) {
        if (Window.get_zin(wnd)) |win| {
            _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);

            if (ThisHelp) |help| {
                if (recall>0 and stacked < df.MAXHELPSTACK) {
                    HelpStack[stacked] = help-df.FirstHelp;
                    stacked += 1;
                }
                ThisHelp = newhelp;
                _ = win.getParent().sendMessage(df.DISPLAY_HELP, @intCast(@intFromPtr(help.*.hname)), 0);
            }

            if (stacked>0) {
                DialogBox.EnableButton(&Dialogs.HelpBox, c.ID_BACK);
            } else {
                DialogBox.DisableButton(&Dialogs.HelpBox, c.ID_BACK);
            }
            BuildHelpBox(null);
            if (Dialogs.HelpBox.dwnd.title) |ttl| {
//                df.AddTitle(wnd, ttl.ptr);
                win.AddTitle(ttl);
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
                var x = Dialogs.HelpBox.ctl[i].dwnd.x+win.GetClientLeft();
                var y = Dialogs.HelpBox.ctl[i].dwnd.y+win.GetClientTop();
                const cw = Dialogs.HelpBox.ctl[i].win;
                if (cw) |cwin| {
                    _ = cwin.sendMessage(df.MOVE, x, y);
                }
                if (i == 0) {
                    x += Dialogs.HelpBox.ctl[i].dwnd.w - 1;
                    y += Dialogs.HelpBox.ctl[i].dwnd.h - 1;
                    if (cw) |cwin| {
                        _ = cwin.sendMessage(df.SIZE, x, y);
                    }
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
    if (win.getClass() == k.MENUBAR or
        win.getClass() == k.APPLICATION) {
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
 
