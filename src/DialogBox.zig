const std = @import("std");
const root = @import("root.zig");
const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const WndProc = @import("WndProc.zig");
const helpbox = @import("HelpBox.zig");
const sysmenu = @import("SystemMenu.zig");
const normal = @import("Normal.zig");
const radio = @import("RadioButton.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;

var SysMenuOpen = false;
var dialogboxes:?std.ArrayList(*Dialogs.DBOX) = null;

fn itextAllocateSentinel(ct:*Dialogs.CTLWINDOW, size:usize) bool {
    if (ct.*.itext) |itext| {
        if (ct.*.itext_allocated) { // can realloc
            if(root.global_allocator.realloc(itext, size+1)) |buf| {
                ct.*.itext = buf[0..size:0];
            } else |_| {
            }
            return true;
        }
    }

    // Either itext is null or no in heap. Assign to new memory buf.
    if(root.global_allocator.allocSentinel(u8, size, 0)) |buf| {
        @memset(buf, 0);
        ct.*.itext = buf;
        ct.*.itext_allocated = true; // can be freed.
        return true;
    } else |_| {
    }
    return false; // error on allocation
}

fn getDialogBoxes() *std.ArrayList(*Dialogs.DBOX) {
    if (dialogboxes == null) {
        if (std.ArrayList(*Dialogs.DBOX).initCapacity(root.global_allocator, 10)) |list| {
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

// --- clear all heap allocations to control text fields ---
pub fn ClearDialogBoxes() void {
    if (dialogboxes) |dbs| {
        for(dbs.items) |db| {
            for (&db.*.ctl) |*ct| {
                if (ct.*.Class == 0)
                    break;
                if (ct.*.itext) |itext| {
                    if (ct.*.itext_allocated) {
//                      if ((ct.*.Class == df.EDITBOX or
//                                 ct.*.Class == df.TEXTBOX or
//                                 ct.*.Class == df.COMBOBOX)) {
                           // FIXME: itext_allocated should save guard already.
                           // Why only apply to these classes?
                           // Memory leak if no safe guard here.
                           root.global_allocator.free(itext);
//                        }
                        ct.*.itext = null;
                        ct.*.itext_allocated = false;
                    }
                    // null for others ?
                }
            }
        }
        dialogboxes.?.deinit(root.global_allocator);
        dialogboxes = null;
    }
}

// ------- create and execute a dialog box ----------
pub fn create(parent:?*Window, db:*Dialogs.DBOX, Modal:df.BOOL,
    wndproc: ?*const fn (win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool) bool {

    const box = db;

    var rtn = false;
    const x = box.*.dwnd.x;
    const y = box.*.dwnd.y;

    var save:c_int = 0;
    if (Modal == df.TRUE) {
        save = df.SAVESELF;
    }

    var win = Window.create(df.DIALOG,
                        box.*.dwnd.title,
                        x, y,
                        box.*.dwnd.h,
                        box.*.dwnd.w,
                        box,
                        parent,
                        wndproc,
                        save);

    _ = win.sendMessage(df.SETFOCUS, df.TRUE, 0);
    win.*.modal = (Modal == df.TRUE);
    FirstFocus(db);
    q.PostMessage(win.win, df.INITIATE_DIALOG, 0, 0);
    if (Modal == df.TRUE) {
        _ = win.sendMessage(df.CAPTURE_MOUSE, 0, 0);
        _ = win.sendMessage(df.CAPTURE_KEYBOARD, 0, 0);
        while (q.dispatch_message()) {
        }
        rtn = (win.ReturnCode == c.ID_OK);
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
        win.ct = @alignCast(@ptrCast(extension));
        if (win.ct) |ctl| {
            const ct = ctl;
            ct.win = win;
        }
    } else {
        win.ct = null;
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
                q.PostMessage(win.getParent().win, df.KEYBOARD, p1, p2);
                return true;
            }
        },
        df.ALT_F6,
        df.CTRL_F4,
        df.ALT_F4 => {
            q.PostMessage(win.getParent().win, df.KEYBOARD, p1, p2);
            return true;
        },
        df.F1 => {
            if (normal.WindowMoving==false and normal.WindowSizing==false) {
                if (win.GetControl()) |ct| {
                    if (ct.*.help) |help| {
                        if (helpbox.DisplayHelp(win, help) == false) {
                            _ = win.getParent().sendCommandMessage(c.ID_HELP,0);
                        }
                    }
                }
                return true;
            }
        },
        else => {
        }
    }
    if (win.getClass() == df.EDITBOX) {
        if (df.isMultiLine(wnd)>0) {
            return false;
        }
    }
    if (win.getClass() == df.TEXTBOX) {
        if (win.WindowHeight() > 1) {
            return false;
        }
    }
    switch (p1) {
// does not seem to do anything ?
//        df.UP => {
//            if (normal.isDerivedFrom(win, df.LISTBOX) == false) {
//                p1 = CTRL_FIVE;
//                p2 = LEFTSHIFT;
//            }
//        },
//        case BS:
//            if (normal.isDerivedFrom(win, df.EDITBOX) == false)    {
//                p1 = CTRL_FIVE;
//                p2 = LEFTSHIFT;
//            }
//            break;
//        case DN:
//            if ((normal.isDerivedFrom(win, df.LISTBOX) == false) and
//                    (normal.isDerivedFrom(win, df.COMBOBOX) == false))
//                p1 = '\t';
//            break;
//        case FWD:
//            if (normal.isDerivedFrom(win, df.EDITBOX) == false)
//                p1 = '\t';
//            break;
        '\r' => {
            if (((normal.isDerivedFrom(win, df.EDITBOX) and (df.isMultiLine(wnd) > 0)) == false) and
                (normal.isDerivedFrom(win, df.BUTTON) == false) and
                (normal.isDerivedFrom(win, df.LISTBOX) == false)) {
                _ = win.getParent().sendCommandMessage(c.ID_OK, 0);
                return true;
            }
        },
        else => {
        }
    }
    return false;
}

fn FixColors(win:*Window) void {
    const wnd = win.win;
    if (win.GetControl()) |ct| {
        if (ct.*.Class != df.BUTTON) {
            if ((ct.*.Class != df.SPINBUTTON) and (ct.*.Class != df.COMBOBOX)) {
                if ((ct.*.Class != df.EDITBOX) and (ct.*.Class != df.LISTBOX)) {
                    const pwnd = win.getParent().win;
                    wnd.*.WindowColors[df.FRAME_COLOR][df.FG] =
                                            pwnd.*.WindowColors[df.FRAME_COLOR][df.FG];
                    wnd.*.WindowColors[df.FRAME_COLOR][df.BG] =
                                            pwnd.*.WindowColors[df.FRAME_COLOR][df.BG];
                    wnd.*.WindowColors[df.STD_COLOR][df.FG] =
                                            pwnd.*.WindowColors[df.STD_COLOR][df.FG];
                    wnd.*.WindowColors[df.STD_COLOR][df.BG] =
                                            pwnd.*.WindowColors[df.STD_COLOR][df.BG];
                }
            }
        }
    }
}

// --- dynamically add or remove scroll bars
//                            from a control window ----
fn SetScrollBars(win:*Window) void {
    const wnd = win.win;
    const oldattr = win.GetAttribute();
    if (wnd.*.wlines > win.ClientHeight()) {
        win.AddAttribute(df.VSCROLLBAR);
    } else {
        win.ClearAttribute(df.VSCROLLBAR);
    }
    if (wnd.*.textwidth > win.ClientWidth()) {
        win.AddAttribute(df.HSCROLLBAR);
    } else {
        win.ClearAttribute(df.HSCROLLBAR);
    }
    if (win.GetAttribute() != oldattr)
        _ = win.sendMessage(df.BORDER, 0, 0);
}

// ------- CLOSE_WINDOW Message (Control) -----
fn CtlCloseWindowMsg(win:*Window) void {
    const wnd = win.win;
    if (win.GetControl()) |ct| {
        ct.win = null;
        if (win.getParent().ReturnCode == c.ID_OK) {
            if (ct.*.Class == df.EDITBOX or ct.*.Class == df.COMBOBOX)  {
                // should use strlen() instead ?
                const len = wnd.*.textlen;
                if (itextAllocateSentinel(ct, len)) {
                    @memcpy(ct.*.itext.?, wnd.*.text[0..len:0]);
                }
                if (df.isMultiLine(wnd) == df.FALSE) {
                    // remove last \n
                    if (ct.*.itext) |itext| {
                        if (std.mem.indexOfScalar(u8, itext, '\n')) |pos| {
                            itext.ptr[pos] = 0;
                        }
                    }
                }
            } else if (ct.*.Class == df.RADIOBUTTON or ct.*.Class == df.CHECKBOX) {
                ct.*.isetting = ct.*.setting;
            }
        }
    }
}

// -- generic window processor used by dialog box controls --
pub fn ControlProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    // win can be null ? probably not.
    switch(msg) {
        df.CREATE_WINDOW => {
            CtlCreateWindowMsg(win);
        },
        df.KEYBOARD => {
            if (CtlKeyboardMsg(win, p1, p2))
                return true;
        },
        df.PAINT => {
            FixColors(win);
            if ((win.getClass() == df.EDITBOX) or
                (win.getClass() == df.LISTBOX) or
                (win.getClass() == df.TEXTBOX)) {
                SetScrollBars(win);
            }
        },
        df.BORDER => {
            FixColors(win);
            if (win.getClass() == df.EDITBOX) {
                const oldFocus = Window.inFocus;
                Window.inFocus = null;
                _ = root.zDefaultWndProc(win, msg, p1, p2);
                Window.inFocus = oldFocus;
                return true;
            }
        },
        df.SETFOCUS => {
            var pwin = win.parent;
            var pwnd:df.WINDOW = null;
            if (pwin) |pw| {
                pwnd = pw.win; // only dummy and application window is null
            }
            var db:?*Dialogs.DBOX = null;
            if (pwnd != null) {
                db = @alignCast(@ptrCast(pwnd.*.extension));
            }
            if (p1 > 0) {
                const oldFocus = Window.inFocus;
                // we assume df.inFocus is not null
                if (oldFocus) |oldWin| {
                    if ((pwnd != null) and (oldWin.getClass() != df.APPLICATION) and
                                       (normal.isAncestor(oldWin.win, pwnd) == false)) {
                        Window.inFocus = null;
                        _ = oldWin.sendMessage(df.BORDER, 0, 0);
                        _ = q.SendMessage(pwnd, df.SHOW_WINDOW, 0, 0);
                        Window.inFocus = oldFocus;
                        oldWin.ClearVisible();
                    }
                    if (oldWin.getClass() == df.APPLICATION) {
                        if (pwin != null and pwin.?.nextWindow() != null) {
                            pwnd.*.wasCleared = df.FALSE;
                        }
                    }
                    _ = root.zDefaultWndProc(win, msg, p1, p2);
                    oldWin.SetVisible();
                    if (pwin) |pw| {
                        pw.dfocus = win;
                        _ = pw.sendCommandMessage(inFocusCommand(db), df.ENTERFOCUS);
                    }
                    return true;
                }
            } else {
                _ = q.SendMessage(pwnd, df.COMMAND, @intFromEnum(inFocusCommand(db)), df.LEAVEFOCUS);
            }
        },
        df.CLOSE_WINDOW => {
            CtlCloseWindowMsg(win);
        },
        else => {
        }
    }
    return root.zDefaultWndProc(win, msg, p1, p2);
}

// -------- CREATE_WINDOW Message ---------
fn CreateWindowMsg(win:*Window, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
    const db:*Dialogs.DBOX = @alignCast(@ptrCast(wnd.*.extension));
    var rtn = false;
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

    for(0..Dialogs.MAXCONTROLS) |i| {
        const ctl:*Dialogs.CTLWINDOW = @ptrCast(&db.*.ctl[i]);
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
                        ctl.*.dwnd.title,
                        @intCast(ctl.*.dwnd.x+win.GetClientLeft()),
                        @intCast(ctl.*.dwnd.y+win.GetClientTop()),
                        ctl.*.dwnd.h,
                        ctl.*.dwnd.w,
                        ctl,
                        win,
                        ControlProc,
                        attrib);
        if ((ctl.*.Class == df.EDITBOX or ctl.*.Class == df.TEXTBOX or
                ctl.*.Class == df.COMBOBOX)) {
            if (ctl.*.itext) |itext| {
                _ = cwnd.sendTextMessage(df.SETTEXT, @constCast(itext), 0);
            }
        }
    }
    return rtn;
}

// -------- LEFT_BUTTON Message ---------
fn LeftButtonMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;

    if (normal.WindowSizing or normal.WindowMoving)
        return true;

    if (df.HitControlBox(wnd, p1-win.GetLeft(), p2-win.GetTop())) {
        q.PostMessage(wnd, df.KEYBOARD, ' ', df.ALTKEY);
        return true;
    }
//    Not in use
//    const db:*Dialogs.DBOX = @alignCast(@ptrCast(wnd.*.extension));
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

    if (normal.WindowMoving or normal.WindowSizing)
        return false;

    const db:*Dialogs.DBOX = @alignCast(@ptrCast(wnd.*.extension));

    switch (p1) {
        df.SHIFT_HT,
        df.BS,
        df.UP => {
            PrevFocus(db);
        },
        df.ALT_F6,
        '\t',
        df.FWD,
        df.DN => {
            NextFocus(db);
        },
        ' ' => {
            if (((p2 & df.ALTKEY)>0) and win.TestAttribute(df.CONTROLBOX)) {
                SysMenuOpen = true;
                sysmenu.BuildSystemMenu(win);
                return true;
            }
        },
        df.CTRL_F4,
        df.ESC => {
            _ = win.sendCommandMessage(c.ID_CANCEL, 0);
        },
        df.F1 => {
            if (Window.inFocus) |focus| {
                if (focus.GetControl()) |ct| {
                    if (ct.*.help) |help| {
                        if (helpbox.DisplayHelp(win, help)) {
                            return true;
                        }
                    }
                }
            }
        },
        else => {
            // ------ search all the shortcut keys -----
            if (dbShortcutKeys(db, @intCast(p1)))
                return true;
        }
    }
    return win.modal;
}

// -------- COMMAND Message ---------
fn CommandMsg(win: *Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.*.win;
    const cmd:c = @enumFromInt(p1);
    switch (cmd) {
        .ID_OK, .ID_CANCEL => {
            if (p2 != 0)
                return true;
            win.ReturnCode = cmd;
            if (win.modal) {
                _ = q.PostMessage(wnd, df.ENDDIALOG, 0, 0);
            } else {
                _ = win.sendMessage(df.CLOSE_WINDOW, df.TRUE, 0);
            }
            return true;
        },
        .ID_HELP => {
            if (p2 != 0)
                return true;

            const db:*Dialogs.DBOX = @alignCast(@ptrCast(wnd.*.extension));
            return helpbox.DisplayHelp(win, db.*.HelpName);
        },
        else => {
        }
    }
    return false;
}

// ----- window-processing module, DIALOG window class -----
pub fn DialogProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
    var p2_new = p2;

    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win, p1, p2);
        },
        df.SHIFT_CHANGED => {
            if (win.modal)
                return true;
        },
        df.LEFT_BUTTON => {
            if (LeftButtonMsg(win, p1, p2))
                return true;
        },
        df.KEYBOARD => {
            if (KeyboardMsg(win, p1, p2))
                return true;
        },
        df.CLOSE_POPDOWN => {
            SysMenuOpen = false;
        },
        df.LB_SELECTION, df.LB_CHOOSE => {
            if (SysMenuOpen)
                return true;
            if (wnd.*.extension) |extension| {
                const db:*Dialogs.DBOX = @alignCast(@ptrCast(extension));
                _ = win.sendCommandMessage(inFocusCommand(db), msg);
            }
        },
        df.SETFOCUS => {
            if ((p1 != 0) and (df.isVisible(wnd) > 0)) {
                if (win.dfocus) |dfocus| {
                    return dfocus.sendMessage(df.SETFOCUS, df.TRUE, 0);
                }
            }
        },
        df.COMMAND => {
            if (CommandMsg(win, p1, p2))
                return true;
        },
        df.PAINT => {
            p2_new = df.TRUE;
        },
        df.MOVE, df.SIZE => {
            const rtn = root.zBaseWndProc(df.DIALOG, win, msg, p1, p2);
            if (df.isVisible(wnd) > 0) {
                if (win.dfocus) |dfocus| {
                    _ = dfocus.sendMessage(df.SETFOCUS, df.TRUE, 0);
                }
            }
            return rtn;
        },
        df.CLOSE_WINDOW => {
            if (p1 == 0) {
                _ = win.sendCommandMessage(c.ID_CANCEL, 0);
                return true;
            }
        },
        else => {
        }
    }
    // Note, p2 will be changed.
    return root.zBaseWndProc(df.DIALOG, win, msg, p1, p2_new);
}

// ---- return pointer to the text of a control window ----
pub fn GetDlgTextString(db:*Dialogs.DBOX, cmd:c, Class:df.CLASS) [*c]u8 {
    const ct = FindCommand(db, cmd, Class);
    if (ct) |ctl| {
        if (ctl.*.itext) |itext| {
            return itext.ptr;
        }
    }
    return null;
}

// ------- set the text of a control specification ------
pub fn SetDlgTextString(db:*Dialogs.DBOX, cmd:c, text: [*c]u8, Class:df.CLASS) void {
    const control = FindCommand(db, cmd, Class);
    if (control) |ct| {
        if (text != null) {
            // always keep a copy
            const len = df.strlen(text);
            if (itextAllocateSentinel(ct, len)) {
                @memcpy(ct.*.itext.?, text[0..len:0]);
            }
        } else {
            if (ct.*.itext_allocated) {
                root.global_allocator.free(ct.*.itext);
                ct.*.itext_allocated = false;
            }

            // FIXME: not sure the logic is right
            if (ct.*.Class == df.TEXT) {
                ct.*.itext = @constCast(&[_]u8{0});
//            } else if (ct.*.itext_allocated) {
//                const ilen = df.strlen(ct.*.itext);
//                root.global_allocator.free(ct.*.itext[0..ilen]);
//                root.global_allocator.free(ct.*.itext);
//                df.free(ct.*.itext);
//                ct.*.itext = @constCast(&[_]u8{0});
//                ct.*.itext = null;
//                ct.*.itext_allocated = false;
            } else {
                ct.*.itext = null;
            }
        }
        if (ct.win) |w| {
            if (text != null) {
                _ = w.sendMessage(df.SETTEXT, @intCast(@intFromPtr(text)), 0);
            } else {
                _ = w.sendMessage(df.CLEARTEXT, 0, 0);
            }
            _ = w.sendMessage(df.PAINT, 0, 0);
        }
    }
}

// ------- set the text of a control window ------
pub export fn PutItemText(wnd:df.WINDOW, cmd:c, text:[*c]u8) callconv(.c) void {
    const db:*Dialogs.DBOX = @alignCast(@ptrCast(wnd.*.extension));
    var control = FindCommand(db, cmd, df.EDITBOX);

    if (control == null)
        control = FindCommand(db, cmd, df.TEXTBOX);
    if (control == null)
        control = FindCommand(db, cmd, df.COMBOBOX);
    if (control == null)
        control = FindCommand(db, cmd, df.LISTBOX);
    if (control == null)
        control = FindCommand(db, cmd, df.SPINBUTTON);
    if (control == null)
        control = FindCommand(db, cmd, df.TEXT);
    if (control) |ct| {
        // assume cwnd cannot be null ?
        if (ct.win) |cwin| {
            const cwnd = cwin.win;
            switch (ct.*.Class) {
                df.COMBOBOX,
                df.EDITBOX => {
                    _ = cwin.sendMessage(df.CLEARTEXT, 0, 0);
                    _ = cwin.sendMessage(df.ADDTEXT, @intCast(@intFromPtr(text)), 0);
                    if (df.isMultiLine(cwnd) == df.FALSE) {
                        _ = cwin.sendMessage(df.PAINT, 0, 0);
                    }
                },
                df.LISTBOX,
                df.TEXTBOX,
                df.SPINBUTTON => {
                    _ = cwin.sendMessage(df.ADDTEXT, @intCast(@intFromPtr(text)), 0);
                },
                df.TEXT => {
                    _ = cwin.sendMessage(df.CLEARTEXT, 0, 0);
                    _ = cwin.sendMessage(df.ADDTEXT, @intCast(@intFromPtr(text)), 0);
                    _ = cwin.sendMessage(df.PAINT, 0, 0);
                },
                else => {
                }
            }
        }
    }
}

// ------- get the text of a control window ------
pub fn GetItemText(wnd:df.WINDOW, cmd:c, text:[*c]u8, len:c_int) void {
    const db:*Dialogs.DBOX = @alignCast(@ptrCast(wnd.*.extension));
    var control = FindCommand(db, cmd, df.EDITBOX);

    if (control == null)
        control = FindCommand(db, cmd, df.COMBOBOX);
    if (control == null)
        control = FindCommand(db, cmd, df.TEXTBOX);
    if (control == null)
        control = FindCommand(db, cmd, df.TEXT);
    if (control) |ct| {
        if (ct.win) |cwin| {
//            const cwnd = cwin.win;
            const cwin_text = cwin.text;
            switch (ct.*.Class) {
                df.TEXT => {
                    if (cwin_text) |t| {
                        if (std.mem.indexOfScalar(u8, t, '\n')) |pos| {
                            @memcpy(text[0..pos], t[0..pos]);
                        } else {
                            // no text;
                            text.* = 0;
                        }
//                            cp = strchr(cwnd_text, '\n');
//                            if (cp != null)
//                                len = (int) (cp - cwnd_text);
//                            strncpy(text, cwnd_text, len);
//                            *(text+len) = '\0';
                    }
                },
                df.TEXTBOX => {
                    if (cwin_text) |t| {
                        var l:usize = @intCast(len);
                        if (std.mem.indexOfScalar(u8, t, 0)) |pos| {
                            if (pos < len)
                                l = pos; // be sure length is the small one.
                        }
                        @memcpy(text[0..l], t[0..l]);
                    }
//                        if (cwnd_text != null)
//                            strncpy(text, cwnd_text, len);
                },
                df.COMBOBOX,
                df.EDITBOX => {
                    _ = cwin.sendMessage(df.GETTEXT,@intCast(@intFromPtr(text)),len);
                },
                else => {
                }
            }
        }
    }
}

// ------- set the text of a listbox control window ------
pub fn GetDlgListText(wnd:df.WINDOW, text:[*c]u8, cmd:c) void {
    const db:*Dialogs.DBOX = @alignCast(@ptrCast(wnd.*.extension));
    const control = FindCommand(db, cmd, df.LISTBOX);
    if (control) |ct| {
        var sel:c_int = -1; // cannot use isize here, otherwise, ListBox.zig GetTextMsg will fail
        if (ct.win) |cwin| {
            _ = cwin.sendMessage(df.LB_CURRENTSELECTION, @intCast(@intFromPtr(&sel)), 0);
            _ = cwin.sendMessage(df.LB_GETTEXT, @intCast(@intFromPtr(text)), @intCast(sel));
        }
    }
}

// ----- return command code of in-focus control window ----
fn inFocusCommand(db:?*Dialogs.DBOX) c {
    if (db) |box| {
        for(&box.*.ctl) |*ctl| {
            if (ctl.*.Class == 0)
                break;
            const w = ctl.win;
            if (w == Window.inFocus) {
                return ctl.*.command;
            }
        }
    }
    return c.ID_NULL;
}

// -------- find a specified control structure -------
pub fn FindCommand(db:*Dialogs.DBOX, cmd:c, Class:df.CLASS) ?*Dialogs.CTLWINDOW {
    for(&db.*.ctl) |*ct| {
        if (ct.*.Class == 0)
            break;
        if (Class == -1 or ct.*.Class == Class) {
            if (cmd == ct.*.command) {
                return @constCast(ct);
            }
        }
    }
    return null;
}

// ---- return the window handle of a specified command ----
pub fn ControlWindow(db:*Dialogs.DBOX, cmd:c) ?*Window {
    for(&db.*.ctl) |*ct| {
        if (ct.*.Class == 0)
            break;
        if (ct.*.Class != df.TEXT and cmd == ct.*.command) {
            if (ct.win) |cwin| {
                return cwin;
            }
        }
    }
    return null;
}

// --- return a pointer to the control structure that matches a window ---
pub export fn WindowControl(db:*Dialogs.DBOX, wnd:df.WINDOW) ?*Dialogs.CTLWINDOW {
    for(&db.*.ctl) |*ct| {
        if (ct.*.Class == 0)
            break;
        if (ct.win) |cwin| {
            const cwnd = cwin.win;
            if (cwnd == wnd) {
                return @constCast(ct);
            }
        }
    }
    return null;
}

// ---- set a control ON or OFF -----
pub export fn ControlSetting(db:*Dialogs.DBOX, cmd: c, Class: c_int, setting: c_int) void {
    const control = FindCommand(db, cmd, Class);
    if (control) |ct| {
        ct.*.isetting = @intCast(setting);
//        if (ct.*.wnd != null)
        if (ct.win) |_| {
            ct.*.setting = @intCast(setting);
        }
    }
}

// ----- test if a control is on or off -----
pub fn isControlOn(db:*Dialogs.DBOX, cmd: c, Class: c_int) bool {
    const control = FindCommand(db, cmd, Class);
    const rtn = if (control) |ct| (if (ct.win) |_| ct.*.setting else ct.*.isetting) else df.FALSE;
    return (rtn == df.TRUE);
}

// -- find control structure associated with text control --
fn AssociatedControl(db:*Dialogs.DBOX, Tcmd: c) *Dialogs.CTLWINDOW {
    for(&db.*.ctl) |*ct| {
        if (ct.*.Class == 0)
            break;
        if (ct.*.Class != df.TEXT) {
            if (ct.*.command == Tcmd) {
                return ct;
            }
        }
    }
    return &db.*.ctl[0]; // FIXME
}

// --- process dialog box shortcut keys ---
pub fn dbShortcutKeys(db:*Dialogs.DBOX, ky: c_int) bool {
    const ch = df.AltConvert(@intCast(ky));

    if (ch != 0) {
        for (&db.*.ctl) |*ctl| {
            var ct = ctl;
            if (ct.*.Class == 0)
                break;
            if (ct.*.itext) |itext| {
                const text = itext;
                if (std.mem.indexOfScalar(u8, text, df.SHORTCUTCHAR)) |pos| {
                    if ((pos < text.len-1) and (std.ascii.toLower(text[pos+1]) == ch)) {
                        if (ct.win) |cwin| {
                            if (ct.*.Class == df.TEXT) {
                                ct = AssociatedControl(db, ct.*.command);
                            }
                            if (ct.*.Class == df.RADIOBUTTON) {
                                radio.SetRadioButton(db, ct);
                            } else if (ct.*.Class == df.CHECKBOX) {
                                ct.*.setting ^= df.ON;
                                _ = cwin.sendMessage(df.PAINT, 0, 0);
                            }  else if (ct.*.Class != 0) { // this IF is not necessary
                                _ = cwin.sendMessage(df.SETFOCUS, df.TRUE, 0);
                                if (ct.*.Class == df.BUTTON)
                                   _ = cwin.sendMessage(df.KEYBOARD, '\r',0);
                            }
                            return true;
                        }
                    }
                }
            }
        }
    }
    return false;
}

// ---- change the focus to the first control ---
pub fn FirstFocus(db:*Dialogs.DBOX) void {
    const len = db.*.ctl.len;
    for (0..len) |idx| {
        const ct = &db.*.ctl[idx];
        if (ct.*.Class != 0) {
            if ((ct.*.Class != df.TEXT) and (ct.*.Class != df.BOX)) {
                if (ct.win) |cwin| {
                    _ = cwin.sendMessage(df.SETFOCUS, df.TRUE, 0);
                }
                return;
            }
            if (idx < len-2) {
                const next = &db.*.ctl[idx+1];
                if (next.*.Class == 0)
                    return;
            }
        }
    }
}

// ---- change the focus to the next control ---
pub fn NextFocus(db:*Dialogs.DBOX) void {
    const control = WindowControl(db, Window.inFocusWnd());
    if (control) |ctl| {
        const len = db.*.ctl.len;
        var start:usize = 0;
        for(&db.*.ctl, 0..) |*ct, idx| {
            if (ct == ctl) {
                start = idx;
                break;
            }
        }
    
        var pos = start;
        var ct = &db.*.ctl[pos];
        for (0..len) |_| {
            pos += 1;
            ct = &db.*.ctl[pos];
            if (ct.*.Class == 0) {
                pos = 0;
                ct = &db.*.ctl[pos];
            }
            if ((ct.*.Class == df.TEXT) and (ct.*.Class != df.BOX)) {
                continue;
            }
            if (ct.win) |cwin| {
                _ = cwin.sendMessage(df.SETFOCUS, df.TRUE, 0);
            }
            break;
        }
    }
}

// ---- change the focus to the previous control ---
// FIXME: not tested.
pub fn PrevFocus(db:*Dialogs.DBOX) void {
    const control = WindowControl(db, Window.inFocusWnd());
    if (control) |ctl| {
        const len = db.*.ctl.len;
        var start:usize = 0;
        var last:usize = 0;
        for(&db.*.ctl, 0..) |*ct, idx| {
            if (ct == ctl) {
                start = idx;
            }
            last = idx; // find last valid control
            if (ct.*.Class == 0)
                break;
        }
    
        var pos = start;
        var ct = &db.*.ctl[pos];
        for (0..len) |_| {
            if (pos == 0) {
                pos = last;
            } else {
                pos -= 1;
            }
           
            ct = &db.*.ctl[pos];
            if ((ct.*.Class == df.TEXT) and (ct.*.Class != df.BOX)) {
                continue;
            }
            if (ct.win) |cwin| {
                _ = cwin.sendMessage(df.SETFOCUS, df.TRUE, 0);
            }
            break;
        }
    }
//                do      {
//                        if (ct == db->ctl)      {
//                                if (looped)
//                                        return;
//                                looped++;
//                                while (ct->Class)
//                                        ct++;
//                        }
//                        --ct;
//                } while (ct->Class == TEXT || ct->Class == BOX);
//                SendMessage(ct->wnd, SETFOCUS, TRUE, 0);
}

pub export fn SetFocusCursor(wnd:df.WINDOW) void {
    if (wnd == Window.inFocusWnd()) {
        _ = q.SendMessage(null, df.SHOW_CURSOR, 0, 0);
        _ = q.SendMessage(wnd, df.KEYBOARD_CURSOR, 1, 0);
    }
}

// Accessories
pub fn GetControl(win:*Window) ?*Dialogs.CTLWINDOW {
    return win.ct;
}

pub fn GetDlgText(db:*Dialogs.DBOX, cmd: c) [*c]u8 {
    return GetDlgTextString(db, cmd, df.TEXT);
}

pub fn GetDlgTextBox(db:*Dialogs.DBOX, cmd: c) [*c]u8 {
    return GetDlgTextString(db, cmd, df.TEXTBOX);
}

pub fn GetEditBoxText(db:*Dialogs.DBOX, cmd: c) [*c]u8 {
    return GetDlgTextString(db, cmd, df.EDITBOX);
}

pub fn GetComboBoxText(db:*Dialogs.DBOX, cmd: c) [*c]u8 {
    return GetDlgTextString(db, cmd, df.COMBOBOX);
}

pub fn SetDlgText(db:*Dialogs.DBOX, cmd: c, s:[*c]u8) void {
    SetDlgTextString(db, cmd, s, df.TEXT);
}

pub fn SetDlgTextBox(db:*Dialogs.DBOX, cmd: c, s:[*c]u8) void {
    SetDlgTextString(db, cmd, s, df.TEXTBOX);
}

pub fn SetEditBoxText(db:*Dialogs.DBOX, cmd: c, s:[*c]u8) void {
    SetDlgTextString(db, cmd, s, df.EDITBOX);
}

pub fn SetComboBoxText(db:*Dialogs.DBOX, cmd: c, s:[*c]u8) void {
    SetDlgTextString(db, cmd, s, df.COMBOBOX);
}

pub fn SetDlgTitle(db:*Dialogs.DBOX, ttl:[*c]u8) void {
    // currently not in use
    if (ttl) |t| {
      db.*.dwnd.title = std.mem.span(t);
    }
}

pub fn SetCheckBox(db:*Dialogs.DBOX, cmd: c) void {
    ControlSetting(db, cmd, df.CHECKBOX, df.ON);
}

pub fn ClearCheckBox(db:*Dialogs.DBOX, cmd: c) void {
    ControlSetting(db, cmd, df.CHECKBOX, df.OFF);
}

pub fn EnableButton(db:*Dialogs.DBOX, cmd: c) void {
    ControlSetting(db, cmd, df.BUTTON, df.ON);
}

pub fn DisableButton(db:*Dialogs.DBOX, cmd: c) void {
    ControlSetting(db, cmd, df.BUTTON, df.OFF);
}

pub fn ButtonEnabled(db:*Dialogs.DBOX, cmd: c) bool {
    return isControlOn(db, cmd, df.BUTTON);
}

pub fn CheckBoxEnabled(db:*Dialogs.DBOX, cmd: c) bool {
    return isControlOn(db, cmd, df.CHECKBOX);
}
