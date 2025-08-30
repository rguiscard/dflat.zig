const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");

var py:c_int = -1;    // the previous y mouse coordinate

// ------- LEFT_BUTTON Message --------
fn LeftButtonMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) c_int {
    const wnd = win.win;
    var my:c_int = @intCast(p2 - win.GetTop());
    if (my >= wnd.*.wlines-wnd.*.wtop)
        my = wnd.*.wlines - wnd.*.wtop;

    if (rect.InsideRect(@intCast(p1), @intCast(p2), rect.ClientRect(win)) == false) {
        return df.FALSE;
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
    return df.TRUE;
}

// ------------- DOUBLE_CLICK Message ------------
fn DoubleClickMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) c_int {
    const wnd = win.win;
    if (df.WindowMoving>0 or df.WindowSizing>0)
        return df.FALSE;
    if (wnd.*.wlines>0) {
        _ = root.zBaseWndProc(df.LISTBOX, win, df.DOUBLE_CLICK, p1, p2);
        if (rect.InsideRect(@intCast(p1), @intCast(p2), rect.ClientRect(win)))
            _ = win.sendMessage(df.LB_CHOOSE, wnd.*.selection, 0);
    }
    return df.TRUE;
}

// ------------ ADDTEXT Message --------------
fn AddTextMsg(win:*Window,p1:df.PARAM,p2:df.PARAM) c_int {
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

pub fn ListBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            _ = root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
            wnd.*.selection = -1;
            wnd.*.AnchorPoint = -1; // EXTENDEDSELECTIONS
            return df.TRUE;
        },
//        case KEYBOARD:
//            if (WindowMoving || WindowSizing)
//                break;
//            if (KeyboardMsg(wnd, p1, p2))
//                return TRUE;
//            break;
        df.LEFT_BUTTON => {
            if (LeftButtonMsg(win, p1, p2) == df.TRUE)
                return df.TRUE;
        },
        df.DOUBLE_CLICK => {
            if (DoubleClickMsg(win, p1, p2) > 0)
                return df.TRUE;
        },
        df.BUTTON_RELEASED => {
            if (df.WindowMoving>0 or df.WindowSizing>0 or df.VSliding>0) {
            } else {
                py = -1;
                return df.TRUE;
            }
        },
        df.ADDTEXT => {
            return AddTextMsg(win, p1, p2);
        },
//        case LB_GETTEXT:
//            GetTextMsg(wnd, p1, p2);
//            return TRUE;
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
            return df.TRUE;
        },
        df.SETFOCUS => {
            _ = root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
            if (p1>0)
                df.WriteSelection(wnd, wnd.*.selection, df.TRUE, null);
            return df.TRUE;
        },
        df.SCROLL,
        df.HORIZSCROLL,
        df.SCROLLPAGE,
        df.HORIZPAGE,
        df.SCROLLDOC => {
            _ = root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
            df. WriteSelection(wnd,wnd.*.selection,df.TRUE,null);
            return df.TRUE;
        },
        df.LB_CHOOSE => {
            _ = q.SendMessage(Window.GetParent(wnd), df.LB_CHOOSE, p1, p2);
            return df.TRUE;
        },
        df.LB_SELECTION => {
            df.ChangeSelection(wnd, @intCast(p1), @intCast(p2));
            _ = q.SendMessage(Window.GetParent(wnd), df.LB_SELECTION,
                wnd.*.selection, 0);
            return df.TRUE;
        },
        df.LB_CURRENTSELECTION => {
            return wnd.*.selection;
        },
        df.LB_SETSELECTION => {
            df.ChangeSelection(wnd, @intCast(p1), 0);
            return df.TRUE;
        },
        df.CLOSE_WINDOW => {
            if ((df.isMultiLine(wnd) > 0) and (wnd.*.AddMode == df.TRUE)) {
                wnd.*.AddMode = df.FALSE;
                _ = q.SendMessage(Window.GetParent(wnd), df.ADDSTATUS, 0, 0);
            }
        },
        else => {
            return df.cListBoxProc(wnd, msg, p1, p2);
        }
    }
    return root.zBaseWndProc(df.LISTBOX, win, msg, p1, p2);
}
