const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");

var py:c_int = -1;
var CurrentMenuSelection:c_int = 0;

// ------------ CREATE_WINDOW Message -------------
fn CreateWindowMsg(win:*Window) c_int {
    const wnd = win.win;
    win.ClearAttribute(df.HASTITLEBAR  |
                       df.VSCROLLBAR   |
                       df.MOVEABLE     |
                       df.SIZEABLE     |
                       df.HSCROLLBAR);
    // ------ adjust to keep popdown on screen -----
    var adj:c_int = df.SCREENHEIGHT-1-wnd.*.rc.bt;
    if (adj < 0) {
        wnd.*.rc.tp += adj;
        wnd.*.rc.bt += adj;
    }
    adj = df.SCREENWIDTH-1-wnd.*.rc.rt;
    if (adj < 0) {
        wnd.*.rc.lf += adj;
        wnd.*.rc.rt += adj;
    }
    const rtn = root.zBaseWndProc(df.POPDOWNMENU, win, df.CREATE_WINDOW, 0, 0);
    _ = win.sendMessage(df.CAPTURE_MOUSE, 0, 0);
    _ = win.sendMessage(df.CAPTURE_KEYBOARD, 0, 0);
    _ = q.SendMessage(null, df.SAVE_CURSOR, 0, 0);
    _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
    wnd.*.oldFocus = df.inFocus;
    df.inFocus = wnd;
    return rtn;
}

// --------- LEFT_BUTTON Message ---------
fn LeftButtonMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    const my:c_int = @intCast(p2 - win.GetTop());
    if (rect.InsideRect(@intCast(p1), @intCast(p2), rect.ClientRect(win))) {
        if (my != py) {
            _ = win.sendMessage(df.LB_SELECTION,
                    @intCast(wnd.*.wtop+my-1), df.TRUE);
            py = my;
        }
    } else {
        const parent = Window.GetParent(wnd);
        if (Window.get_zin(parent)) |prt| {
            if (p2 == prt.GetTop()) {
                if (df.GetClass(parent) == df.MENUBAR) {
                    q.PostMessage(parent, df.LEFT_BUTTON, p1, p2);
                }
            }
        }
    }
}

// -------- BUTTON_RELEASED Message --------
fn ButtonReleasedMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    py = -1;
    if (rect.InsideRect(@intCast(p1), @intCast(p2), rect.ClientRect(win))) {
        const sel:c_uint = @intCast(p2 - win.GetClientTop());
        const tl = df.TextLine(wnd, sel);
        if (tl[0] != df.LINE)
            _ = win.sendMessage(df.LB_CHOOSE, @intCast(wnd.*.selection), 0);
    } else {
        const pwnd = Window.GetParent(wnd);
        if (Window.get_zin(pwnd)) |ptr| {
            if ((df.GetClass(pwnd) == df.MENUBAR) and (p2==ptr.GetTop()))
                return false;
            if (p1 == ptr.GetLeft()+2)
                return false;
        }
        _ = win.sendMessage(df.CLOSE_WINDOW, 0, 0);
        return true;
    }
    return false;
}

// - Window processing module for POPDOWNMENU window class -
pub fn PopDownProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win);
        },
        df.LEFT_BUTTON => {
            LeftButtonMsg(win, p1, p2);
            return df.FALSE;
        },
        df.DOUBLE_CLICK => {
            return df.TRUE;
        },
        df.LB_SELECTION => {
            const sel:c_uint = @intCast(p1);
            const l = df.TextLine(wnd, sel);
            if (l[0] == df.LINE) {
                return df.TRUE;
            }
            wnd.*.mnu.*.Selection = @intCast(p1);
        },
        df.BUTTON_RELEASED => {
            if (ButtonReleasedMsg(win, p1, p2))
                return df.TRUE;
        },
//        case BUILD_SELECTIONS:
//            wnd->mnu = (void *) p1;
//            wnd->selection = wnd->mnu->Selection;
//            break;
//        case PAINT:
//            if (wnd->mnu == NULL)
//                return TRUE;
//            PaintMsg(wnd);
//            break;
//        case BORDER:
//            return BorderMsg(wnd);
//        case LB_CHOOSE:
//            LBChooseMsg(wnd, p1);
//            return TRUE;
//        case KEYBOARD:
//            if (KeyboardMsg(wnd, p1, p2))
//                return TRUE;
//            break;
//case CLOSE_WINDOW:
//        return CloseWindowMsg(wnd);
        else => {
            return df.cPopDownProc(wnd, msg, p1, p2);
        }
    }
    return root.zBaseWndProc(df.POPDOWNMENU, win, msg, p1, p2);
}
