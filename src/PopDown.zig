const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");

var py:c_int = -1;
var CurrentMenuSelection:c_int = 0;

// ------------ CREATE_WINDOW Message -------------
fn CreateWindowMsg(win:*Window) c_int {
    const wnd = win.win;
    win.ClearAttribute(df.HASTITLEBAR  |
                       df.VSCROLLBAR   |
                       df.MOVEABLE     |
                       df.SIZEABLE     |
                       df.HSCROLLBAR);
    // ------ adjust to keep popdown on screen -----
    var adj:c_int = df.SCREENHEIGHT-1-wnd.*.rc.bt;
    if (adj < 0) {
        wnd.*.rc.tp += adj;
        wnd.*.rc.bt += adj;
    }
    adj = df.SCREENWIDTH-1-wnd.*.rc.rt;
    if (adj < 0) {
        wnd.*.rc.lf += adj;
        wnd.*.rc.rt += adj;
    }
    const rtn = root.zBaseWndProc(df.POPDOWNMENU, win, df.CREATE_WINDOW, 0, 0);
    _ = win.sendMessage(df.CAPTURE_MOUSE, 0, 0);
    _ = win.sendMessage(df.CAPTURE_KEYBOARD, 0, 0);
    _ = q.SendMessage(null, df.SAVE_CURSOR, 0, 0);
    _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
    wnd.*.oldFocus = df.inFocus;
    df.inFocus = wnd;
    return rtn;
}

// --------- LEFT_BUTTON Message ---------
fn LeftButtonMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    const my:c_int = @intCast(p2 - win.GetTop());
    if (rect.InsideRect(@intCast(p1), @intCast(p2), rect.ClientRect(win))) {
        if (my != py) {
            _ = win.sendMessage(df.LB_SELECTION,
                    @intCast(wnd.*.wtop+my-1), df.TRUE);
            py = my;
        }
    } else {
        const parent = Window.GetParent(wnd);
        if (Window.get_zin(parent)) |prt| {
            if (p2 == prt.GetTop()) {
                if (df.GetClass(parent) == df.MENUBAR) {
                    q.PostMessage(parent, df.LEFT_BUTTON, p1, p2);
                }
            }
        }
    }
}

// -------- BUTTON_RELEASED Message --------
fn ButtonReleasedMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    py = -1;
    if (rect.InsideRect(@intCast(p1), @intCast(p2), rect.ClientRect(win))) {
        const sel:c_uint = @intCast(p2 - win.GetClientTop());
        const tl = df.TextLine(wnd, sel);
        if (tl[0] != df.LINE)
            _ = win.sendMessage(df.LB_CHOOSE, @intCast(wnd.*.selection), 0);
    } else {
        const pwnd = Window.GetParent(wnd);
        if (Window.get_zin(pwnd)) |ptr| {
            if ((df.GetClass(pwnd) == df.MENUBAR) and (p2==ptr.GetTop()))
                return false;
            if (p1 == ptr.GetLeft()+2)
                return false;
        }
        _ = win.sendMessage(df.CLOSE_WINDOW, 0, 0);
        return true;
    }
    return false;
}

// --------- PAINT Message --------
fn PaintMsg(win:*Window) void {
    const wnd = win.win;
    var sep = [_]u8{0}**df.MAXPOPWIDTH;
    var sel = [_]u8{0}**df.MAXPOPWIDTH;
    const wd:usize = @intCast(df.MenuWidth(&wnd.*.mnu.*.Selections[0])-2);
    for (0..wd) |idx| {
        sep[idx] = df.LINE;
    }

    _ = win.sendMessage(df.CLEARTEXT, 0, 0);
    wnd.*.selection = wnd.*.mnu.*.Selection;
    for (wnd.*.mnu.*.Selections) |mnu| {
        if (mnu.SelectionTitle) |title| {
            if (title[0] == df.LINE) {
                _ = win.sendTextMessage(df.ADDTEXT, sep[0..wd], 0);
            } else {
                df.PaintPopDownSelection(wnd, @constCast(&mnu), &sel);
                _ = win.sendTextMessage(df.ADDTEXT, &sel, 0);
            }
        }
    }
}

fn BorderMsg(win:*Window) c_int {
    const wnd = win.win;
    var rtn = df.TRUE;
    if (wnd.*.mnu) |_| {
        const currFocus = df.inFocus;
        df.inFocus = null;
        rtn = root.zBaseWndProc(df.POPDOWNMENU, win, df.BORDER, 0, 0);
        df.inFocus = currFocus;
        for (0..@intCast(win.ClientHeight())) |i| {
            if (df.TextLine(wnd, i)[0] == df.LINE) {
                df.wputch(wnd, df.LEDGE, 0, @intCast(i+1));
                df.wputch(wnd, df.REDGE, @intCast(win.WindowWidth()-1), @intCast(i+1));
            }
        }
    }
    return rtn;
}

// -------------- LB_CHOOSE Message --------------
fn LBChooseMsg(win:*Window, p1:df.PARAM) void {
    const wnd = win.win;
    const popdown = &wnd.*.mnu.*.Selections[@intCast(p1)];
    wnd.*.mnu.*.Selection = @intCast(p1);
    if ((popdown.*.Attrib & df.INACTIVE) == 0) {
        const pwnd = Window.GetParent(wnd);
        if ((popdown.*.Attrib & df.TOGGLE) > 0) {
            popdown.*.Attrib ^= df.CHECKED;
        }
        if (pwnd != null) {
            CurrentMenuSelection = @intCast(p1);
            q.PostMessage(pwnd, df.COMMAND, popdown.*.ActionId, 0); // p2 was p1
        }
    } else {
        df.beep();
    }
}

// ---------- KEYBOARD Message ---------
fn KeyboardMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    if (wnd.*.mnu) |_| {
        var c:c_uint = @intCast(p1);
        if (c < 128) { // FIXME unicode
            c = std.ascii.toLower(@intCast(c));
        }
        const a = df.AltConvert(c);
        for(wnd.*.mnu.*.Selections, 0..) |popdown, sel| {
            if (popdown.SelectionTitle) |title| {
                if (std.mem.indexOfScalar(u8, std.mem.span(title), df.SHORTCUTCHAR)) |idx| {
                    var sc:u8 = title[idx+1];
                    if (sc < 256) {
                        sc = std.ascii.toLower(sc);
                    }
                    if ((sc == c) or ((a > 0) and (sc == a)) or
                           (popdown.Accelerator == c)) {
                        q.PostMessage(wnd, df.LB_SELECTION, @intCast(sel), 0);
                        q.PostMessage(wnd, df.LB_CHOOSE, @intCast(sel), df.TRUE);
                        return true;
                    }
                }
            }
        }
    }
    switch (p1) {
        df.F1 => {
            // if (ActivePopDown == NULL)
            if (wnd.*.mnu.*.Selections[0].SelectionTitle == null) {
                _ = q.SendMessage(Window.GetParent(wnd), df.KEYBOARD, p1, p2);
            } else {
                _ = df.DisplayHelp(wnd, wnd.*.mnu.*.Selections[@intCast(wnd.*.selection)].help);
            }
            return true;
        },
        df.ESC => {
            _ = win.sendMessage(df.CLOSE_WINDOW, 0, 0);
            return true;
        },
        df.FWD,
        df.BS => {
            if (df.GetClass(Window.GetParent(wnd)) == df.MENUBAR) {
                q.PostMessage(Window.GetParent(wnd), df.KEYBOARD, p1, p2);
            }
            return true;
        },
        df.UP => {
            if (wnd.*.selection == 0) {
                if (wnd.*.wlines == win.ClientHeight()) {
                    q.PostMessage(wnd, df.LB_SELECTION,
                                    @intCast(wnd.*.wlines-1), df.FALSE);
                    return true;
                }
            }
        },
        df.DN => {
            if (wnd.*.selection == wnd.*.wlines-1) {
                if (wnd.*.wlines == win.ClientHeight()) {
                    q.PostMessage(wnd, df.LB_SELECTION, 0, df.FALSE);
                    return true;
                }
            }
        },
        df.HOME,
        df.END,
        '\r' => {
        },
        else => {
            return true;
        }
    }
    return false;
}

// ----------- CLOSE_WINDOW Message ----------
fn CloseWindowMsg(win:*Window) c_int {
    const wnd = win.win;
    const pwnd = Window.GetParent(wnd);
    _ = win.sendMessage(df.RELEASE_MOUSE, 0, 0);
    _ = win.sendMessage(df.RELEASE_KEYBOARD, 0, 0);
    _ = q.SendMessage(null, df.RESTORE_CURSOR, 0, 0);
    df.inFocus = wnd.*.oldFocus;
    const rtn = root.zBaseWndProc(df.POPDOWNMENU, win, df.CLOSE_WINDOW, 0, 0);
    _ = q.SendMessage(pwnd, df.CLOSE_POPDOWN, 0, 0);
    return rtn;
}

// - Window processing module for POPDOWNMENU window class -
pub fn PopDownProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win);
        },
        df.LEFT_BUTTON => {
            LeftButtonMsg(win, p1, p2);
            return df.FALSE;
        },
        df.DOUBLE_CLICK => {
            return df.TRUE;
        },
        df.LB_SELECTION => {
            const sel:c_uint = @intCast(p1);
            const l = df.TextLine(wnd, sel);
            if (l[0] == df.LINE) {
                return df.TRUE;
            }
            wnd.*.mnu.*.Selection = @intCast(p1);
        },
        df.BUTTON_RELEASED => {
            if (ButtonReleasedMsg(win, p1, p2))
                return df.TRUE;
        },
        df.BUILD_SELECTIONS => {
            const pp:usize = @intCast(p1);
            wnd.*.mnu = @ptrFromInt(pp);
            wnd.*.selection = wnd.*.mnu.*.Selection;
        },
        df.PAINT => {
            if (wnd.*.mnu == null)
                return df.TRUE;
//            df.PaintMsg(wnd);
            PaintMsg(win);
        },
        df.BORDER => {
            return BorderMsg(win);
        },
        df.LB_CHOOSE => {
            LBChooseMsg(win, p1);
            return df.TRUE;
        },
        df.KEYBOARD => {
            if (KeyboardMsg(win, p1, p2))
                return df.TRUE;
        },
        df.CLOSE_WINDOW => {
            return CloseWindowMsg(win);
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.POPDOWNMENU, win, msg, p1, p2);
}
