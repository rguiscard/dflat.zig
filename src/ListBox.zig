const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");
const normal = @import("Normal.zig");
const textbox = @import("TextBox.zig");

var py:c_int = -1;    // the previous y mouse coordinate

// --------- SHIFT_F8 Key ------------
fn AddModeKey(win:*Window) void {
    const wnd = win.win;
    if (df.isMultiLine(wnd)>0)    {
        win.AddMode ^= true;
        // parent could be null ?
        const mode = "Add Mode";
        const p1:c_int = if (win.AddMode) @intCast(@intFromPtr(mode.ptr)) else 0;
        if (win.parent) |pw| {
            _ = pw.sendMessage(df.ADDSTATUS, p1, 0);
        } else {
            _ = df.SendMessage(null, df.ADDSTATUS, p1, 0);
        }
    }
}

// --------- UP (Up Arrow) Key ------------
fn UpKey(win:*Window,p2:df.PARAM) void {
    const wnd = win.win;
    if (win.selection > 0)    {
        if (win.selection == wnd.*.wtop) {
            _ = root.zBaseWndProc(df.LISTBOX, win, df.KEYBOARD, df.UP, p2);
            q.PostMessage(wnd, df.LB_SELECTION, win.selection-1,
                if (df.isMultiLine(wnd)>0) p2 else df.FALSE);
        } else {
            var newsel:isize = win.selection-1;
            if (wnd.*.wlines == win.ClientHeight()) {
                  var last = df.TextLine(wnd, newsel);
                  while(last[0] == df.LINE) {
                      // Not sure this is really work.
                      newsel -= 1;
                      last = df.TextLine(wnd, newsel);
                  }
//                while (*TextLine(wnd, newsel) == LINE)
//                    --newsel;
            }
            q.PostMessage(wnd, df.LB_SELECTION, @intCast(newsel),
                if (df.isMultiLine(wnd)>0) p2 else df.FALSE); // EXTENDEDSELECTIONS
        }
    }
}

// --------- DN (Down Arrow) Key ------------
fn DnKey(win:*Window, p2:df.PARAM) void {
    const wnd = win.win;
    if (win.selection < wnd.*.wlines-1) {
        if (win.selection == wnd.*.wtop+win.ClientHeight()-1) {
            _ = root.zBaseWndProc(df.LISTBOX, win, df.KEYBOARD, df.DN, p2);
            q.PostMessage(wnd, df.LB_SELECTION, win.selection+1,
                if (df.isMultiLine(wnd)>0) p2 else df.FALSE);
        } else {
            var newsel:usize = @intCast(win.selection+1);
            if (wnd.*.wlines == win.ClientHeight()) {
                  var last = df.TextLine(wnd, newsel);
                  while(last[0] == df.LINE) {
                      // Not sure this is really work.
                      newsel += 1;
                      last = df.TextLine(wnd, newsel);
                  }
//                while (*TextLine(wnd, newsel) == LINE)
//                    newsel++;
            }
            q.PostMessage(wnd, df.LB_SELECTION, @intCast(newsel),
                if (df.isMultiLine(wnd)>0) p2 else df.FALSE);  // EXTENDEDSELECTIONS
        }
    }
}

// --------- HOME and PGUP Keys ------------
fn HomePgUpKey(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    _ = root.zBaseWndProc(df.LISTBOX, win, df.KEYBOARD, p1, p2);
    q.PostMessage(wnd, df.LB_SELECTION, wnd.*.wtop,
        if (df.isMultiLine(wnd)>0) p2 else df.FALSE);  // EXTENDEDSELECTIONS
}

// --------- END and PGDN Keys ------------
fn EndPgDnKey(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    _ = root.zBaseWndProc(df.LISTBOX, win, df.KEYBOARD, p1, p2);
    var bot:c_int = @intCast(wnd.*.wtop+win.ClientHeight()-1);
    if (bot > wnd.*.wlines-1)
        bot = @intCast(wnd.*.wlines-1);
    q.PostMessage(wnd, df.LB_SELECTION, bot,
        if (df.isMultiLine(wnd)>0) p2 else df.FALSE);  // EXTENDEDSELECTIONS
}

// --------- Space Bar Key ------------ 
fn SpacebarKey(win:*Window, p2:df.PARAM) void {
    const wnd = win.win;
    if (df.isMultiLine(wnd)>0) {
        var sel:isize = -1;
        _ = win.sendMessage(df.LB_CURRENTSELECTION, @intCast(@intFromPtr(&sel)), 0);
        if (sel != -1) {
            if (win.AddMode) {
                FlipSelection(win, sel);
            }
            if (ItemSelected(win, sel)) {
                const p2n = p2 & (df.LEFTSHIFT | df.RIGHTSHIFT);
                if (p2n == 0) {
                    win.AnchorPoint = sel;
                }
                _ = ExtendSelections(win, sel, @intCast(p2));
            } else {
                win.AnchorPoint = -1;
            }
            _ = win.sendMessage(df.PAINT, 0, 0);
        }
    }
}

// --------- Enter ('\r') Key ------------
fn EnterKey(win:*Window) void {
    if (win.selection != -1) {
        _ = win.sendMessage(df.LB_SELECTION, win.selection, df.TRUE);
        _ = win.sendMessage(df.LB_CHOOSE, win.selection, 0);
    }
}

// --------- All Other Key Presses ------------
fn KeyPress(win:*Window,p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    var sel:isize = win.selection+1;
    while (sel < wnd.*.wlines) {
        var cp = df.TextLine(wnd, sel);
        if (cp == null)
            break;
        if (df.isMultiLine(wnd)>0)
            cp += 1;

        const first = cp[0];
        if ((first < 256) and (std.ascii.toLower(first) == p1)) {
            _ = win.sendMessage(df.LB_SELECTION, @intCast(sel),
                if (df.isMultiLine(wnd)>0) p2 else df.FALSE);
            if (SelectionInWindow(win, sel) == false) {
                const x:isize = win.ClientHeight();
                wnd.*.wtop = @intCast(sel-x+1);
                _ = win.sendMessage(df.PAINT, 0, 0);
            }
            break;
        }
//        if (tolower(*cp) == (int)p1)    {
//            SendMessage(wnd, LB_SELECTION, sel,
//                isMultiLine(wnd) ? p2 : FALSE);
//            if (!SelectionInWindow(wnd, sel))    {
//                wnd->wtop = sel-ClientHeight(wnd)+1;
//                SendMessage(wnd, PAINT, 0, 0);
//            }
//            break;
//        }
        sel += 1;
    }
}

// --------- KEYBOARD Message ------------
fn KeyboardMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    switch (p1) {
        df.SHIFT_F8 => {
            AddModeKey(win);
            return true;
        },
        df.UP => {
            TestExtended(win, p2);
            UpKey(win, p2);
            return true;
        },
        df.DN => {
            TestExtended(win, p2);
            DnKey(win, p2);
            return true;
        },
        df.PGUP,
        df.HOME => {
            TestExtended(win, p2);
            HomePgUpKey(win, p1, p2);
            return true;
        },
        df.PGDN,
        df.END => {
            TestExtended(win, p2);
            EndPgDnKey(win, p1, p2);
            return true;
        },
        ' ' => {
            SpacebarKey(win, p2);
        },
        '\r' => {
            EnterKey(win);
            return true;
        },
        else => {
            KeyPress(win, p1, p2);
        }
    }
    return false;
}

// ------- LEFT_BUTTON Message --------
fn LeftButtonMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    var my:c_int = @intCast(p2 - win.GetTop());
    if (my >= wnd.*.wlines-wnd.*.wtop)
        my = wnd.*.wlines - wnd.*.wtop;

    if (rect.InsideRect(@intCast(p1), @intCast(p2), rect.ClientRect(win)) == false) {
        return false;
    }
    if ((wnd.*.wlines > 0) and  (my != py)) {
        const sel:c_int = wnd.*.wtop+my-1;

//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        int sh = getshift();
//        if (!(sh & (LEFTSHIFT | RIGHTSHIFT)))    {
//            if (!(sh & CTRLKEY))
//                ClearAllSelections(wnd);
//            win.AnchorPoint = sel;
//            SendMessage(wnd, PAINT, 0, 0);
//        }
//#endif

        _ = win.sendMessage(df.LB_SELECTION, sel, df.TRUE);
        py = my;
    }
    return true;
}

// ------------- DOUBLE_CLICK Message ------------
fn DoubleClickMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    if (normal.WindowMoving or normal.WindowSizing)
        return false;
    if (wnd.*.wlines>0) {
        _ = root.zBaseWndProc(df.LISTBOX, win, df.DOUBLE_CLICK, p1, p2);
        if (rect.InsideRect(@intCast(p1), @intCast(p2), rect.ClientRect(win)))
            _ = win.sendMessage(df.LB_CHOOSE, win.selection, 0);
    }
    return true;
}

// ------------ ADDTEXT Message --------------
fn AddTextMsg(win:*Window,p1:df.PARAM,p2:df.PARAM) bool {
    const rtn = root.zBaseWndProc(df.LISTBOX, win, df.ADDTEXT, p1, p2);
    if (win.selection == -1)
        _ = win.sendMessage(df.LB_SETSELECTION, 0, 0);
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//    if (*(char *)p1 == LISTSELECTOR)
//        win.SelectCount += 1;
//#endif
    return rtn;
}

// --------- GETTEXT Message ------------
fn GetTextMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    if (p2 != -1) {
        const pp1:usize = @intCast(p1);
        const cp1:[*c]u8 = @ptrFromInt(pp1);
        const pp2:usize = @intCast(p2);
        const cp2:[*c]u8 = df.TextLine(wnd, pp2);
//        char *cp1 = (char *)p1;
//        char *cp2 = TextLine(wnd, (int)p2);
//        df.ListCopyText(cp1, cp2);
        var idx:usize = 0;
        while(cp2 != null and cp2[idx] != 0 and cp2[idx] != '\n') {
            cp1[idx] = cp2[idx];
            idx += 1;
        }
        cp1[idx] = 0;
    }
}

pub fn ListBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            _ = root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
            win.selection = -1;
            win.AnchorPoint = -1;
            return true;
        },
        df.KEYBOARD => {
            if ((normal.WindowMoving == false) and (normal.WindowSizing == false)) {
                if (KeyboardMsg(win, p1, p2))
                    return true;
            }
        },
        df.LEFT_BUTTON => {
            if (LeftButtonMsg(win, p1, p2))
                return true;
        },
        df.DOUBLE_CLICK => {
            if (DoubleClickMsg(win, p1, p2))
                return true;
        },
        df.BUTTON_RELEASED => {
            if (normal.WindowMoving or normal.WindowSizing or textbox.VSliding) {
            } else {
                py = -1;
                return true;
            }
        },
        df.ADDTEXT => {
            return AddTextMsg(win, p1, p2);
        },
        df.LB_GETTEXT => {
            GetTextMsg(win, p1, p2);
            return true;
        },
        df.CLEARTEXT => {
            win.selection = -1;
            win.AnchorPoint = -1;
            win.SelectCount = 0;
        },
        df.PAINT => {
            _ = root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
            if (p1 > 0) {
                const pp1:usize = @intCast(p1);
                const rc:*df.RECT = @ptrFromInt(pp1);
                WriteSelection(win, @intCast(win.selection), df.TRUE, rc);
            } else {
                WriteSelection(win, @intCast(win.selection), df.TRUE, null);
            }
            return true;
        },
        df.SETFOCUS => {
            _ = root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
            if (p1>0)
                WriteSelection(win, @intCast(win.selection), df.TRUE, null);
            return true;
        },
        df.SCROLL,
        df.HORIZSCROLL,
        df.SCROLLPAGE,
        df.HORIZPAGE,
        df.SCROLLDOC => {
            _ = root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
            WriteSelection(win, @intCast(win.selection),df.TRUE,null);
            return true;
        },
        df.LB_CHOOSE => {
            _ = win.getParent().sendMessage(df.LB_CHOOSE, p1, p2);
            return true;
        },
        df.LB_SELECTION => {
            ChangeSelection(win, @intCast(p1), @intCast(p2));
            _ = win.getParent().sendMessage(df.LB_SELECTION, win.selection, 0);
            return true;
        },
        df.LB_CURRENTSELECTION => {
            if (p1 > 0) {
                const pp:usize = @intCast(p1);
                const a:*c_int = @ptrFromInt(pp);
                a.* = @intCast(win.selection);
                return if (win.selection == -1) false else true;
            }
            return false;
        },
        df.LB_SETSELECTION => {
            ChangeSelection(win, @intCast(p1), 0);
            return true;
        },
        df.CLOSE_WINDOW => {
            if ((df.isMultiLine(wnd) > 0) and win.AddMode) {
                win.AddMode = false;
                _ = win.getParent().sendMessage(df.ADDSTATUS, 0, 0);
            }
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
}

fn SelectionInWindow(win:*Window, sel:isize) bool {
    const wnd = win.win;
    return ((wnd.*.wlines>0) and (sel >= wnd.*.wtop) and
            (sel < wnd.*.wtop+win.ClientHeight()));
}

fn WriteSelection(win:*Window, sel:isize, reverse:c_int, rc:?*df.RECT) void {
    const wnd = win.win;
    if (win.isVisible()) {
        if (SelectionInWindow(win, sel)) {
            df.WriteTextLine(wnd, rc, @intCast(sel), @intCast(reverse));
        }
    }
}

// ----- Test for extended selections in the listbox -----
fn TestExtended(win:*Window, p2:df.PARAM) void {
    const wnd = win.win;
    const p2n = p2 & (df.LEFTSHIFT | df.RIGHTSHIFT);
    if (df.isMultiLine(wnd)>0 and (win.AddMode == false) and p2n == 0) {
        if (win.SelectCount > 1) {
            ClearAllSelections(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
        }
    }
}

// ----- Clear selections in the listbox -----
fn ClearAllSelections(win:*Window) void {
    const wnd = win.win;
    if (df.isMultiLine(wnd)>0 and win.SelectCount > 0)    {
        for (0..@intCast(wnd.*.wlines)) |idx| {
            ClearSelection(win, @intCast(idx));
        }
//        int sel;
//        for (sel = 0; sel < wnd->wlines; sel++)
//            ClearSelection(wnd, sel);
    }
}

// ----- Invert a selection in the listbox -----
fn FlipSelection(win:*Window, sel:isize) void {
    const wnd = win.win;
    if (df.isMultiLine(wnd)>0) {
        if (ItemSelected(win, sel)) {
            ClearSelection(win, sel);
        } else {
            SetSelection(win, sel);
        }
    }
}

fn ExtendSelections(win:*Window, sel:isize, shift:usize) usize {
    if (((shift & (df.LEFTSHIFT | df.RIGHTSHIFT))>0) and
                        win.AnchorPoint >= 0) {
        const anchor:usize = @intCast(win.AnchorPoint);
        const i:usize = @intCast(@max(sel, anchor));
        const j:usize = @intCast(@min(sel, anchor));
        const rtn = i-j;

        for (j..i+1) |idx| {
            SetSelection(win, @intCast(idx));
        }
//        int i = sel;
//        int j = wnd->AnchorPoint;
//        int rtn;
//        if (j > i)
//            swap(i,j);
//        rtn = i - j;
//        while (j <= i)
//            SetSelection(wnd, j++);
        return rtn;
    }
    return 0;
}

fn SetSelection(win:*Window,sel:isize) void {
    const wnd = win.win;
    if (df.isMultiLine(wnd)>0 and (ItemSelected(win, sel) == false)) {
        const lp = df.TextLine(wnd, sel);
        lp[0] = df.LISTSELECTOR;
//        *lp = LISTSELECTOR;
        win.SelectCount += 1;
    }
}

fn ClearSelection(win:*Window,sel:isize) void {
    const wnd = win.win;
    if (df.isMultiLine(wnd)>0 and ItemSelected(win, sel)) {
        const lp = df.TextLine(wnd, sel);
        lp[0] =  ' ';
//        *lp = ' ';
        win.SelectCount -= 1;
    }
}

pub fn ItemSelected(win:*Window,sel:isize) bool {
    const wnd = win.win;
    if (sel != -1 and df.isMultiLine(wnd)>0 and sel < wnd.*.wlines) {
        const cp = df.TextLine(wnd, sel);
        return (cp[0] & 255) == df.LISTSELECTOR;
//        return (int)((*cp) & 255) == LISTSELECTOR;
    }
    return false;
}

fn ChangeSelection(win:*Window,sel:isize,shift:usize) void {
    const wnd = win.win;
    if (sel != win.selection) {
        if (sel != -1 and df.isMultiLine(wnd)>0) {
            if (win.AddMode == false) {
                ClearAllSelections(win);
            }
            const sels = ExtendSelections(win, sel, shift);
            if (sels > 1) {
                _ = win.sendMessage(df.PAINT, 0, 0);
            }
            if (sels == 0 and win.AddMode == false) {
                ClearSelection(win, win.selection);
                SetSelection(win, sel);
                win.AnchorPoint = sel;
            }
        }
        WriteSelection(win, @intCast(win.selection), df.FALSE, null);
        win.selection = sel;
        if (sel != -1)
            WriteSelection(win, sel, df.TRUE, null);
     }
}
