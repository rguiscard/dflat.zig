const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");

// ------- Window processing module for EDITBOX class ------ 
pub fn EditorProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    switch (msg) {
//                case KEYBOARD:
//            if (KeyboardMsg(wnd, p1, p2))
//                return TRUE;
//            break;
//                case SETTEXT:
//                        return SetTextMsg(wnd, (char *) p1);
        else => {
            return df.cEditorProc(wnd, msg, p1, p2);
        }
    }
    return root.zBaseWndProc(df.EDITOR, win, msg, p1, p2);
}
