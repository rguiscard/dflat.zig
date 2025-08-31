const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");

var TextMarking = false;

fn EditBufLen(win:*Window) c_uint {
    const wnd = win.win;
    return if (df.isMultiLine(wnd)>0) df.EDITLEN else df.ENTRYLEN;
}

fn WndCol(win:*Window) c_int {
    const wnd = win.win;
    return wnd.*.CurrCol-wnd.*.wleft;
}

// ----------- CREATE_WINDOW Message ----------
fn CreateWindowMsg(win:*Window) c_int {
    const wnd = win.win;
    const rtn = root.zBaseWndProc(df.EDITBOX, win, df.CREATE_WINDOW, 0, 0);
    wnd.*.MaxTextLength = df.MAXTEXTLEN+1;
    wnd.*.textlen = EditBufLen(win);
    wnd.*.InsertMode = df.TRUE;
    if (df.isMultiLine(wnd)>0)
        wnd.*.WordWrapMode = df.TRUE;
    _ = win.sendMessage(df.CLEARTEXT, 0, 0);
    return rtn;
}

// ----------- ADDTEXT Message ----------
fn AddTextMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) c_int {
    const wnd = win.win;
    var rtn = df.FALSE;
    const pp1:usize = @intCast(p1);
    const ptext:[*c]u8 = @ptrFromInt(pp1);
    if (df.strlen(ptext)+wnd.*.textlen <= wnd.*.MaxTextLength) {
        rtn = root.zBaseWndProc(df.EDITBOX, win, df.ADDTEXT, p1, p2);
        if (rtn == df.TRUE)    {
            if (df.isMultiLine(wnd) == 0)    {
                wnd.*.CurrLine = 0;
                wnd.*.CurrCol = @intCast(df.strlen(p1));
                if (wnd.*.CurrCol >= win.ClientWidth()) {
                    wnd.*.wleft = @intCast(wnd.*.CurrCol-win.ClientWidth());
                    wnd.*.CurrCol -= wnd.*.wleft;
                }
                wnd.*.BlkEndCol = wnd.*.CurrCol;
                _ = win.sendMessage(df.KEYBOARD_CURSOR,
                                     @intCast(WndCol(win)), wnd.*.WndRow); // WndCol
            }
        }
    }
    return rtn;
}

// ----------- SETTEXT Message ----------
fn SetTextMsg(win:*Window,p1:df.PARAM) c_int {
    const wnd = win.win;
    var rtn = df.FALSE;
    const pp1:usize = @intCast(p1);
    const ptext:[*c]u8 = @ptrFromInt(pp1);
    if (df.strlen(ptext) <= wnd.*.MaxTextLength) {
        rtn = root.zBaseWndProc(df.EDITBOX, win, df.SETTEXT, p1, 0);
            wnd.*.TextChanged = df.FALSE;
        }
    return rtn;
}

// ----------- CLEARTEXT Message ------------
fn ClearTextMsg(win:*Window) c_int {
    const wnd = win.win;
    const rtn = root.zBaseWndProc(df.EDITBOX, win, df.CLEARTEXT, 0, 0);
    const blen = EditBufLen(win)+2;
    wnd.*.text = @ptrCast(df.DFrealloc(wnd.*.text, blen));
    _ = df.memset(wnd.*.text, 0, blen);
    wnd.*.wlines = 0;
    wnd.*.CurrLine = 0;
    wnd.*.CurrCol = 0;
    wnd.*.WndRow = 0;
    wnd.*.wleft = 0;
    wnd.*.wtop = 0;
    wnd.*.textwidth = 0;
    wnd.*.TextChanged = df.FALSE;
    return rtn;
}

// ----------- KEYBOARD_CURSOR Message ----------
fn KeyboardCursorMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    wnd.*.CurrCol = @intCast(p1 + wnd.*.wleft);
    wnd.*.WndRow = @intCast(p2);
    wnd.*.CurrLine = @intCast(p2 + wnd.*.wtop);
    if (wnd == df.inFocus) {
        if (df.CharInView(wnd, @intCast(p1), @intCast(p2))>0)
            _ = q.SendMessage(null, df.SHOW_CURSOR,
                      if ((wnd.*.InsertMode>0) and (TextMarking == false)) df.TRUE else df.FALSE,
                      0);
    } else {
        _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
    }
}

// ----------- SIZE Message ----------
fn SizeMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) c_int {
    const wnd = win.win;
    const rtn = root.zBaseWndProc(df.EDITBOX, win, df.SIZE, p1, p2);
    if (WndCol(win) > win.ClientWidth()-1) {
        wnd.*.CurrCol = @intCast(win.ClientWidth()-1 + wnd.*.wleft);
    }
    if (wnd.*.WndRow > win.ClientHeight()-1) {
        wnd.*.WndRow = @intCast(win.ClientHeight()-1);
        wnd.*.CurrLine = wnd.*.WndRow+wnd.*.wtop;
    }
    _ = win.sendMessage(df.KEYBOARD_CURSOR, @intCast(WndCol(win)), @intCast(wnd.*.WndRow));
    return rtn;
}

// ----------- SCROLL Message ----------
fn ScrollMsg(win:*Window, p1:df.PARAM) c_int {
    const wnd = win.win;
    var rtn = df.FALSE;
    if (df.isMultiLine(wnd)>0) {
        rtn = root.zBaseWndProc(df.EDITBOX,win,df.SCROLL,p1,0);
        if (rtn != df.FALSE) {
            if (p1>0) {
                // -------- scrolling up ---------
                if (wnd.*.WndRow == 0)    {
                    wnd.*.CurrLine += 1;
                    df.StickEnd(wnd);
                } else {
                    wnd.*.WndRow -= 1;
                }
            } else {
                // -------- scrolling down ---------
                if (wnd.*.WndRow == win.ClientHeight()-1)    {
                    if (wnd.*.CurrLine > 0) {
                        wnd.*.CurrLine -= 1;
                    }
                    df.StickEnd(wnd);
                } else {
                    wnd.*.WndRow += 1;
                }
            }
            _ = win.sendMessage(df.KEYBOARD_CURSOR,@intCast(WndCol(win)),@intCast(wnd.*.WndRow));
        }
    }
    return rtn;
}

// ----------- HORIZSCROLL Message ----------
fn HorizScrollMsg(win:*Window, p1:df.PARAM) c_int {
    const wnd = win.win;
    var rtn = df.FALSE;
//    char *currchar = CurrChar;
    const curr_char = df.zCurrChar(wnd);
    if (((p1>0) and (wnd.*.CurrCol == wnd.*.wleft) and
               (curr_char[0] == '\n')) == false)  {
        rtn = root.zBaseWndProc(df.EDITBOX, win, df.HORIZSCROLL, p1, 0);
        if (rtn == df.TRUE) {
            if (wnd.*.CurrCol < wnd.*.wleft) {
                wnd.*.CurrCol += 1;
            } else if (WndCol(win) == win.ClientWidth()) {
                wnd.*.CurrCol -= 1;
            }
            _ = win.sendMessage(df.KEYBOARD_CURSOR,@intCast(WndCol(win)),@intCast(wnd.*.WndRow));
        }
    }
    return rtn;
}

// ----------- SCROLLPAGE Message ----------
fn ScrollPageMsg(win:*Window,p1:df.PARAM) c_int {
    const wnd = win.win;
    var rtn = df.FALSE;
    if (df.isMultiLine(wnd)>0)    {
        rtn = root.zBaseWndProc(df.EDITBOX, win, df.SCROLLPAGE, p1, 0);
//        SetLinePointer(wnd, wnd->wtop+wnd->WndRow);
        wnd.*.CurrLine = wnd.*.wtop+wnd.*.WndRow;
        df.StickEnd(wnd);
        _ = win.sendMessage(df.KEYBOARD_CURSOR,@intCast(WndCol(win)), @intCast(wnd.*.WndRow));
    }
    return rtn;
}
// ----------- HORIZSCROLLPAGE Message ----------
fn HorizPageMsg(win:*Window, p1:df.PARAM) c_int {
    const wnd = win.win;
    const rtn = root.zBaseWndProc(df.EDITBOX, win, df.HORIZPAGE, p1, 0);
    if (p1 == df.FALSE) {
        if (wnd.*.CurrCol > wnd.*.wleft+win.ClientWidth()-1)
            wnd.*.CurrCol = @intCast(wnd.*.wleft+win.ClientWidth()-1);
    } else if (wnd.*.CurrCol < wnd.*.wleft) {
        wnd.*.CurrCol = wnd.*.wleft;
    }
    _ = win.sendMessage(df.KEYBOARD_CURSOR, @intCast(WndCol(win)), @intCast(wnd.*.WndRow));
    return rtn;
}

pub fn EditBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win);
        },
        df.ADDTEXT => {
            return AddTextMsg(win, p1, p2);
        },
        df.SETTEXT => {
            return SetTextMsg(win, p1);
        },
        df.CLEARTEXT => {
            return ClearTextMsg(win);
        },
//        case GETTEXT:
//            return GetTextMsg(wnd, p1, p2);
//        case SETTEXTLENGTH:
//            return SetTextLengthMsg(wnd, (unsigned) p1);
        df.KEYBOARD_CURSOR => {
            KeyboardCursorMsg(win, p1, p2);
            return df.TRUE;
        },
        df.SETFOCUS => {
            if (p1 == 0) {
                _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
            }
            // fall through?
            const rtn = root.zBaseWndProc(df.EDITBOX, win, msg, p1, p2);
            _ = win.sendMessage(df.KEYBOARD_CURSOR, @intCast(wnd.*.CurrCol-wnd.*.wleft), wnd.*.WndRow);
            return rtn;
        },
        df.PAINT,
        df.MOVE => {
            const rtn = root.zBaseWndProc(df.EDITBOX, win, msg, p1, p2);
            _ = win.sendMessage(df.KEYBOARD_CURSOR, @intCast(wnd.*.CurrCol-wnd.*.wleft), wnd.*.WndRow);
            return rtn;
        },
        df.SIZE => {
            return SizeMsg(win, p1, p2);
        },
        df.SCROLL => {
            return ScrollMsg(win, p1);
        },
        df.HORIZSCROLL => {
            return HorizScrollMsg(win, p1);
        },
        df.SCROLLPAGE => {
            return ScrollPageMsg(win, p1);
        },
        df.HORIZPAGE => {
            return HorizPageMsg(win, p1);
        },
//        case LEFT_BUTTON:
//            if (LeftButtonMsg(wnd, p1, p2))
//                return TRUE;
//            break;
//        case MOUSE_MOVED:
//            if (MouseMovedMsg(wnd, p1, p2))
//                return TRUE;
//            break;
//        case BUTTON_RELEASED:
//            if (ButtonReleasedMsg(wnd))
//                return TRUE;
//            break;
//        case KEYBOARD:
//            if (KeyboardMsg(wnd, p1, p2))
//                return TRUE;
//            break;
//        case SHIFT_CHANGED:
//            ShiftChangedMsg(wnd, p1);
//            break;
//        case COMMAND:
//            if (CommandMsg(wnd, p1))
//                return TRUE;
//            break;
//        case CLOSE_WINDOW:
//            return CloseWindowMsg(wnd, p1, p2);
        else => {
            return df.cEditBoxProc(wnd, msg, p1, p2);
        }
    }
    return root.zBaseWndProc(df.EDITBOX, win, msg, p1, p2);
}
