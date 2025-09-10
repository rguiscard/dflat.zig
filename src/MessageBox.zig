const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const WndProc = @import("WndProc.zig");

const sOK      = "   Ok   ";
const sYES     = "   Yes  ";
const sNO      = "   No   ";
const sCancel  = " Cancel ";
const sERROR = "Error";
const sCONFIRM = "Confirm";
const sWait = "Wait...";

pub fn ErrorMessage(msg: [:0]const u8) bool {
    return GenericMessage(null, sERROR, msg, 1, ErrorBoxProc, sOK, null, df.ID_OK, 0, true);
}

pub fn MessageBox(title: [:0]const u8, msg: [:0]const u8) bool {
    return GenericMessage(null, title, msg, 1, MessageBoxProc, sOK, null, df.ID_OK, 0, true);
}

pub fn YesNoBox(msg: [:0]const u8) bool {
    return GenericMessage(null, sCONFIRM, msg, 2, YesNoBoxProc, sYES, sNO, df.ID_OK, df.ID_CANCEL, true);
}

pub fn CancelBox(wnd: df.WINDOW, msg: [:0]const u8) bool {
    return GenericMessage(wnd, sWait, msg, 1, CancelProc, sCancel, null, df.ID_CANCEL, 0, false);
}

fn GenericMessage(wnd: df.WINDOW, title: ?[:0]const u8, msg:[:0]const u8, buttonct: c_int,
                  wndproc: *const fn (win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool,
                  button1: ?[:0]const u8, button2: ?[:0]const u8, c1: c_int, c2: c_int, isModal: bool) bool {
    var mBox = Dialogs.MsgBox;

//    const ptr:[*c]u8 = @constCast(msg.ptr);
//    const m = std.mem.span(ptr);
    const m = msg;

    var ttl_w:c_int = 0;
    mBox.dwnd.title = null;
    if (title) |t| {
        ttl_w = @intCast(t.len+2);
//        const pp:[*c]u8 = @constCast(t.ptr);
//        mBox.dwnd.title = std.mem.span(pp);
        mBox.dwnd.title = t;
    }

    mBox.ctl[0].dwnd.h = MsgHeight(m);
    mBox.ctl[0].dwnd.w = @max(@max(MsgWidth(m), buttonct*8+buttonct+2),ttl_w);
    mBox.dwnd.h = mBox.ctl[0].dwnd.h+6;
    mBox.dwnd.w = mBox.ctl[0].dwnd.w+4;
    if (buttonct == 1) {
        mBox.ctl[1].dwnd.x = @divFloor((mBox.dwnd.w - 10), 2); // or @divTrunk ?
    } else {
        mBox.ctl[1].dwnd.x = @divFloor((mBox.dwnd.w - 20), 2); // or @divTrunk ?
        mBox.ctl[2].dwnd.x = mBox.ctl[1].dwnd.x + 10;
        mBox.ctl[2].Class = df.BUTTON;
    }

    mBox.ctl[1].dwnd.y = mBox.dwnd.h - 4;
    mBox.ctl[2].dwnd.y = mBox.dwnd.h - 4;
    mBox.ctl[0].itext = @constCast(m);
    mBox.ctl[1].itext = if (button1) |b| @constCast(b) else null;
    mBox.ctl[2].itext = if (button2) |b| @constCast(b) else null;
    mBox.ctl[1].command = @intCast(c1);
    mBox.ctl[2].command = @intCast(c2);
    mBox.ctl[1].isetting = df.ON;
    mBox.ctl[2].isetting = df.ON;

    
    const c_modal:df.BOOL = if (isModal) df.TRUE else df.FALSE;
    const rtn = DialogBox.DialogBox(wnd, &mBox, c_modal, wndproc);

    mBox.ctl[2].Class = 0;
    return rtn;
}

pub fn MomentaryMessage(msg: [:0]const u8) *Window {
    var win = Window.create(
                    df.TEXTBOX,
                    null,
                    -1,-1,MsgHeight(msg)+2,MsgWidth(msg)+2,
                    df.NULL,null,null,
                    df.HASBORDER | df.SHADOW | df.SAVESELF);
    const wnd = win.*.win;

    _ = win.sendTextMessage(df.SETTEXT, @constCast(msg), 0);
    if (df.cfg.mono == 0) {
        wnd.*.WindowColors[df.STD_COLOR][df.FG] = df.WHITE;
        wnd.*.WindowColors[df.STD_COLOR][df.BG] = df.GREEN;
        wnd.*.WindowColors[df.FRAME_COLOR][df.FG] = df.WHITE;
        wnd.*.WindowColors[df.FRAME_COLOR][df.BG] = df.GREEN;
    }
    _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
    return win;
}

fn MessageBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            wnd.*.Class = df.MESSAGEBOX;
            df.InitWindowColors(wnd);
            win.ClearAttribute(df.CONTROLBOX);
        },
        df.KEYBOARD => {
              //  This do nothing
//            if (p1 == '\r' or p1 == df.ESC)
//                ReturnValue = (int)p1;
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.MESSAGEBOX, win, msg, p1, p2);
}

fn YesNoBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            wnd.*.Class = df.MESSAGEBOX;
            df.InitWindowColors(wnd);
            win.ClearAttribute(df.CONTROLBOX);
        },
        df.KEYBOARD => {
            if (p1 < 128) {
                const c = std.ascii.toLower(@intCast(p1));
                if (c == 'y') {
                    _ = win.sendMessage(df.COMMAND, df.ID_OK, 0);
                } else if (c == 'n') {
                    _ = win.sendMessage(df.COMMAND, df.ID_CANCEL, 0);
                }
            }
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.MESSAGEBOX, win, msg, p1, p2);
}

fn ErrorBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    switch (msg)    {
        df.CREATE_WINDOW => {
            wnd.*.Class = df.ERRORBOX;
            df.InitWindowColors(wnd);
        },
        df.KEYBOARD => {
              //  This do nothing
//            if (p1 == '\r' or p1 == df.ESC)
//                ReturnValue = (int)p1;
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.ERRORBOX, win, msg, p1, p2);
}

fn CancelProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    switch (msg) {
        // There is no CancelWnd.
//        case CREATE_WINDOW:
//            CancelWnd = wnd;
//            SendMessage(wnd, CAPTURE_MOUSE, 0, 0);
//            SendMessage(wnd, CAPTURE_KEYBOARD, 0, 0);
//            break;
//        case COMMAND:
//            if ((int) p1 == ID_CANCEL && (int) p2 == 0)
//                SendMessage(GetParent(wnd), msg, p1, p2);
//            return TRUE;
//        case CLOSE_WINDOW:
//            CancelWnd = NULL;
//            SendMessage(wnd, RELEASE_MOUSE, 0, 0);
//            SendMessage(wnd, RELEASE_KEYBOARD, 0, 0);
//            p1 = TRUE;
//            break;
        else => {
        }
    }
    return root.zBaseWndProc(df.MESSAGEBOX, win, msg, p1, p2);
}

pub fn MsgHeight(msg:[:0]const u8) c_int {
    const h:c_int =  @intCast(std.mem.count(u8, msg, "\n")+1);
    return @min(h, df.SCREENHEIGHT-10);
}

pub fn MsgWidth(msg:[:0]const u8) c_int {
    var w:c_int = 0;
    var iter = std.mem.splitScalar(u8, msg, '\n'); // split do not include '\n'
    while (iter.next()) |line| {
        w = @intCast(@max(w, line.len));
    }
    return @min(w, df.SCREENWIDTH-10);
}
