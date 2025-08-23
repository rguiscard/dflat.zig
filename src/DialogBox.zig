const std = @import("std");
const root = @import("root.zig");
const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();

// ------- create and execute a dialog box ----------
pub export fn DialogBox(wnd:df.WINDOW, db:*df.DBOX, Modal:df.BOOL,
   wndproc: ?*const fn (wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int) df.BOOL {

    const box = db;

    var rtn:df.BOOL = df.FALSE;
    const x = box.*.dwnd.x;
    const y = box.*.dwnd.y;

    var save:c_int = 0;
    if (Modal == df.TRUE) {
        save = df.SAVESELF;
    }

    const ttl:[]const u8 =  std.mem.span(box.*.dwnd.title);
    var win = Window.create(df.DIALOG,
                        ttl,
                        x, y,
                        box.*.dwnd.h,
                        box.*.dwnd.w,
                        box,
                        wnd,
                        wndproc,
                        save);
    const DialogWnd = win.win;

    _ = win.sendMessage(df.SETFOCUS, df.TRUE, 0);
//    DialogWnd.*.Modal = if (Modal) 1 else 0;
    win.*.modal = (Modal == df.TRUE);
    df.FirstFocus(db);
    df.PostMessage(DialogWnd, df.INITIATE_DIALOG, 0, 0);
    if (Modal == df.TRUE) {
        _ = win.sendMessage(df.CAPTURE_MOUSE, 0, 0);
        _ = win.sendMessage(df.CAPTURE_KEYBOARD, 0, 0);
        while (df.dispatch_message()>0) {
        }
        rtn = if (DialogWnd.*.ReturnCode == df.ID_OK) df.TRUE else df.FALSE;
        _ = win.sendMessage(df.RELEASE_MOUSE, 0, 0);
        _ = win.sendMessage(df.RELEASE_KEYBOARD, 0, 0);
        _ = win.sendMessage(df.CLOSE_WINDOW, df.TRUE, 0);
    }
    return rtn;
}
