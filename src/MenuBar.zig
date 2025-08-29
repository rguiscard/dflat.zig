const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");

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

pub fn MenuBarProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            df.reset_menubar(wnd);
        },
        df.SETFOCUS => {
            return SetFocusMsg(win, p1);
        },
//        case BUILDMENU:
//            BuildMenuMsg(wnd, p1);
//            break;
//        case PAINT:
//            if (!isVisible(wnd) || GetText(wnd) == NULL)
//                break;
//            PaintMsg(wnd);
//            return FALSE;
//        case BORDER:
//                    if (mwnd == NULL)
//                                SendMessage(wnd, PAINT, 0, 0);
//            return TRUE;
//        case KEYBOARD:
//            KeyboardMsg(wnd, p1);
//            return TRUE;
//        case LEFT_BUTTON:
//            LeftButtonMsg(wnd, p1);
//            return TRUE;
//        case MB_SELECTION:
//            SelectionMsg(wnd, p1, p2);
//            break;
//        case COMMAND:
//            CommandMsg(wnd, p1, p2);
//            return TRUE;
//        case INSIDE_WINDOW:
//            return InsideRect(p1, p2, WindowRect(wnd));
//        case CLOSE_POPDOWN:
//            ClosePopdownMsg(wnd);
//            return TRUE;
//        case CLOSE_WINDOW:
//            rtn = BaseWndProc(MENUBAR, wnd, msg, p1, p2);
//            CloseWindowMsg(wnd);
//            return rtn;
        else => {
            return df.cMenuBarProc(wnd, msg, p1, p2);
        }
    }
    return root.zBaseWndProc(df.MENUBAR, win, msg, p1, p2);
}
