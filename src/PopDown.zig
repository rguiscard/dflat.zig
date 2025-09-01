const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");

// - Window processing module for POPDOWNMENU window class -
pub fn PopDownProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    switch (msg) {
//        case CREATE_WINDOW:
//            return CreateWindowMsg(wnd);
//        case LEFT_BUTTON:
//            LeftButtonMsg(wnd, p1, p2);
//            return FALSE;
//        case DOUBLE_CLICK:
//            return TRUE;
//        case LB_SELECTION:
//            if (*TextLine(wnd, (int)p1) == LINE)
//                return TRUE;
//            wnd->mnu->Selection = (int)p1;
//            break;
//        case BUTTON_RELEASED:
//            if (ButtonReleasedMsg(wnd, p1, p2))
//                return TRUE;
//            break;
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
