const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");

fn EditBufLen(win:*Window) c_uint {
    const wnd = win.win;
    return if (df.isMultiLine(wnd)>0) df.EDITLEN else df.ENTRYLEN;
}

// ----------- CREATE_WINDOW Message ----------
fn CreateWindowMsg(win:*Window) c_int {
    const wnd = win.win;
    const rtn = root.zBaseWndProc(df.EDITBOX, win, df.CREATE_WINDOW, 0, 0);
    wnd.*.MaxTextLength = df.MAXTEXTLEN+1;
    wnd.*.textlen = EditBufLen(win);
    wnd.*.InsertMode = df.TRUE;
    if (df.isMultiLine(wnd)>0)
        wnd.*.WordWrapMode = df.TRUE;
    _ = win.sendMessage(df.CLEARTEXT, 0, 0);
    return rtn;
}

pub fn EditBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win);
        },
//        case ADDTEXT:
//            return AddTextMsg(wnd, p1, p2);
//        case SETTEXT:
//            return SetTextMsg(wnd, p1);
//        case CLEARTEXT:
//                        return ClearTextMsg(wnd);
//        case GETTEXT:
//            return GetTextMsg(wnd, p1, p2);
//        case SETTEXTLENGTH:
//            return SetTextLengthMsg(wnd, (unsigned) p1);
//        case KEYBOARD_CURSOR:
//            KeyboardCursorMsg(wnd, p1, p2);
//                        return TRUE;
//        case SETFOCUS:
//                        if (!(int)p1)
//                                SendMessage(NULL, HIDE_CURSOR, 0, 0);
//        case PAINT:
//        case MOVE:
//            rtn = BaseWndProc(EDITBOX, wnd, msg, p1, p2);
//            SendMessage(wnd,KEYBOARD_CURSOR,WndCol,wnd->WndRow);
//            return rtn;
//        case SIZE:
//            return SizeMsg(wnd, p1, p2);
//        case SCROLL:
//            return ScrollMsg(wnd, p1);
//        case HORIZSCROLL:
//            return HorizScrollMsg(wnd, p1);
//        case SCROLLPAGE:
//            return ScrollPageMsg(wnd, p1);
//        case HORIZPAGE:
//            return HorizPageMsg(wnd, p1);
//        case LEFT_BUTTON:
//            if (LeftButtonMsg(wnd, p1, p2))
//                return TRUE;
//            break;
//        case MOUSE_MOVED:
//            if (MouseMovedMsg(wnd, p1, p2))
//                return TRUE;
//            break;
//        case BUTTON_RELEASED:
//            if (ButtonReleasedMsg(wnd))
//                return TRUE;
//            break;
//        case KEYBOARD:
//            if (KeyboardMsg(wnd, p1, p2))
//                return TRUE;
//            break;
//        case SHIFT_CHANGED:
//            ShiftChangedMsg(wnd, p1);
//            break;
//        case COMMAND:
//            if (CommandMsg(wnd, p1))
//                return TRUE;
//            break;
//        case CLOSE_WINDOW:
//            return CloseWindowMsg(wnd, p1, p2);
        else => {
            return df.cEditBoxProc(wnd, msg, p1, p2);
        }
    }
    return root.zBaseWndProc(df.EDITBOX, win, msg, p1, p2);
}
