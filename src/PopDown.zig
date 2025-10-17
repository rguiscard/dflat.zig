const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const k = @import("Classes.zig").CLASS;
const rect = @import("Rect.zig");
const helpbox = @import("HelpBox.zig");
const menus = @import("Menus.zig");
const cfg = @import("Config.zig");

var py:c_int = -1;
pub var CurrentMenuSelection:c_int = 0;

// ------------ CREATE_WINDOW Message -------------
fn CreateWindowMsg(win:*Window) bool {
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
    const rtn = root.BaseWndProc(k.POPDOWNMENU, win, df.CREATE_WINDOW, q.none);
    _ = win.sendMessage(df.CAPTURE_MOUSE, .{.capture=.{false, null}});
    _ = win.sendMessage(df.CAPTURE_KEYBOARD, .{.capture=.{false, null}});
    _ = q.SendMessage(null, df.SAVE_CURSOR, q.none);
    _ = q.SendMessage(null, df.HIDE_CURSOR, q.none);
    win.oldFocus = Window.inFocus;
    Window.inFocus = win;
    return rtn;
}

// --------- LEFT_BUTTON Message ---------
fn LeftButtonMsg(win:*Window, x:usize, y:usize) void {
    const my:usize = if (y > win.GetTop()) y - win.GetTop() else 0;
    if (rect.InsideRect(@intCast(x), @intCast(y), rect.ClientRect(win))) {
        if (my != py) {
            _ = win.sendMessage(df.LB_SELECTION,
                    .{.legacy=.{@intCast(win.wtop+my-1), df.TRUE}});
            py = @intCast(my);
        }
    } else {
        if (win.parent) |pw| {
            if (y == pw.GetTop()) {
                if (pw.Class == k.MENUBAR) {
                    q.PostMessage(pw, df.LEFT_BUTTON, .{.position=.{x, y}});
                }
            }
        }
    }
}

// -------- BUTTON_RELEASED Message --------
fn ButtonReleasedMsg(win:*Window, x:usize, y:usize) bool {
    const wnd = win.win;
    py = -1;
    if (rect.InsideRect(@intCast(x), @intCast(y), rect.ClientRect(win))) {
        const sel:usize = y - win.GetClientTop();
//        const tl = df.TextLine(wnd, sel);
//        if (tl[0] != df.LINE)
        const tl = win.textLine(sel);
        if (wnd.*.text[tl] != df.LINE)
            _ = win.sendMessage(df.LB_CHOOSE, .{.legacy=.{win.selection, 0}});
    } else {
        const pwin = win.getParent();
        if ((pwin.getClass() == k.MENUBAR) and (y==pwin.GetTop()))
            return false;
        if (x == pwin.GetLeft()+2)
            return false;
        _ = win.sendMessage(df.CLOSE_WINDOW, .{.yes=false});
        return true;
    }
    return false;
}

fn PaintPopDownSelection(win:*Window, pd1:*menus.PopDown, sel:[]u8) void {
    const buf = sel;
    if (win.mnu) |mnu| {
//        const ActivePopDown = &mnu.*.Selections[0];
        const selections:[]menus.PopDown = &mnu.*.Selections;
        const sel_wd:usize = SelectionWidth(@constCast(&selections));
        const m_wd:usize = @intCast(MenuWidth(@constCast(&selections)));
        var idx:usize = 0;

        @memset(buf, 0);
        if (pd1.*.Attrib.INACTIVE) {
            // ------ inactive menu selection -----
            buf[0] = df.CHANGECOLOR;
            buf[1] = win.WindowColors [df.HILITE_COLOR] [df.FG]|0x80;
            buf[2] = win.WindowColors [df.STD_COLOR] [df.BG]|0x80;
            idx += 3;
        }
        buf[idx] = ' ';
        idx += 1;

        if (pd1.*.Attrib.CHECKED) {
                // ---- paint the toggle checkmark ----
                // #define CHECKMARK      (unsigned char) (SCREENHEIGHT==25?251:4)
                const checkmark:u8 = if (df.SCREENHEIGHT == 25) 251 else 4;
                buf[idx-1] = checkmark;
        }

        var len=CopyCommand(buf[idx..], pd1.*.SelectionTitle.?,
                 pd1.*.Attrib.INACTIVE,
                 win.WindowColors [df.STD_COLOR] [df.BG]);
        idx += len;

        if (pd1.*.Accelerator>0) {
            // ---- paint accelerator key ----
            const str_len:usize = @intCast(pd1.*.SelectionTitle.?.len);
            const wd1:usize = 2+sel_wd-str_len;
            const key = pd1.*.Accelerator;
            if (key > 0 and key < 27) {
                // --- CTRL+ key ---
                for(0..wd1) |_| {
                    buf[idx] = ' ';
                    idx += 1;
                }
                len = @intCast(df.sprintf(&buf[idx], "[Ctrl+%c]", key-1+'A'));
                idx += @intCast(len);
            } else {
                var i:usize = 0;
                while(true) {
                    const ky = df.keys[i];
                    if (ky.keylabel == null)
                        break;
                    if (ky.keycode == key) {
                        for(0..wd1) |_| {
                            buf[idx] = ' ';
                            idx += 1;
                        }
                        len = @intCast(df.sprintf(&buf[idx], "[%s]", ky.keylabel));
                        idx += @intCast(len);
                        break;
                    }
                    i += 1;
                }
            }
        }
        if (pd1.*.Attrib.CASCADED) {
            // ---- paint cascaded menu token ----
            if (pd1.*.Accelerator == 0) {
                const wd:usize = m_wd-len+1;
                for(0..wd) |_| {
                    buf[idx] = ' ';
                    idx += 1;
                }
            }
            buf[idx-1] = df.CASCADEPOINTER;
        } else {
            buf[idx] = ' ';
            idx += 1;
        }
        buf[idx] = ' ';
        buf[idx+1] = df.RESETCOLOR;
        buf[idx+2] = 0;
    }
}

// --------- PAINT Message --------
fn PaintMsg(win:*Window) void {
    if (win.mnu) |mnu| {
//        var sep = [_]u8{df.LINE}**df.MAXPOPWIDTH; // cannot be slice
        // need to use df.LINE to differentiate from sel. 
        // otherwise, zig make them the same.
        var sep:[]u8 = @constCast(&[_]u8{df.LINE}**df.MAXPOPWIDTH);
        const sel:[]u8 = @constCast(&[_]u8{0}**df.MAXPOPWIDTH);
        const selections:[]menus.PopDown = &mnu.*.Selections;

        @memset(sep, df.LINE);
        const wd:usize = @intCast(MenuWidth(@constCast(&selections))-2);
        sep[wd] = 0; // minimal of width and maxwidth ?

        _ = win.sendMessage(df.CLEARTEXT, q.none);
        win.selection = mnu.*.Selection;
        for (mnu.*.Selections) |m| {
            if (m.SelectionTitle) |title| {
                if (title[0] == df.LINE) {
                    _ = win.sendTextMessage(df.ADDTEXT, sep);
                } else {
                    PaintPopDownSelection(win, @constCast(&m), sel);
                    _ = win.sendTextMessage(df.ADDTEXT, sel);
                }
            }
        }
    }
}

fn BorderMsg(win:*Window) bool {
    const wnd = win.win;
    var rtn = true;
    if (win.mnu) |_| {
        const currFocus = Window.inFocus;
        Window.inFocus = null;
        rtn = root.BaseWndProc(k.POPDOWNMENU, win, df.BORDER, .{.paint=.{null, false}});
        Window.inFocus = currFocus;
        for (0..@intCast(win.ClientHeight())) |i| {
            const pos = win.textLine(i);
            const chr = wnd.*.text[pos]; 
//            if (df.TextLine(wnd, i)[0] == df.LINE) {
            if (chr == df.LINE) {
                df.wputch(wnd, df.LEDGE, 0, @intCast(i+1));
                df.wputch(wnd, df.REDGE, @intCast(win.WindowWidth()-1), @intCast(i+1));
            }
        }
    }
    return rtn;
}

// -------------- LB_CHOOSE Message --------------
fn LBChooseMsg(win:*Window, p1:df.PARAM) void {
    if (win.mnu) |mnu| {
        const popdown = &mnu.*.Selections[@intCast(p1)];
        mnu.*.Selection = @intCast(p1);
        if (popdown.*.Attrib.INACTIVE == false) {
            if (popdown.*.Attrib.TOGGLE) {
                popdown.*.Attrib.CHECKED = !popdown.*.Attrib.CHECKED;
            }
            if (win.parent) |pw| {
                CurrentMenuSelection = @intCast(p1);
                q.PostMessage(pw, df.COMMAND, .{.legacy=.{@intFromEnum(popdown.*.ActionId), 0}}); // p2 was p1
            }
        } else {
            df.beep();
        }
    }
}

// ---------- KEYBOARD Message ---------
fn KeyboardMsg(win:*Window,p1:u16, p2:u8) bool {
    if (win.mnu) |mnu| {
        var c:c_uint = @intCast(p1);
        if (c < 128) { // FIXME unicode
            c = std.ascii.toLower(@intCast(c));
        }
        const a = df.AltConvert(c);
        for(mnu.*.Selections, 0..) |popdown, sel| {
            if (popdown.SelectionTitle) |title| {
                if (std.mem.indexOfScalar(u8, title, df.SHORTCUTCHAR)) |idx| {
                    var sc:u8 = title[idx+1];
                    if (sc < 256) {
                        sc = std.ascii.toLower(sc);
                    }
                    if ((sc == c) or ((a > 0) and (sc == a)) or
                           (popdown.Accelerator == c)) {
                        q.PostMessage(win, df.LB_SELECTION, .{.legacy=.{@intCast(sel), 0}});
                        q.PostMessage(win, df.LB_CHOOSE, .{.legacy=.{@intCast(sel), df.TRUE}});
                        return true;
                    }
                }
            }
        }
    }
    switch (p1) {
        df.F1 => {
            // if (ActivePopDown == NULL)
            if (win.mnu) |mnu| {
                if (mnu.*.Selections[0].SelectionTitle != null) {
                    if (mnu.*.Selections[@intCast(win.selection)].help) |helpName| {
                        _ = helpbox.DisplayHelp(win, helpName);
                        return true;
                    }
                }
            }
            _ = win.getParent().sendMessage(df.KEYBOARD, .{.char=.{p1, p2}});
 
//            if (win.mnu.*.Selections[0].SelectionTitle == null) {
//                _ = win.getParent().sendMessage(df.KEYBOARD, p1, p2);
//            } else {
//                const helpName = std.mem.span(win.mnu.*.Selections[@intCast(wnd.*.selection)].help);
//                _ = helpbox.DisplayHelp(win, helpName);
//            }
            return true;
        },
        df.ESC => {
            _ = win.sendMessage(df.CLOSE_WINDOW, .{.yes=false});
            return true;
        },
        df.FWD,
        df.BS => {
            if (win.parent) |pw| {
                if (pw.Class == k.MENUBAR) {
                    q.PostMessage(pw, df.KEYBOARD, .{.char=.{p1, p2}});
                }
            }
//            if (win.getParent().getClass() == k.MENUBAR) {
//                q.PostMessage(win.getParent().win, df.KEYBOARD, p1, p2);
//            }
            return true;
        },
        df.UP => {
            if (win.selection == 0) {
                if (win.wlines == win.ClientHeight()) {
                    q.PostMessage(win, df.LB_SELECTION,
                                    .{.legacy=.{@intCast(win.wlines-1), df.FALSE}});
                    return true;
                }
            }
        },
        df.DN => {
            if (win.selection == win.wlines-1) {
                if (win.wlines == win.ClientHeight()) {
                    q.PostMessage(win, df.LB_SELECTION, .{.legacy=.{0, df.FALSE}});
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
fn CloseWindowMsg(win:*Window) bool {
    _ = win.sendMessage(df.RELEASE_MOUSE, .{.capture=.{false, null}});
    _ = win.sendMessage(df.RELEASE_KEYBOARD, .{.capture=.{false, null}});
    _ = q.SendMessage(null, df.RESTORE_CURSOR, q.none);
    Window.inFocus = win.oldFocus;

    const rtn = root.BaseWndProc(k.POPDOWNMENU, win, df.CLOSE_WINDOW, .{.yes=false});
    _ = win.getParent().sendMessage(df.CLOSE_POPDOWN, q.none);
    return rtn;
}

// - Window processing module for POPDOWNMENU window class -
pub fn PopDownProc(win: *Window, msg: df.MESSAGE, params:q.Params) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win);
        },
        df.LEFT_BUTTON => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            LeftButtonMsg(win, p1, p2);
            return false;
        },
        df.DOUBLE_CLICK => {
            return true;
        },
        df.LB_SELECTION => {
            const p1 = params.legacy[0];
            const sel:usize = @intCast(p1);
//            const l = df.TextLine(wnd, sel);
//            if (l[0] == df.LINE) {
            const l = win.textLine(sel);
            if (wnd.*.text[l] == df.LINE) {
                return true;
            }
            if (win.mnu) |mnu| {
                mnu.*.Selection = @intCast(p1);
            }
        },
        df.BUTTON_RELEASED => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            if (ButtonReleasedMsg(win, p1, p2))
                return true;
        },
        df.BUILD_SELECTIONS => {
            const p1 = params.legacy[0];
            const pp:usize = @intCast(p1);
            win.mnu = @ptrFromInt(pp);
            if (win.mnu) |mnu| {
                win.selection = mnu.*.Selection;
            }
        },
        df.PAINT => {
            if (win.mnu == null)
                return true;
            PaintMsg(win);
        },
        df.BORDER => {
            return BorderMsg(win);
        },
        df.LB_CHOOSE => {
            const p1 = params.legacy[0];
            LBChooseMsg(win, p1);
            return true;
        },
        df.KEYBOARD => {
            const p1 = params.char[0];
            const p2 = params.char[1];
            if (KeyboardMsg(win, p1, p2))
                return true;
        },
        df.CLOSE_WINDOW => {
            return CloseWindowMsg(win);
        },
        else => {
        }
    }
    return root.BaseWndProc(k.POPDOWNMENU, win, msg, params);
}

// --------- compute menu height --------
pub fn MenuHeight(pd:*[]menus.PopDown) usize {
    var ht:usize = 0;
    for (pd.*) |popdown| {
        if (popdown.SelectionTitle != null)
            ht += 1;
    }
    return ht+2;
}

// --------- compute menu width --------
pub fn MenuWidth(pd:*[]menus.PopDown) usize {
    var len:usize = 0;
    const wd:usize = SelectionWidth(pd);
    for (pd.*) |popdown| {
        if (popdown.SelectionTitle == null)
            break; 
        if (popdown.Accelerator>0) {
            var i:usize = 0;
            while(true) {
                const key = df.keys[i];
                if (key.keylabel == null)
                    break;
                if (key.keycode == popdown.Accelerator) {
                    len = @intCast(@max(len, 2+df.strlen(key.keylabel)));
                    break;
                }
                i += 1;
            }
        }
        if (popdown.Attrib.CASCADED) {
            len = @max(len, 2);
        }
    }
    return wd+5+len;
}

// ---- compute the maximum selection width in a menu ----
pub fn SelectionWidth(pd:*[]menus.PopDown) usize {
    var wd:usize = 0;
    for (pd.*) |popdown| {
        if (popdown.SelectionTitle) |title| {
            const len:c_int = @intCast(title.len-1);
            wd = @max(wd, len);
        }
    }
    return wd;
}

// ----- copy a menu command to a display buffer ----
pub fn CopyCommand(dest:[]u8, src:[]const u8, skipcolor:bool, bg:c_int) usize {
    var idx:usize = 0;
    var change = false;

    const pmi:usize = @intCast(@intFromEnum(k.POPDOWNMENU));
    for (src) |chr| {
        if (chr == '\n') // original code end with '\n' and dest do no have '\n'
            break;
        if (chr == df.SHORTCUTCHAR) {
            change = true;
            continue; // skip shortcut symbol
        }
        if (change and !skipcolor) {
            dest[idx]   = df.CHANGECOLOR;
            dest[idx+1] = cfg.config.clr[pmi] [df.HILITE_COLOR] [df.BG] | 0x80;
            dest[idx+2] = @intCast(bg | 0x80);
            dest[idx+3] = chr;
            dest[idx+4] = df.RESETCOLOR;
            idx += 5;
        } else {
            dest[idx] = chr;
            idx += 1;
        }
        change = false;
    }
    return @intCast(idx);
}
