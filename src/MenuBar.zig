const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");

// positions in menu bar & shortcut key value
var menu = [_]struct{x1:isize, x2:isize, sc:u8} {.{.x1=-1, .x2=-1, .sc=0}}**10;
var mctr:usize = 0;
var mwnd:?df.WINDOW = null;

// Temporary
//pub export fn menu_set_x1(idx:usize, val:isize) callconv(.c) void {
//    menu[idx].x1 = val;
//    if (mctr < (idx+1))
//        mctr = idx+1;
//}

pub export fn menu_get_x1(idx:usize) callconv(.c) isize {
    return menu[idx].x1;
}

//pub export fn menu_set_x2(idx:usize, val:isize) callconv(.c) void {
//    menu[idx].x2 = val;
//}

pub export fn menu_get_x2(idx:usize) callconv(.c) isize {
    return menu[idx].x2;
}

//pub export fn menu_set_sc(idx:usize, val:u8) callconv(.c) void {
//    menu[idx].sc = val;
//}

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
    const len = df.strlen(wnd.*.text);
    if (root.global_allocator.dupe(u8, wnd.*.text[0..len])) |buf| {
        const b:[*c]u8 = buf.ptr;
        var offset:isize = 3;
        var idx:usize = 0;
        const pp1:usize = @intCast(p1);
        df.ActiveMenuBar = @ptrFromInt(pp1);
//        df.ActiveMenu = &df.ActiveMenuBar.*.PullDown;
        for(df.ActiveMenuBar.*.PullDown) |m| {
            if (m.Title) |title| {
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
//                cp = strchr(title, SHORTCUTCHAR);
//                if (cp) {
//            menu[mctr].sc = tolower(*(cp+1));
//                menu_set_sc(idx, tolower(*(cp+1)));
                idx += 1;
                mctr += 1;
            }
        }

        df.ActiveMenu = &df.ActiveMenuBar.*.PullDown;
        wnd.*.text = b;
    } else |_| {
        // error 
    }
}

// ---------- PAINT Message ----------
fn PaintMsg(win:*Window) void {
    const wnd = win.win;
    df.cPaintMsg(wnd);
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

// ---------------- CLOSE_WINDOW Message ---------------
fn CloseWindowMsg(win:*Window) void {
    const wnd = win.win;
    if (wnd.*.text) |text| {
        const len = df.strlen(wnd.*.text);
        root.global_allocator.free(text[0..len]); // off by 1 ?
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
//        case BORDER:
//                    if (mwnd == NULL)
//                                SendMessage(wnd, PAINT, 0, 0);
//            return TRUE;
//        case KEYBOARD:
//            KeyboardMsg(wnd, p1);
//            return TRUE;
        df.LEFT_BUTTON => {
            LeftButtonMsg(win, p1);
            return df.TRUE;
        },
//        case MB_SELECTION:
//            SelectionMsg(wnd, p1, p2);
//            break;
//        case COMMAND:
//            CommandMsg(wnd, p1, p2);
//            return TRUE;
        df.INSIDE_WINDOW => {
            return if (rect.InsideRect(@intCast(p1), @intCast(p2), win.WindowRect())) df.TRUE else df.FALSE;
        },
//        case CLOSE_POPDOWN:
//            ClosePopdownMsg(wnd);
//            return TRUE;
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
    if (wnd.*.text == null) {
        if (root.global_allocator.alloc(u8, @intCast(df.SCREENWIDTH+5))) |b| {
            @memset(b, ' ');
            wnd.*.text = b.ptr;
        } else |_| {
            // error
        }
    } else {
        const len = df.strlen(wnd.*.text); // off by 1?
        if (root.global_allocator.realloc(wnd.*.text[0..len], @intCast(df.SCREENWIDTH+5))) |b| {
            @memset(b, ' ');
            wnd.*.text = b.ptr;
        } else |_| {
            // error
        }
    }
    wnd.*.text[@intCast(win.WindowWidth())] = 0;
}
