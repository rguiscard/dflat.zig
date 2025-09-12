const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");

var py:c_int = -1;    // the previous y mouse coordinate

// ----- Test for extended selections in the listbox -----
fn TestExtended(win:*Window, p2:df.PARAM) void {
    // EXTENDEDSELECTIONS
    _ = win;
    _ = p2;
//    if (isMultiLine(wnd) && !wnd->AddMode &&
//            !((int) p2 & (LEFTSHIFT | RIGHTSHIFT)))    {
//        if (wnd->SelectCount > 1)    {
//            ClearAllSelections(wnd);
//            SendMessage(wnd, PAINT, 0, 0);
//        }
//    }
}

// --------- UP (Up Arrow) Key ------------
fn UpKey(win:*Window,p2:df.PARAM) void {
    const wnd = win.win;
    if (wnd.*.selection > 0)    {
        if (wnd.*.selection == wnd.*.wtop) {
            _ = root.zBaseWndProc(df.LISTBOX, win, df.KEYBOARD, df.UP, p2);
            q.PostMessage(wnd, df.LB_SELECTION, wnd.*.selection-1,
                if (df.isMultiLine(wnd)>0) p2 else df.FALSE);
        } else {
            var newsel:usize = @intCast(wnd.*.selection-1);
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
    if (wnd.*.selection < wnd.*.wlines-1) {
        if (wnd.*.selection == wnd.*.wtop+win.ClientHeight()-1) {
            _ = root.zBaseWndProc(df.LISTBOX, win, df.KEYBOARD, df.DN, p2);
            q.PostMessage(wnd, df.LB_SELECTION, wnd.*.selection+1,
                if (df.isMultiLine(wnd)>0) p2 else df.FALSE);
        } else {
            var newsel:usize = @intCast(wnd.*.selection+1);
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

// --------- Enter ('\r') Key ------------
fn EnterKey(win:*Window) void {
    const wnd = win.win;
    if (wnd.*.selection != -1) {
        _ = win.sendMessage(df.LB_SELECTION, wnd.*.selection, df.TRUE);
        _ = win.sendMessage(df.LB_CHOOSE, wnd.*.selection, 0);
    }
}

// --------- All Other Key Presses ------------
fn KeyPress(win:*Window,p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    var sel:usize = @intCast(wnd.*.selection+1);
    while (sel < wnd.*.wlines) {
        const cp = df.TextLine(wnd, sel);
        if (cp == null)
            break;
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        if (isMultiLine(wnd))
//            cp++;
//#endif

        const first = cp[0];
        if ((first < 256) and (std.ascii.toLower(first) == p1)) {
            _ = win.sendMessage(df.LB_SELECTION, @intCast(sel),
                if (df.isMultiLine(wnd)>0) p2 else df.FALSE);
            if (SelectionInWindow(win, sel) == false) {
                const x:usize = @intCast(win.ClientHeight());
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
//    const wnd = win.win;
    switch (p1) {
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        case SHIFT_F8:
//            AddModeKey(wnd);
//            return TRUE;
//#endif
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
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        case ' ':
//            SpacebarKey(wnd, p2);
//            break;
//#endif
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
//            wnd->AnchorPoint = sel;
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
    if (df.WindowMoving>0 or df.WindowSizing>0)
        return false;
    if (wnd.*.wlines>0) {
        _ = root.zBaseWndProc(df.LISTBOX, win, df.DOUBLE_CLICK, p1, p2);
        if (rect.InsideRect(@intCast(p1), @intCast(p2), rect.ClientRect(win)))
            _ = win.sendMessage(df.LB_CHOOSE, wnd.*.selection, 0);
    }
    return true;
}

// ------------ ADDTEXT Message --------------
fn AddTextMsg(win:*Window,p1:df.PARAM,p2:df.PARAM) bool {
    const wnd = win.win;
    const rtn = root.zBaseWndProc(df.LISTBOX, win, df.ADDTEXT, p1, p2);
    if (wnd.*.selection == -1)
        _ = win.sendMessage(df.LB_SETSELECTION, 0, 0);
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//    if (*(char *)p1 == LISTSELECTOR)
//        wnd->SelectCount++;
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
        df.ListCopyText(cp1, cp2);
    }
}

pub fn ListBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            _ = root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
            wnd.*.selection = -1;
            wnd.*.AnchorPoint = -1; // EXTENDEDSELECTIONS
            return true;
        },
        df.KEYBOARD => {
            if ((df.WindowMoving == 0) and (df.WindowSizing == 0)) {
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
            if (df.WindowMoving>0 or df.WindowSizing>0 or df.VSliding>0) {
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
            wnd.*.selection = -1;
            wnd.*.AnchorPoint = -1; // EXTENDEDSELECTIONS
            wnd.*.SelectCount = 0;
        },
        df.PAINT => {
            _ = root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
            if (p1 > 0) {
                const pp1:usize = @intCast(p1);
                const rc:*df.RECT = @ptrFromInt(pp1);
                df.WriteSelection(wnd, wnd.*.selection, df.TRUE, rc);
            } else {
                df.WriteSelection(wnd, wnd.*.selection, df.TRUE, null);
            }
            return true;
        },
        df.SETFOCUS => {
            _ = root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
            if (p1>0)
                df.WriteSelection(wnd, wnd.*.selection, df.TRUE, null);
            return true;
        },
        df.SCROLL,
        df.HORIZSCROLL,
        df.SCROLLPAGE,
        df.HORIZPAGE,
        df.SCROLLDOC => {
            _ = root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
            df.WriteSelection(wnd,wnd.*.selection,df.TRUE,null);
            return true;
        },
        df.LB_CHOOSE => {
            _ = win.getParent().sendMessage(df.LB_CHOOSE, p1, p2);
            return true;
        },
        df.LB_SELECTION => {
            df.ChangeSelection(wnd, @intCast(p1), @intCast(p2));
            _ = win.getParent().sendMessage(df.LB_SELECTION, wnd.*.selection, 0);
            return true;
        },
        df.LB_CURRENTSELECTION => {
            if (p1 > 0) {
                const pp:usize = @intCast(p1);
                const a:*c_int = @ptrFromInt(pp);
                a.* = wnd.*.selection;
                return if (wnd.*.selection == -1) false else true;
            }
            return false;
        },
        df.LB_SETSELECTION => {
            df.ChangeSelection(wnd, @intCast(p1), 0);
            return true;
        },
        df.CLOSE_WINDOW => {
            if ((df.isMultiLine(wnd) > 0) and (wnd.*.AddMode == df.TRUE)) {
                wnd.*.AddMode = df.FALSE;
                _ = win.getParent().sendMessage(df.ADDSTATUS, 0, 0);
            }
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
}

fn SelectionInWindow(win:*Window, sel:usize) bool {
    const wnd = win.win;
    return ((wnd.*.wlines>0) and (sel >= wnd.*.wtop) and
            (sel < wnd.*.wtop+win.ClientHeight()));
}
