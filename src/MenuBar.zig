const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");

// positions in menu bar & shortcut key value
var menu = [_]struct{x1:isize, x2:isize, sc:u8} {.{.x1=-1, .x2=-1, .sc=0}}**10;
var mctr:usize = 0;
var mwnd:df.WINDOW = null;
var Selecting:bool = false;
var Cascaders = [_]df.WINDOW{0}**df.MAXCASCADES;
var casc:usize = 0;

pub export fn get_selecting() c_int {
    return if(Selecting) df.TRUE else df.FALSE;
} 

pub export fn set_selecting(val:c_int) void {
    Selecting = if (val > 0) true else false;
}

pub export fn menu_get_x1(idx:usize) callconv(.c) isize {
    return menu[idx].x1;
}

pub export fn menu_get_x2(idx:usize) callconv(.c) isize {
    return menu[idx].x2;
}

pub export fn menu_get_sc(idx:usize) callconv(.c) u8 {
    return menu[idx].sc;
}

pub export fn get_mctr() callconv(.c) usize {
    return mctr;
}

// ----------- SETFOCUS Message -----------
fn SetFocusMsg(win:*Window,p1:df.PARAM) c_int {
    const wnd = win.win;
    const rtn = root.zBaseWndProc(df.MENUBAR, win, df.SETFOCUS, p1, 0);
    if (p1>0) {
        _ = q.SendMessage(Window.GetParent(wnd), df.ADDSTATUS, 0, 0);
    } else {
        _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
    }
    return rtn;
}

// --------- BUILDMENU Message ---------
fn BuildMenuMsg(win:*Window, p1:df.PARAM) void {
    const wnd = win.win;
    reset_menubar(win);
    if (win.text) |buf| {
        const b:[*c]u8 = buf.ptr;
        var offset:isize = 3;
        var idx:usize = 0;
        const pp1:usize = @intCast(p1);
        df.ActiveMenuBar = @ptrFromInt(pp1);
        for(df.ActiveMenuBar.*.PullDown) |m| {
            if (m.Title) |title| {
                // FIX: this method realloc buf, may cause memory leak.
                const rtn = df.cBuildMenu(wnd, title, @intCast(offset), @constCast(&b));
                if (rtn == df.FALSE) {
                    break;
                }
                menu[idx].x1 = offset;
                offset += @intCast(df.strlen(title) + (3+df.MSPACE));
                menu[idx].x2 = offset-df.MSPACE;

                const l = df.strlen(title);
                if (std.mem.indexOfScalar(u8, title[0..l], df.SHORTCUTCHAR)) |pos| {
                    menu[idx].sc = std.ascii.toLower(title[pos+1]);
                }
                idx += 1;
                mctr += 1;
            }
        }

        df.ActiveMenu = &df.ActiveMenuBar.*.PullDown;
        wnd.*.text = b;
    } else {
        // error 
    }
}

// ---------- PAINT Message ----------
fn PaintMsg(win:*Window) void {
    const wnd = win.win;
    if (Selecting)
        return;
    if (wnd == df.inFocus) {
        _ = q.SendMessage(Window.GetParent(wnd), df.ADDSTATUS, 0, 0);
    }
    df.SetStandardColor(wnd);
    df.wputs(wnd, wnd.*.text, 0, 0);

    if ((df.ActiveMenuBar != null) and (df.ActiveMenuBar.*.ActiveSelection != -1) and
            ((wnd == df.inFocus) or (mwnd != null))) {

        const offset=menu[@intCast(df.ActiveMenuBar.*.ActiveSelection)].x1;
        const offset1=menu[@intCast(df.ActiveMenuBar.*.ActiveSelection)].x2;

        wnd.*.text[@intCast(offset1)] = 0;
        df.SetReverseColor(wnd);
        df.cPaintMenu(wnd, @intCast(offset), @intCast(offset1), df.ActiveMenuBar.*.ActiveSelection);

        if ((mwnd == null) and (wnd == df.inFocus)) {
            const st = df.ActiveMenu[@intCast(df.ActiveMenuBar.*.ActiveSelection)].StatusText;
            if (st) |txt| {
                _ = q.SendMessage(Window.GetParent(wnd), df.ADDSTATUS,
                    @intCast(@intFromPtr(txt)), 0);
            }
        }
    }
}

// --------------- LEFT_BUTTON Message ----------
fn LeftButtonMsg(win:*Window,p1:df.PARAM) void {
    const mx = p1-win.GetLeft();
    // --- compute the selection that the left button hit ---
    for (menu, 0..) |m, idx| {
        if (m.x1 == -1) {
            break; // out of range
        }
        const i:isize = @intCast(idx);
        if ((mx >= menu[idx].x1-4*i) and
               (mx <= menu[idx].x2-4*i-5)) {
            if ((idx != df.ActiveMenuBar.*.ActiveSelection) or (mwnd == null)) {
                _ = win.sendMessage(df.MB_SELECTION, i, 0);
            }
            break;
        }
    }
}

// -------------- MB_SELECTION Message --------------
fn SelectionMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    var mx:c_int = 0;
    var my:c_int = 0;

    if (p2 == 0) {
        df.ActiveMenuBar.*.ActiveSelection = -1;
        _ = win.sendMessage(df.PAINT, 0, 0);
    }
    Selecting = true;
    // should use Menu or Menu* ?
    const mnu = df.ActiveMenu[@intCast(p1)];
    if (mnu.PrepMenu) |proc| {
        proc(df.GetDocFocus(), @constCast(&mnu));
    }
    const wd = df.MenuWidth(@constCast(&mnu.Selections));
    if (p2>0) {
        const brd = win.GetRight();
        if (Window.get_zin(mwnd)) |zin| { // assume mwnd exist ?
            mx = @intCast(zin.GetLeft() + zin.WindowWidth() - 1);
            if (mx + wd > brd) {
                mx = @intCast(brd - wd);
            }
            my = @intCast(zin.GetTop() + mwnd.*.selection);
        }
    } else {
        var offset = menu[@intCast(p1)].x1 - 4 * p1;
        if (mwnd != null)
            _ = q.SendMessage(mwnd, df.CLOSE_WINDOW, 0, 0);
            df.ActiveMenuBar.*.ActiveSelection = @intCast(p1);
        if (offset > win.WindowWidth()-wd) {
            offset = win.WindowWidth()-wd;
        }
        mx = @intCast(win.GetLeft()+offset);
        my = @intCast(win.GetTop()+1);
    }
    const mwin = Window.create(df.POPDOWNMENU, null,
                mx, my,
                df.MenuHeight(@constCast(&mnu.Selections)),
                wd,
                null,
                win.win,
                null,
                df.SHADOW);
    mwnd = mwin.win;
    if (p2 == 0) {
        Selecting = false;
        _ = win.sendMessage(df.PAINT, 0, 0);
        Selecting = true;
    }
    if (mnu.Selections[0].SelectionTitle != null)    {
        _ = mwin.sendMessage(df.BUILD_SELECTIONS, @intCast(@intFromPtr(&mnu)), 0);
        _ = mwin.sendMessage(df.SETFOCUS, df.TRUE, 0);
        _ = mwin.sendMessage(df.SHOW_WINDOW, 0, 0);
    }
    Selecting = false;
}

// --------- COMMAND Message ----------
fn CommandMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    if (p1 == df.ID_HELP) {
        _ = root.zBaseWndProc(df.MENUBAR, win, df.COMMAND, p1, p2);
        return;
    }
    if (df.isCascadedCommand(df.ActiveMenuBar, @intCast(p1))>0) {
        // FIXME: Cascade menu will show, but command will not be sent.
        // Could possibly to title is not (void*)-1, but null.
        //
        // find the cascaded menu based on command id in p1
        for(df.ActiveMenuBar.*.PullDown[mctr..], mctr..) |mnu, del| {
            if ((mnu.CascadeId != -1) and // instead of using -1 for title, check CascadeId.
                (mnu.CascadeId == p1)) {
                    if (casc < df.MAXCASCADES) {
                        Cascaders[casc] = mwnd;
                        casc += 1;
                        _ = win.sendMessage(df.MB_SELECTION, @intCast(del), df.TRUE);
                    }
                    break;
            }
        }
    } else {
        if (mwnd) |mm| {
            _ = q.SendMessage(mm, df.CLOSE_WINDOW, 0, 0);
        }
        _ = q.SendMessage(df.GetDocFocus(), df.SETFOCUS, df.TRUE, 0);
        q.PostMessage(Window.GetParent(wnd), df.COMMAND, p1, p2);
    }
}

// --------------- CLOSE_POPDOWN Message ---------------
fn ClosePopdownMsg(win:*Window) void {
    if (casc > 0) {
        casc -= 1;
        _ = q.SendMessage(Cascaders[casc], df.CLOSE_WINDOW, 0, 0);
    } else {
        mwnd = null;
        df.ActiveMenuBar.*.ActiveSelection = -1;
        if (Selecting == false) {
            _ = q.SendMessage(df.GetDocFocus(), df.SETFOCUS, df.TRUE, 0);
            _ = win.sendMessage(df.PAINT, 0, 0);
        }
    }
}

// ---------------- CLOSE_WINDOW Message ---------------
fn CloseWindowMsg(win:*Window) void {
    const wnd = win.win;
    if (win.text) |text| {
        root.global_allocator.free(text);
        win.text = null;
        wnd.*.text = null;
    }
    mctr = 0;
    df.ActiveMenuBar.*.ActiveSelection = -1;
    df.ActiveMenu = null;
    df.ActiveMenuBar = null;
}

pub fn MenuBarProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            reset_menubar(win);
        },
        df.SETFOCUS => {
            return SetFocusMsg(win, p1);
        },
        df.BUILDMENU => {
            BuildMenuMsg(win, p1);
        },
        df.PAINT => {
            if ((df.isVisible(wnd)>0) and (wnd.*.text != null)) {
                PaintMsg(win);
                return df.FALSE;
            }
        },
        df.BORDER => {
            if (mwnd == null) {
                _ = win.sendMessage(df.PAINT, 0, 0);
            }
            return df.TRUE;
        },
//        case KEYBOARD:
//            KeyboardMsg(wnd, p1);
//            return TRUE;
        df.LEFT_BUTTON => {
            LeftButtonMsg(win, p1);
            return df.TRUE;
        },
        df.MB_SELECTION => {
           SelectionMsg(win, p1, p2);
        },
        df.COMMAND => {
            CommandMsg(win, p1, p2);
            return df.TRUE;
        },
        df.INSIDE_WINDOW => {
            return if (rect.InsideRect(@intCast(p1), @intCast(p2), win.WindowRect())) df.TRUE else df.FALSE;
        },
        df.CLOSE_POPDOWN => {
            ClosePopdownMsg(win);
            return df.TRUE;
        },
        df.CLOSE_WINDOW => {
            const rtn = root.zBaseWndProc(df.MENUBAR, win, msg, p1, p2);
            CloseWindowMsg(win);
            return rtn;
        },
        else => {
            return df.cMenuBarProc(wnd, msg, p1, p2);
        }
    }
    return root.zBaseWndProc(df.MENUBAR, win, msg, p1, p2);
}

// ------------- reset the MENUBAR --------------
fn reset_menubar(win:*Window) void {
    const wnd = win.win;
    if (win.text) |text|{
        if (root.global_allocator.realloc(text, @intCast(df.SCREENWIDTH+5))) |b| {
            win.text= b;
        } else |_| {
            // error
        }
    } else {
        if (root.global_allocator.alloc(u8, @intCast(df.SCREENWIDTH+5))) |b| {
            win.text= b;
        } else |_| {
            // error
        }
    }
    if (win.text) |text| {
        @memset(text, ' ');
        wnd.*.text = text.ptr;
        wnd.*.text[text.len-1] = 0;
    }
    wnd.*.text[@intCast(win.WindowWidth())] = 0;
}
