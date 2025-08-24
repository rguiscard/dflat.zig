const std = @import("std");
const root = @import("root.zig");
const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const WndProc = @import("WndProc.zig");

const MAXCONTROLS = 30;
var dialogboxes:?std.ArrayList(*df.DBOX) = null;

fn getDialogBoxes() *std.ArrayList(*df.DBOX) {
    if (dialogboxes == null) {
        if (std.ArrayList(*df.DBOX).initCapacity(root.global_allocator, 10)) |list| {
            dialogboxes = list;
        } else |_| {
            // error
        }
    }
    return &dialogboxes.?;
}

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

// ----- window-processing module, DIALOG window class -----
pub fn DialogProc(wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const p2_new = p2;

    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(wnd, p1, p2);
        },
        else => {
            return df.cDialogProc(wnd, msg, p1, p2);
        }
    }
    // Note, p2 will be changed.
    return root.zBaseWndProc(df.DIALOG, wnd, msg, p1, p2_new);
}

// -------- CREATE_WINDOW Message ---------
fn CreateWindowMsg(wnd: df.WINDOW, p1: df.PARAM, p2: df.PARAM) c_int {
    var win:*Window = undefined;
    if (Window.get_zin(wnd)) |zin| {
        win = zin;
    }

    const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));
    var rtn:c_int = df.FALSE;
    var idx:isize = -1;

    const dbs = getDialogBoxes();

    // ---- build a table of processed dialog boxes ----
    for (dbs.items, 0..) |item, i| {
        if (db == item) {
            idx = @intCast(i);
            break;
        }
    }
    if (idx < 0) { // not found
        if (dbs.append(root.global_allocator, db)) {
        } else |_| { // error
        }
    }
    rtn = root.zBaseWndProc(df.DIALOG, wnd, df.CREATE_WINDOW, p1, p2);

    for(0..MAXCONTROLS) |i| {
        const ctl:*df.CTLWINDOW = @ptrCast(&db.*.ctl[i]);
        if (ctl.*.Class == 0) { // Class as 0 is used as end of array
            break;
        }
        var attrib:c_int = 0;
        if (wnd.*.attrib & df.NOCLIP > 0)
            attrib = attrib | df.NOCLIP;
//        if (wnd.*.Modal > 0)
        if (win.*.modal)
            attrib = attrib | df.SAVESELF;
        ctl.*.setting = ctl.*.isetting;
        if ((ctl.*.Class == df.EDITBOX) and (ctl.*.dwnd.h > 1)) {
            attrib = attrib | (df.MULTILINE | df.HASBORDER);
        } else if ((ctl.*.Class == df.LISTBOX or ctl.*.Class == df.TEXTBOX) and ctl.*.dwnd.h > 2) {
            attrib = attrib | df.HASBORDER;
        }
//        const win:*Window = @constCast(@fieldParentPtr("win", &wnd));
        var cwnd = Window.create(ctl.*.Class,
                        if (ctl.*.dwnd.title) |t| std.mem.span(t) else null,
                        @intCast(ctl.*.dwnd.x+win.GetClientLeft()),
                        @intCast(ctl.*.dwnd.y+win.GetClientTop()),
                        ctl.*.dwnd.h,
                        ctl.*.dwnd.w,
                        ctl,
                        wnd,
                        WndProc.ControlProc,
                        attrib);
        if ((ctl.*.Class == df.EDITBOX or ctl.*.Class == df.TEXTBOX or
                ctl.*.Class == df.COMBOBOX) and
                    ctl.*.itext != null) {
            _ = cwnd.sendTextMessage(df.SETTEXT, std.mem.span(ctl.*.itext), 0);
        }
    }
    return rtn;
}
