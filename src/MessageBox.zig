const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const WndProc = @import("WndProc.zig");

const sOK  = "   Ok   ";
const sYES = "   Yes  ";
const sNO  = "   No   ";
const sERROR  = "Error";
const sCONFIRM  = "Confirm";

// InputBox and CancelBox were not used. Port them later.
pub export fn ErrorMessage(message: [*c]u8) df.BOOL {
    const result = GenericMessage(null, @constCast(sERROR.ptr), message, 1, WndProc.ErrorBoxProc, sOK, null, df.ID_OK, 0, true);
    return result;
}

pub export fn MessageBox(title: [*c]u8, message: [*c]u8) df.BOOL {
    const result = GenericMessage(null, title, message, 1, WndProc.MessageBoxProc, sOK, null, df.ID_OK, 0, true);
    return result;
}

pub export fn YesNoBox(message: [*c]u8) df.BOOL {
    const result = GenericMessage(null, @constCast(sCONFIRM.ptr), message, 2, WndProc.YesNoBoxProc, sYES, sNO, df.ID_OK, df.ID_CANCEL, true);
    return result;
}

fn GenericMessage(wnd: df.WINDOW, title: [*c]u8, message:[*c]u8, buttonct: c_int,
                  wndproc: *const fn (win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int,
                  button1: ?[]const u8, button2: ?[]const u8, c1: c_int, c2: c_int, isModal: bool) df.BOOL {
    var mBox = Dialogs.MsgBox;

//    const m:[*c]u8 = @constCast(message.ptr);
    const m:[*c]u8 = message;
    var ttl_w:c_int = 0;
    if (title) |t| {
      const tt = std.mem.span(t);
      ttl_w = @intCast(tt.len+2);
    }

//    mBox.dwnd.title = if (title) |t| @constCast(t.ptr) else null;
    mBox.dwnd.title = title; // need a copy ?
    mBox.ctl[0].dwnd.h = df.MsgHeight(m);
    mBox.ctl[0].dwnd.w = @max(@max(df.MsgWidth(m), buttonct*8+buttonct+2),ttl_w);
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
    mBox.ctl[0].itext = m;
    mBox.ctl[1].itext = if (button1) |b| @constCast(b.ptr) else null;
    mBox.ctl[2].itext = if (button2) |b| @constCast(b.ptr) else null;
    mBox.ctl[1].command = c1;
    mBox.ctl[2].command = c2;
    mBox.ctl[1].isetting = df.ON;
    mBox.ctl[2].isetting = df.ON;

    
    const c_modal:df.BOOL = if (isModal) df.TRUE else df.FALSE;
    const rtn = DialogBox.DialogBox(wnd, &mBox, c_modal, wndproc);

    mBox.ctl[2].Class = 0;
    return rtn;
}
