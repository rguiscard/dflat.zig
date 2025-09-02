const std = @import("std");
const root = @import("root.zig");
const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const WndProc = @import("WndProc.zig");
const q = @import("Message.zig");

var SysMenuOpen = false;
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
    wndproc: ?*const fn (win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int) df.BOOL {

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
    win.*.modal = (Modal == df.TRUE);
    df.FirstFocus(db);
    q.PostMessage(DialogWnd, df.INITIATE_DIALOG, 0, 0);
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

// ------- CREATE_WINDOW Message (Control) -----
fn CtlCreateWindowMsg(win:*Window) void {
    const wnd = win.win;
    if (wnd.*.extension) |extension| {
        wnd.*.ct = @alignCast(@ptrCast(extension));

        const ct = wnd.*.ct;
        ct.*.wnd = wnd;
    } else {
        wnd.*.ct = null;
    }
    wnd.*.extension = null;
}

// ------- KEYBOARD Message (Control) -----
fn CtlKeyboardMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    switch (p1) {
        ' ' => {
            if ((p2 & df.ALTKEY) > 0) {
                // it didn't break. Fall through
                q.PostMessage(Window.GetParent(wnd), df.KEYBOARD, p1, p2);
                return true;
            }
        },
        df.ALT_F6,
        df.CTRL_F4,
        df.ALT_F4 => {
            q.PostMessage(Window.GetParent(wnd), df.KEYBOARD, p1, p2);
            return true;
        },
        df.F1 => {
            if ((df.WindowMoving==0) and (df.WindowSizing==0)) {
                const ct = df.GetControl(wnd);
                if (df.DisplayHelp(wnd, ct.*.help) == 0) {
                    _ = df.SendMessage(Window.GetParent(wnd),df.COMMAND,df.ID_HELP,0);
                }
                return true;
            }
        },
        else => {
        }
    }
    if (df.GetClass(wnd) == df.EDITBOX) {
        if (df.isMultiLine(wnd)>0) {
            return false;
        }
    }
    if (df.GetClass(wnd) == df.TEXTBOX) {
        if (win.WindowHeight() > 1) {
            return false;
        }
    }
    switch (p1) {
// does not seem to do anything ?
//        df.UP => {
//            if (df.isDerivedFrom(wnd, df.LISTBOX) == 0) {
//                p1 = CTRL_FIVE;
//                p2 = LEFTSHIFT;
//            }
//        },
//        case BS:
//            if (!isDerivedFrom(wnd, EDITBOX))    {
//                p1 = CTRL_FIVE;
//                p2 = LEFTSHIFT;
//            }
//            break;
//        case DN:
//            if (!isDerivedFrom(wnd, LISTBOX) &&
//                    !isDerivedFrom(wnd, COMBOBOX))
//                p1 = '\t';
//            break;
//        case FWD:
//            if (!isDerivedFrom(wnd, EDITBOX))
//                p1 = '\t';
//            break;
//        case '\r':
//            if (isDerivedFrom(wnd, EDITBOX))
//                if (isMultiLine(wnd))
//                    break;
//            if (isDerivedFrom(wnd, BUTTON))
//                break;
//            if (isDerivedFrom(wnd, LISTBOX))
//                break;
//            SendMessage(GetParent(wnd), COMMAND, ID_OK, 0);
//            return TRUE;
        else => {
        }
    }
    return false;
}

// -- generic window processor used by dialog box controls --
pub fn ControlProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    // win can be null ? probably not.
    const wnd = win.win;
    switch(msg) {
        df.CREATE_WINDOW => {
            CtlCreateWindowMsg(win);
        },
        df.KEYBOARD => {
            if (CtlKeyboardMsg(win, p1, p2))
                return df.TRUE;
        },
        df.PAINT => {
            df.FixColors(wnd);
            if ((df.GetClass(wnd) == df.EDITBOX) or
                (df.GetClass(wnd) == df.LISTBOX) or
                (df.GetClass(wnd) == df.TEXTBOX)) {
                df.SetScrollBars(wnd);
            }
        },
        df.BORDER => {
            df.FixColors(wnd);
            if (df.GetClass(wnd) == df.EDITBOX) {
                const oldFocus = df.inFocus;
                df.inFocus = null;
                _ = root.DefaultWndProc(wnd, msg, p1, p2);
                df.inFocus = oldFocus;
                return df.TRUE;
            }
        },
        df.SETFOCUS => {
            const pwnd = Window.GetParent(wnd);
            var db:?*df.DBOX = null;
            if (pwnd != null) {
                db = @alignCast(@ptrCast(pwnd.*.extension));
            }
            if (p1 > 0) {
                const oldFocus = df.inFocus;
                // we assume df.inFocus is not null
                if (Window.get_zin(oldFocus)) |oldWin| {
                    if ((pwnd != null) and (df.GetClass(oldFocus) != df.APPLICATION) and
                                       (df.isAncestor(df.inFocus, pwnd) == 0)) {
                        df.inFocus = null;
                        _ = df.SendMessage(oldFocus, df.BORDER, 0, 0);
                        _ = df.SendMessage(pwnd, df.SHOW_WINDOW, 0, 0);
                        df.inFocus = oldFocus;
                        oldWin.ClearVisible();
                    }
                    if ((df.GetClass(oldFocus) == df.APPLICATION) and
                            df.NextWindow(pwnd) != null) {
                        pwnd.*.wasCleared = df.FALSE;
                    }
                    _ = root.DefaultWndProc(wnd, msg, p1, p2);
                    oldWin.SetVisible();
                    if (pwnd != null) {
                        pwnd.*.dfocus = wnd;
                        _ = df.SendMessage(pwnd, df.COMMAND,
                                 df.inFocusCommand(db), df.ENTERFOCUS);
                    }
                    return df.TRUE;
                }
            } else {
                _ = df.SendMessage(pwnd, df.COMMAND,
                            df.inFocusCommand(db), df.LEAVEFOCUS);
            }
        },
        df.CLOSE_WINDOW => {
            df.CtlCloseWindowMsg(wnd);
        },
        else => {
        }
    }
    return root.zDefaultWndProc(win, msg, p1, p2);
}

// -------- CREATE_WINDOW Message ---------
fn CreateWindowMsg(win:*Window, p1: df.PARAM, p2: df.PARAM) c_int {
    const wnd = win.win;
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
    rtn = root.zBaseWndProc(df.DIALOG, win, df.CREATE_WINDOW, p1, p2);

    for(0..MAXCONTROLS) |i| {
        const ctl:*df.CTLWINDOW = @ptrCast(&db.*.ctl[i]);
        if (ctl.*.Class == 0) { // Class as 0 is used as end of array
            break;
        }
        var attrib:c_int = 0;
        if (wnd.*.attrib & df.NOCLIP > 0)
            attrib = attrib | df.NOCLIP;
        if (win.*.modal)
            attrib = attrib | df.SAVESELF;
        ctl.*.setting = ctl.*.isetting;
        if ((ctl.*.Class == df.EDITBOX) and (ctl.*.dwnd.h > 1)) {
            attrib = attrib | (df.MULTILINE | df.HASBORDER);
        } else if ((ctl.*.Class == df.LISTBOX or ctl.*.Class == df.TEXTBOX) and ctl.*.dwnd.h > 2) {
            attrib = attrib | df.HASBORDER;
        }
        var cwnd = Window.create(ctl.*.Class,
                        if (ctl.*.dwnd.title) |t| std.mem.span(t) else null,
                        @intCast(ctl.*.dwnd.x+win.GetClientLeft()),
                        @intCast(ctl.*.dwnd.y+win.GetClientTop()),
                        ctl.*.dwnd.h,
                        ctl.*.dwnd.w,
                        ctl,
                        wnd,
                        ControlProc,
                        attrib);
        if ((ctl.*.Class == df.EDITBOX or ctl.*.Class == df.TEXTBOX or
                ctl.*.Class == df.COMBOBOX) and
                    ctl.*.itext != null) {
            _ = cwnd.sendTextMessage(df.SETTEXT, std.mem.span(ctl.*.itext), 0);
        }
    }
    return rtn;
}

// -------- LEFT_BUTTON Message ---------
fn LeftButtonMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;

    if ((df.WindowSizing>0) or (df.WindowMoving>0))
        return true;

    if (df.HitControlBox(wnd, p1-win.GetLeft(), p2-win.GetTop())) {
        q.PostMessage(wnd, df.KEYBOARD, ' ', df.ALTKEY);
        return true;
    }
//    Not in use
//    const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));
//    CTLWINDOW *ct = db->ctl;
//    while (ct->Class)    {
//        WINDOW cwnd = ct->wnd;
//        if (ct->Class == COMBOBOX)    {
//            if (p2 == GetTop(cwnd))    {
//                if (p1 == GetRight(cwnd)+1)    {
//                    SendMessage(cwnd, LEFT_BUTTON, p1, p2);
//                    return TRUE;
//                }
//            }
//            if (GetClass(inFocus) == LISTBOX)
//                SendMessage(wnd, SETFOCUS, TRUE, 0);
//        }
//        else if (ct->Class == SPINBUTTON)    {
//            if (p2 == GetTop(cwnd))    {
//                if (p1 == GetRight(cwnd)+1 ||
//                        p1 == GetRight(cwnd)+2)    {
//                    SendMessage(cwnd, LEFT_BUTTON, p1, p2);
//                    return TRUE;
//                }
//            }
//        }
//        ct++;
//    }
    return false;
}

// -------- KEYBOARD Message ---------
fn KeyboardMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.*.win;

    if ((df.WindowMoving>0) or (df.WindowSizing>0))
        return false;

    const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));

    switch (p1) {
        df.SHIFT_HT,
        df.BS,
        df.UP => {
            df.PrevFocus(db);
        },
        df.ALT_F6,
        '\t',
        df.FWD,
        df.DN => {
            df.NextFocus(db);
        },
        ' ' => {
            if (((p2 & df.ALTKEY)>0) and win.TestAttribute(df.CONTROLBOX)) {
                SysMenuOpen = true;
                df.BuildSystemMenu(wnd);
                return true;
            }
        },
        df.CTRL_F4,
        df.ESC => {
            _ = win.sendMessage(df.COMMAND, df.ID_CANCEL, 0);
        },
        df.F1 => {
            const ct = df.GetControl(df.inFocus);
            if (ct != null) {
                if (df.DisplayHelp(wnd, ct.*.help)>0) {
                    return true;
                }
            }
        },
         else => {
             // ------ search all the shortcut keys -----
             if (df.dbShortcutKeys(db, @intCast(p1))>0)
                 return true;
         }
    }
    return win.modal;
}

// -------- COMMAND Message ---------
fn CommandMsg(win: *Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.*.win;
    switch (p1) {
        df.ID_OK, df.ID_CANCEL => {
            if (p2 != 0)
                return true;
            wnd.*.ReturnCode = @intCast(p1);
            if (win.modal) {
                _ = q.PostMessage(wnd, df.ENDDIALOG, 0, 0);
            } else {
                _ = win.sendMessage(df.CLOSE_WINDOW, df.TRUE, 0);
            }
            return true;
        },
        df.ID_HELP => {
            if (p2 != 0)
                return true;

            const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));
            const rtn = df.DisplayHelp(wnd, db.*.HelpName);
            return (rtn == df.TRUE);
        },
        else => {
        }
    }
    return false;
}

// ----- window-processing module, DIALOG window class -----
pub fn DialogProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    var p2_new = p2;

    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win, p1, p2);
        },
        df.SHIFT_CHANGED => {
            if (win.modal)
                return df.TRUE;
        },
        df.LEFT_BUTTON => {
            if (LeftButtonMsg(win, p1, p2))
                return df.TRUE;
        },
        df.KEYBOARD => {
            if (KeyboardMsg(win, p1, p2))
                return df.TRUE;
        },
        df.CLOSE_POPDOWN => {
            SysMenuOpen = false;
        },
        df.LB_SELECTION, df.LB_CHOOSE => {
            if (SysMenuOpen)
                return df.TRUE;
            if (wnd.*.extension) |extension| {
                const db:*df.DBOX = @alignCast(@ptrCast(extension));
                _ = win.sendMessage(df.COMMAND, df.inFocusCommand(db), msg);
            }
        },
        df.SETFOCUS => {
            if ((p1 != 0) and (wnd.*.dfocus != null) and (df.isVisible(wnd) > 0)) {
                return df.SendMessage(wnd.*.dfocus, df.SETFOCUS, df.TRUE, 0);
            }
        },
        df.COMMAND => {
            if (CommandMsg(win, p1, p2))
                return df.TRUE;
        },
        df.PAINT => {
            p2_new = df.TRUE;
        },
        df.MOVE, df.SIZE => {
            const rtn = root.zBaseWndProc(df.DIALOG, win, msg, p1, p2);
            if ((wnd.*.dfocus != null) and (df.isVisible(wnd) > 0))
                _ = df.SendMessage(wnd.*.dfocus, df.SETFOCUS, df.TRUE, 0);
            return rtn;
        },
        df.CLOSE_WINDOW => {
            if (p1 == 0) {
                _ = win.sendMessage(df.COMMAND, df.ID_CANCEL, 0);
                return df.TRUE;
            }
        },
        else => {
        }
    }
    // Note, p2 will be changed.
    return root.zBaseWndProc(df.DIALOG, win, msg, p1, p2_new);
}
