const std = @import("std");
const root = @import("root.zig");
const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const WndProc = @import("WndProc.zig");
const q = @import("Message.zig");
const helpbox = @import("HelpBox.zig");
const sysmenu = @import("SystemMenu.zig");
const Normal = @import("Normal.zig");

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
    wndproc: ?*const fn (win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool) c_int {

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
    return @intCast(rtn);
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
//                if (df.DisplayHelp(wnd, ct.*.help) == 0) {
                if (helpbox.DisplayHelp(win, std.mem.span(ct.*.help)) == 0) {
                    _ = q.SendMessage(Window.GetParent(wnd),df.COMMAND,df.ID_HELP,0);
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
//            if (Normal.isDerivedFrom(win, df.LISTBOX) == false) {
//                p1 = CTRL_FIVE;
//                p2 = LEFTSHIFT;
//            }
//        },
//        case BS:
//            if (Normal.isDerivedFrom(win, df.EDITBOX) == false)    {
//                p1 = CTRL_FIVE;
//                p2 = LEFTSHIFT;
//            }
//            break;
//        case DN:
//            if ((Normal.isDerivedFrom(win, df.LISTBOX) == false) and
//                    (Normal.isDerivedFrom(win, df.COMBOBOX) == false))
//                p1 = '\t';
//            break;
//        case FWD:
//            if (Normal.isDerivedFrom(win, df.EDITBOX) == false)
//                p1 = '\t';
//            break;
        '\r' => {
            if (((Normal.isDerivedFrom(win, df.EDITBOX) and (df.isMultiLine(wnd) > 0)) == false) and
                (Normal.isDerivedFrom(win, df.BUTTON) == false) and
                (Normal.isDerivedFrom(win, df.LISTBOX) == false)) {
                _ = q.SendMessage(Window.GetParent(wnd), df.COMMAND, df.ID_OK, 0);
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
    const ct = wnd.*.ct;
    if (ct.*.Class != df.BUTTON) {
        if ((ct.*.Class != df.SPINBUTTON) and (ct.*.Class != df.COMBOBOX)) {
            if ((ct.*.Class != df.EDITBOX) and (ct.*.Class != df.LISTBOX)) {
                wnd.*.WindowColors[df.FRAME_COLOR][df.FG] =
                                        df.GetParent(wnd).*.WindowColors[df.FRAME_COLOR][df.FG];
                wnd.*.WindowColors[df.FRAME_COLOR][df.BG] =
                                        df.GetParent(wnd).*.WindowColors[df.FRAME_COLOR][df.BG];
                wnd.*.WindowColors[df.STD_COLOR][df.FG] =
                                        df.GetParent(wnd).*.WindowColors[df.STD_COLOR][df.FG];
                wnd.*.WindowColors[df.STD_COLOR][df.BG] =
                                        df.GetParent(wnd).*.WindowColors[df.STD_COLOR][df.BG];
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
//    CTLWINDOW *ct = GetControl(wnd);
    const ct = df.GetControl(wnd);
    if (ct != null)    {
        ct.*.wnd = null;
        if (Window.GetParent(wnd).*.ReturnCode == df.ID_OK) {
            if (ct.*.Class == df.EDITBOX or ct.*.Class == df.COMBOBOX)  {
                // should use strlen() instead ?
                const len = wnd.*.textlen;
                if (ct.*.itext != null) {
                    if(root.global_allocator.realloc(ct.*.itext[0..len], len)) |buf| {
                        @memcpy(buf, wnd.*.text[0..len]);
                        ct.*.itext = buf.ptr;
                    } else |_| {
                    }
                } else {
                    if(root.global_allocator.allocSentinel(u8, len, 0)) |buf| {
                        @memset(buf, 0);
                        @memcpy(buf, wnd.*.text[0..len]);
                        ct.*.itext = buf.ptr;
                    } else |_| {
                    }
                } 
                if (df.isMultiLine(wnd) == df.FALSE) {
                    // remove last \n
                    if (std.mem.indexOfScalar(u8, ct.*.itext[0..len], '\n')) |pos| {
                        ct.*.itext[pos] = 0;
                    }
                }
//                ct->itext=DFrealloc(ct->itext,strlen(wnd->text)+1);
//                strcpy(ct->itext, wnd->text);
//                if (!isMultiLine(wnd))    {
//                        char *cp = ct->itext+strlen(ct->itext)-1;
//                        if (*cp == '\n')
//                        *cp = '\0';
//                }
            } else if (ct.*.Class == df.RADIOBUTTON or ct.*.Class == df.CHECKBOX) {
                ct.*.isetting = ct.*.setting;
            }
        }
    }
}

// -- generic window processor used by dialog box controls --
pub fn ControlProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    // win can be null ? probably not.
    const wnd = win.win;
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
            if ((df.GetClass(wnd) == df.EDITBOX) or
                (df.GetClass(wnd) == df.LISTBOX) or
                (df.GetClass(wnd) == df.TEXTBOX)) {
                SetScrollBars(win);
            }
        },
        df.BORDER => {
            FixColors(win);
            if (df.GetClass(wnd) == df.EDITBOX) {
                const oldFocus = df.inFocus;
                df.inFocus = null;
                _ = root.DefaultWndProc(wnd, msg, p1, p2);
                df.inFocus = oldFocus;
                return true;
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
                        _ = q.SendMessage(oldFocus, df.BORDER, 0, 0);
                        _ = q.SendMessage(pwnd, df.SHOW_WINDOW, 0, 0);
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
                        _ = q.SendMessage(pwnd, df.COMMAND,
                                 inFocusCommand(db), df.ENTERFOCUS);
                    }
                    return true;
                }
            } else {
                _ = q.SendMessage(pwnd, df.COMMAND,
                            inFocusCommand(db), df.LEAVEFOCUS);
            }
        },
        df.CLOSE_WINDOW => {
//            df.CtlCloseWindowMsg(wnd);
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
    const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));
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
                sysmenu.BuildSystemMenu(win);
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
                if (helpbox.DisplayHelp(win, std.mem.span(ct.*.help))>0) {
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
            const rtn = helpbox.DisplayHelp(win, std.mem.span(db.*.HelpName));
            return (rtn == df.TRUE);
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
                const db:*df.DBOX = @alignCast(@ptrCast(extension));
                _ = win.sendMessage(df.COMMAND, inFocusCommand(db), msg);
            }
        },
        df.SETFOCUS => {
            if ((p1 != 0) and (wnd.*.dfocus != null) and (df.isVisible(wnd) > 0)) {
                return if (q.SendMessage(wnd.*.dfocus, df.SETFOCUS, df.TRUE, 0) == df.TRUE) true else false;
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
            if ((wnd.*.dfocus != null) and (df.isVisible(wnd) > 0))
                _ = q.SendMessage(wnd.*.dfocus, df.SETFOCUS, df.TRUE, 0);
            return rtn;
        },
        df.CLOSE_WINDOW => {
            if (p1 == 0) {
                _ = win.sendMessage(df.COMMAND, df.ID_CANCEL, 0);
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
pub export fn GetDlgTextString(db:*df.DBOX, cmd:c_uint, Class:df.CLASS) callconv(.c) [*c]u8 {
    const ct = df.FindCommand(db, cmd, Class);
    return if (ct) |c| c.*.itext else null;
}

// ------- set the text of a control specification ------
pub export fn SetDlgTextString(db:*df.DBOX, cmd:c_uint, text: [*c]u8, Class:df.CLASS) callconv(.c) void {
    const control = df.FindCommand(db, cmd, Class);
    if (control) |ct| {
        if (text != null) {
            if (ct.*.Class == df.TEXT) {
                ct.*.itext = text;  // text may not go out of scope
            } else {
                if (ct.*.itext) |_| {
                    const ilen = df.strlen(ct.*.itext);
                    const len = df.strlen(text);
                    if(root.global_allocator.realloc(ct.*.itext[0..ilen], len)) |buf| {
                        @memcpy(buf, text[0..len]);
                        ct.*.itext = buf.ptr;
                    } else |_| {
                    }
                } else {
                    const len = df.strlen(text);
                    if(root.global_allocator.allocSentinel(u8, len, 0)) |buf| {
                        @memset(buf, 0);
                        @memcpy(buf, text[0..len]);
                        ct.*.itext = buf.ptr;
                    } else |_| {
                    }
                }
//                ct.*.itext = df.DFrealloc(ct.*.itext, df.strlen(text)+1);
//                df.strcpy(ct.*.itext, text);
            }
        } else {
            if (ct.*.Class == df.TEXT) {
                ct.*.itext = @constCast(&[_]u8{0});
            } else {
                const ilen = df.strlen(ct.*.itext);
                root.global_allocator.free(ct.*.itext[0..ilen]);
//                root.global_allocator.free(ct.*.itext);
//                df.free(ct.*.itext);
                ct.*.itext = null;
            }
        }
        if (ct.*.wnd != null) {
            const w:df.WINDOW = @ptrCast(@alignCast(ct.*.wnd));
            if (text != null) {
                _ = q.SendMessage(w, df.SETTEXT, @intCast(@intFromPtr(text)), 0);
            } else {
                _ = q.SendMessage(w, df.CLEARTEXT, 0, 0);
            }
            _ = q.SendMessage(w, df.PAINT, 0, 0);
        }
    }
}

// ------- set the text of a control window ------
pub export fn PutItemText(wnd:df.WINDOW, cmd:c_uint, text:[*c]u8) callconv(.c) void {
    const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));
    var control = df.FindCommand(db, cmd, df.EDITBOX);

    if (control == null)
        control = df.FindCommand(db, cmd, df.TEXTBOX);
    if (control == null)
        control = df.FindCommand(db, cmd, df.COMBOBOX);
    if (control == null)
        control = df.FindCommand(db, cmd, df.LISTBOX);
    if (control == null)
        control = df.FindCommand(db, cmd, df.SPINBUTTON);
    if (control == null)
        control = df.FindCommand(db, cmd, df.TEXT);
    if (control) |ct| {
        // assume cwnd cannot be null ?
        const cwnd:df.WINDOW = @ptrCast(@alignCast(ct.*.wnd));
        switch (ct.*.Class) {
            df.COMBOBOX,
            df.EDITBOX => {
                _ = q.SendMessage(cwnd, df.CLEARTEXT, 0, 0);
                _ = q.SendMessage(cwnd, df.ADDTEXT, @intCast(@intFromPtr(text)), 0);
                if (df.isMultiLine(cwnd) == df.FALSE) {
                    _ = q.SendMessage(cwnd, df.PAINT, 0, 0);
                }
            },
            df.LISTBOX,
            df.TEXTBOX,
            df.SPINBUTTON => {
                _ = q.SendMessage(cwnd, df.ADDTEXT, @intCast(@intFromPtr(text)), 0);
            },
            df.TEXT => {
                _ = q.SendMessage(cwnd, df.CLEARTEXT, 0, 0);
                _ = q.SendMessage(cwnd, df.ADDTEXT, @intCast(@intFromPtr(text)), 0);
                _ = q.SendMessage(cwnd, df.PAINT, 0, 0);
            },
            else => {
            }
        }
    }
}

// ------- get the text of a control window ------
pub export fn GetItemText(wnd:df.WINDOW, cmd:c_uint, text:[*c]u8, len:c_int) callconv(.c) void {
    const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));
    var control = df.FindCommand(db, cmd, df.EDITBOX);

    if (control == null)
        control = df.FindCommand(db, cmd, df.COMBOBOX);
    if (control == null)
        control = df.FindCommand(db, cmd, df.TEXTBOX);
    if (control == null)
        control = df.FindCommand(db, cmd, df.TEXT);
    if (control) |ct| {
        if (ct.*.wnd != null) {
            const cwnd:df.WINDOW = @ptrCast(@alignCast(ct.*.wnd));
            if (Window.get_zin(cwnd)) |cwin| {
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
                        _ = q.SendMessage(cwnd,df.GETTEXT,@intCast(@intFromPtr(text)),len);
                    },
                    else => {
                    }
                }
            }
        }
    }
}

// ------- set the text of a listbox control window ------
pub export fn GetDlgListText(wnd:df.WINDOW, text:[*c]u8, cmd:c_uint) callconv(.c) void {
    const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));
    const ct = df.FindCommand(db, cmd, df.LISTBOX);
    const cwnd:df.WINDOW = @ptrCast(@alignCast(ct.*.wnd));

    var sel:c_int = -1; // cannot use isize here, otherwise, ListBox.zig GetTextMsg will fail
    _ = q.SendMessage(cwnd, df.LB_CURRENTSELECTION, @intCast(@intFromPtr(&sel)), 0);
    _ = q.SendMessage(cwnd, df.LB_GETTEXT, @intCast(@intFromPtr(text)), @intCast(sel));
}

// ----- return command code of in-focus control window ----
fn inFocusCommand(db:?*df.DBOX) c_int {
    if (db) |box| {
        for(&box.*.ctl) |*ctl| {
            if (ctl.*.Class == 0)
                break;
            const w:df.WINDOW = @alignCast(@ptrCast(ctl.*.wnd));
            if (w == df.inFocus) {
                return ctl.*.command;
            }
        }
    }
    return -1;
}

// -------- find a specified control structure -------
pub export fn FindCommand(db:*df.DBOX, cmd:c_uint, Class:df.CLASS) callconv(.c) ?*df.CTLWINDOW {
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
pub export fn ControlWindow(db:*df.DBOX, cmd:c_uint) callconv(.c) df.WINDOW {
    for(&db.*.ctl) |*ct| {
        if (ct.*.Class == 0)
            break;
        if (ct.*.Class != df.TEXT and cmd == ct.*.command) {
                return @ptrCast(@alignCast(ct.*.wnd));
        }
    }
    return null;
}

// --- return a pointer to the control structure that matches a window ---
pub export fn WindowControl(db:*df.DBOX, wnd:df.WINDOW) ?*df.CTLWINDOW {
    for(&db.*.ctl) |*ct| {
        const cwnd:df.WINDOW = @ptrCast(@alignCast(ct.*.wnd));
        if (ct.*.Class == 0)
            break;
        if (cwnd == wnd) {
            return @constCast(ct);
        }
    }
    return null;
}

// ---- set a control ON or OFF -----
pub export fn ControlSetting(db:*df.DBOX, cmd: c_uint, Class: c_int, setting: c_int) void {
    const control = df.FindCommand(db, cmd, Class);
    if (control) |ct| {
        ct.*.isetting = @intCast(setting);
        if (ct.*.wnd != null)
            ct.*.setting = @intCast(setting);
    }
}

// ----- test if a control is on or off -----
pub export fn isControlOn(db:*df.DBOX, cmd: c_uint, Class: c_int) df.BOOL {
    const control = df.FindCommand(db, cmd, Class);
    return if (control) |ct| (if (ct.*.wnd) |_| ct.*.setting else ct.*.isetting) else df.FALSE;
}
