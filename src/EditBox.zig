const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");
const textbox = @import("TextBox.zig");

// -------- local variables --------
var KeyBoardMarking = false;
var ButtonDown = false;
var TextMarking = false;
var ButtonX:c_int = 0;
var ButtonY:c_int = 0;
var PrevY:c_int = -1;

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
    win.textlen = EditBufLen(win);
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

    if (win.text) |txt| {
        if (root.global_allocator.realloc(txt, blen)) |buf| {
            win.text = buf;
        } else |_| {
        }
    } else {
        if (root.global_allocator.alloc(u8, blen)) |buf| {
            win.text = buf;
        } else |_| {
        }
    }

    if (win.text) |buf| {
        @memset(buf, 0);
        wnd.*.text = buf.ptr;
    }
//    wnd.*.text = @ptrCast(df.DFrealloc(wnd.*.text, blen));
//    _ = df.memset(wnd.*.text, 0, blen);
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

// ----------- SETTEXTLENGTH Message ----------
fn SetTextLengthMsg(win:*Window, p1:df.PARAM) c_int {
    const wnd = win.win;
    var len:c_int = @intCast(p1);
    len += 1;
    if (len < df.MAXTEXTLEN) {
        wnd.*.MaxTextLength = @intCast(len);
        if (len < win.textlen) {
            if (win.text) |txt| {
                if (root.global_allocator.realloc(txt, @intCast(len+2))) |buf| {
                    win.text = buf;
                } else |_| {
                }
            } else {
                if (root.global_allocator.alloc(u8, @intCast(len+2))) |buf| {
                    @memset(buf, 0);
                    win.text = buf;
                } else |_| {
                }
            }
            if (win.text) |txt| {
                wnd.*.text = txt.ptr;
                wnd.*.textlen = @intCast(len); // len is less than actually allocated memory
                win.textlen = @intCast(len);
                wnd.*.text[@intCast(len)] = 0;
                wnd.*.text[@intCast(len+1)] = 0;
                df.BuildTextPointers(wnd);
            }
//            wnd->text=DFrealloc(wnd->text, len+2);
//            wnd->textlen = len;
//            *((wnd->text)+len) = '\0';
//            *((wnd->text)+len+1) = '\0';
//            BuildTextPointers(wnd);
        }
        return df.TRUE;
    }
    return df.FALSE;
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

// ----------- LEFT_BUTTON Message ---------- 
fn LeftButtonMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    var MouseX:c_int = @intCast(p1 - win.GetClientLeft());
    var MouseY:c_int = @intCast(p2 - win.GetClientTop());
    const rc = rect.ClientRect(win);
    if (KeyBoardMarking)
        return true;
    if (df.WindowMoving>0 or df.WindowSizing>0)
        return false;

    if (TextMarking) {
        if (rect.InsideRect(@intCast(p1), @intCast(p2), rc) == false) {
            var x = MouseX;
            var y = MouseY;
            var dir = df.FALSE;
            var msg:df.MESSAGE = 0;
            if (p2 == win.GetTop()) {
                y += 1;
                dir = df.FALSE;
                msg = df.SCROLL;
            } else if (p2 == win.GetBottom()) {
                y -= 1;
                dir = df.TRUE;
                msg = df.SCROLL;
            } else if (p1 == win.GetLeft()) {
                x -= 1;
                dir = df.FALSE;
                msg = df.HORIZSCROLL;
            } else if (p1 == win.GetRight()) {
                x += 1;
                dir = df.TRUE;
                msg = df.HORIZSCROLL;
            }
            if (msg != 0)   {
                if (win.sendMessage(msg, dir, 0)>0) {
                    df.ExtendBlock(wnd, x, y);
                }
                _ = win.sendMessage(df.PAINT, 0, 0);
            }
        }
        return true;
    }
    if (rect.InsideRect(@intCast(p1), @intCast(p2), rc) == false)
        return false;
    if (df.TextBlockMarked(wnd)) {
        textbox.ClearTextBlock(win);
        _ = win.sendMessage(df.PAINT, 0, 0);
    }
    if (wnd.*.wlines>0) {
        if (MouseY > wnd.*.wlines-1)
            return true;
        const sel:c_uint = @intCast(MouseY+wnd.*.wtop);
        const lp = df.TextLine(wnd, sel);
        const len:c_int = @intCast(df.strchr(lp, '\n') - lp);

        MouseX = @min(MouseX, len);
        if (MouseX < wnd.*.wleft) {
            MouseX = 0;
            _ = win.sendMessage(df.KEYBOARD, df.HOME, 0);
        }
        ButtonDown = true;
        ButtonX = MouseX;
        ButtonY = MouseY;
    } else {
        MouseX = 0;
        MouseY = 0;
    }
    wnd.*.WndRow = MouseY;
    wnd.*.CurrLine = MouseY+wnd.*.wtop;

    if (df.isMultiLine(wnd)>0 or
        ((df.TextBlockMarked(wnd) == false) and
            (MouseX+wnd.*.wleft < df.strlen(wnd.*.text)))) {
        wnd.*.CurrCol = @intCast(MouseX+wnd.*.wleft);
    }
    _ = win.sendMessage(df.KEYBOARD_CURSOR, WndCol(win), wnd.*.WndRow);
    return true;
}

// ----------- MOUSE_MOVED Message ----------
fn MouseMovedMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    const MouseX:c_int = @intCast(p1 - win.GetClientLeft());
    const MouseY:c_int = @intCast(p2 - win.GetClientTop());
    var rc = rect.ClientRect(win);
    if (rect.InsideRect(@intCast(p1), @intCast(p2), rc) == false)
        return false;
    if (MouseY > wnd.*.wlines-1)
        return false;
    if (ButtonDown) {
        df.SetAnchor(wnd, @intCast(ButtonX+wnd.*.wleft), @intCast(ButtonY+wnd.*.wtop));
        TextMarking = true;
        rc = win.WindowRect();
        _ = q.SendMessage(null,df.MOUSE_TRAVEL,@intCast(@intFromPtr(&rc)), 0);
        ButtonDown = false;
    }
    if (TextMarking and !(df.WindowMoving>0 or df.WindowSizing>0)) {
        df.ExtendBlock(wnd, MouseX, MouseY);
        return true;
    }
    return false;
}

// ----------- BUTTON_RELEASED Message ----------
fn ButtonReleasedMsg(win:*Window) bool {
    ButtonDown = false;
    if (TextMarking and !(df.WindowMoving>0 or df.WindowSizing>0)) {
        // release the mouse ouside the edit box
        _ = q.SendMessage(null, df.MOUSE_TRAVEL, 0, 0);
        StopMarking(win);
        return true;
    }
    PrevY = -1;
    return false;
}

// ----------- SHIFT_CHANGED Message ----------
fn ShiftChangedMsg(win:*Window, p1:df.PARAM) void {
    const v = p1 & (df.LEFTSHIFT | df.RIGHTSHIFT);
    if ((v == 0) and KeyBoardMarking) {
        StopMarking(win);
        KeyBoardMarking = false;
    }
}

// ----------- ID_DELETETEXT Command ----------
fn DeleteTextCmd(win:*Window) void {
    const wnd = win.win;
    if (df.TextBlockMarked(wnd)) {
        const beg_sel:c_uint = @intCast(wnd.*.BlkBegLine);
        const end_sel:c_uint = @intCast(wnd.*.BlkEndLine);
        const beg_col:c_uint = @intCast(wnd.*.BlkBegCol);
        const end_col:c_uint = @intCast(wnd.*.BlkEndCol);

        const bbl=df.TextLine(wnd,beg_sel)+beg_col;
        const bel=df.TextLine(wnd,end_sel)+end_col;
        const len:c_int = @intCast(bel - bbl);
        SaveDeletedText(win, bbl, @intCast(len));
        wnd.*.TextChanged = df.TRUE;
        _ = df.memmove(bbl, bel, df.strlen(bel));
        const bcol:usize = @intCast(wnd.*.BlkBegCol); // could we reuse beg_col?
        wnd.*.CurrLine = df.TextLineNumber(wnd, bbl-bcol);
        wnd.*.CurrCol = wnd.*.BlkBegCol;
        wnd.*.WndRow = wnd.*.BlkBegLine - wnd.*.wtop;
        if (wnd.*.WndRow < 0) {
            wnd.*.wtop = wnd.*.BlkBegLine;
            wnd.*.WndRow = 0;
        }
        _ = win.sendMessage(df.KEYBOARD_CURSOR, @intCast(WndCol(win)), @intCast(wnd.*.WndRow));
        textbox.ClearTextBlock(win);
        df.BuildTextPointers(wnd);
    }
}

// ----------- ID_CLEAR Command ----------
fn ClearCmd(win:*Window) void {
    const wnd = win.win;
    if (df.TextBlockMarked(wnd))    {
        const beg_sel:c_uint = @intCast(wnd.*.BlkBegLine);
        const end_sel:c_uint = @intCast(wnd.*.BlkEndLine);
        const beg_col:c_uint = @intCast(wnd.*.BlkBegCol);
        const end_col:c_uint = @intCast(wnd.*.BlkEndCol);

        const bbl=df.TextLine(wnd,beg_sel)+beg_col;
        const bel=df.TextLine(wnd,end_sel)+end_col;
        const len:c_int = @intCast(bel - bbl);
        SaveDeletedText(win, bbl, @intCast(len));
        wnd.*.CurrLine = df.TextLineNumber(wnd, bbl);
        wnd.*.CurrCol = wnd.*.BlkBegCol;
        wnd.*.WndRow = wnd.*.BlkBegLine - wnd.*.wtop;
        if (wnd.*.WndRow < 0) {
            wnd.*.WndRow = 0;
            wnd.*.wtop = wnd.*.BlkBegLine;
        }

//        char *bbl=TextLine(wnd,wnd->BlkBegLine)+wnd->BlkBegCol;
//        char *bel=TextLine(wnd,wnd->BlkEndLine)+wnd->BlkEndCol;
//        int len = (int) (bel - bbl);
//        SaveDeletedText(wnd, bbl, len);
//        wnd->CurrLine = TextLineNumber(wnd, bbl);
//        wnd->CurrCol = wnd->BlkBegCol;
//        wnd->WndRow = wnd->BlkBegLine - wnd->wtop;
//        if (wnd->WndRow < 0)    {
//            wnd->WndRow = 0;
//            wnd->wtop = wnd->BlkBegLine;
//        }

        // ------ change all text lines in block to \n -----
        df.TextBlockToN(bbl, bel);
//        while (bbl < bel)    {
//            char *cp = strchr(bbl, '\n');
//            if (cp > bel)
//                cp = bel;
//            strcpy(bbl, cp);
//            bel -= (int) (cp - bbl);
//            bbl++;
//        }

        textbox.ClearTextBlock(win);
        df.BuildTextPointers(wnd);
        _ = win.sendMessage(df.KEYBOARD_CURSOR, @intCast(WndCol(win)), @intCast(wnd.*.WndRow));
        wnd.*.TextChanged = df.TRUE;

//        ClearTextBlock(wnd);
//        BuildTextPointers(wnd);
//        SendMessage(wnd, KEYBOARD_CURSOR, WndCol, wnd->WndRow);
//        wnd->TextChanged = TRUE;
    }
}

// ----------- ID_UNDO Command ----------
fn UndoCmd(win:*Window) void {
    const wnd = win.win;
    if (win.DeletedText) |text| {
        _ = df.PasteText(wnd, wnd.*.DeletedText, wnd.*.DeletedLength);
        root.global_allocator.free(text);
        win.DeletedText = null;
        win.*.DeletedText = null;
        win.DeletedLength = 0;
        wnd.*.DeletedLength = 0;
        _ = win.sendMessage(df.PAINT, 0, 0);
    }
//    if (wnd->DeletedText != NULL)    {
//        PasteText(wnd, wnd->DeletedText, wnd->DeletedLength);
//        free(wnd->DeletedText);
//        wnd->DeletedText = NULL;
//        wnd->DeletedLength = 0;
//        SendMessage(wnd, PAINT, 0, 0);
//    }
}

// ----------- ID_PARAGRAPH Command ----------
fn ParagraphCmd(win:*Window) void {
    const wnd = win.win;
    textbox.ClearTextBlock(win);

    df.ParagraphCmd(wnd);

    _ = win.sendMessage(df.PAINT, 0, 0);
    _ = win.sendMessage(df.KEYBOARD_CURSOR, @intCast(WndCol(win)), @intCast(wnd.*.WndRow));
    wnd.*.TextChanged = df.TRUE;
    df.BuildTextPointers(wnd);
}

// ----------- COMMAND Message ----------
fn CommandMsg(win:*Window,p1:df.PARAM) bool {
    const wnd = win.win;
    switch (p1) {
        df.ID_SEARCH => {
            df.SearchText(wnd);
            return true;
        },
        df.ID_REPLACE => {
            df.ReplaceText(wnd);
            return true;
        },
        df.ID_SEARCHNEXT => {
            df.SearchNext(wnd);
            return true;
        },
        df.ID_CUT => {
            df.CopyToClipboard(wnd);
            _ = win.sendMessage(df.COMMAND, df.ID_DELETETEXT, 0);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        df.ID_COPY => {
            df.CopyToClipboard(wnd);
            textbox.ClearTextBlock(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        df.ID_PASTE => {
            _ = df.PasteFromClipboard(wnd);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        df.ID_DELETETEXT => {
            DeleteTextCmd(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        df.ID_CLEAR => {
            ClearCmd(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        df.ID_UNDO => {
            UndoCmd(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        df.ID_PARAGRAPH => {
            ParagraphCmd(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        else => {
        }
    }
    return false;
}

// ---------- CLOSE_WINDOW Message -----------
fn CloseWindowMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) c_int {
    const wnd = win.win;
    _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
    if (win.DeletedText) |text| {
        root.global_allocator.free(text);

        // May not necessary. Not in original code
        wnd.*.DeletedText = null;
        win.DeletedText = null;
    }

    const rtn = root.zBaseWndProc(df.EDITBOX, win, df.CLOSE_WINDOW, p1, p2);
    if (win.text) |text| {
        root.global_allocator.free(text);
        win.text = null;
        wnd.*.text = null;
    }
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
        df.SETTEXTLENGTH => {
            return SetTextLengthMsg(win, p1);
        },
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
        df.LEFT_BUTTON => {
            if (LeftButtonMsg(win, p1, p2))
                return df.TRUE;
        },
        df.MOUSE_MOVED => {
            if (MouseMovedMsg(win, p1, p2))
                return df.TRUE;
        },
        df.BUTTON_RELEASED => {
            if (ButtonReleasedMsg(win))
                return df.TRUE;
        },
//        case KEYBOARD:
//            if (KeyboardMsg(wnd, p1, p2))
//                return TRUE;
//            break;
        df.SHIFT_CHANGED => {
            ShiftChangedMsg(win, p1);
        },
        df.COMMAND => {
            if (CommandMsg(win, p1))
                return df.TRUE;
        },
        df.CLOSE_WINDOW => {
            return CloseWindowMsg(win, p1, p2);
        },
        else => {
            return df.cEditBoxProc(wnd, msg, p1, p2);
        }
    }
    return root.zBaseWndProc(df.EDITBOX, win, msg, p1, p2);
}

fn swap(a:*c_int, b:*c_int) void {
    const x = a.*;
    a.* = b.*;
    b.* = x;
}

fn StopMarking(win:*Window) void {
    const wnd = win.win;
    TextMarking = false;
    if (wnd.*.BlkBegLine > wnd.*.BlkEndLine) {
        swap(&wnd.*.BlkBegLine, &wnd.*.BlkEndLine);
        swap(&wnd.*.BlkBegCol, &wnd.*.BlkEndCol);
    }
    if ((wnd.*.BlkBegLine == wnd.*.BlkEndLine) and
            (wnd.*.BlkBegCol > wnd.*.BlkEndCol)) {
        swap(&wnd.*.BlkBegCol, &wnd.*.BlkEndCol);
    }
}

// ------ save deleted text for the Undo command ------
fn SaveDeletedText(win:*Window, bbl:[*c]u8, len:usize) void {
    const wnd = win.win;
    wnd.*.DeletedLength = @intCast(len);
    win.DeletedLength = len;

    if (win.DeletedText) |txt| {
        if (root.global_allocator.realloc(txt, len)) |buf| {
            win.DeletedText = buf;
        } else |_| {
        }
    } else {
        if (root.global_allocator.alloc(u8, len)) |buf| {
            @memset(buf, 0);
            win.DeletedText = buf;
        } else |_| {
        }
    }
    if (win.DeletedText) |buf| {
        wnd.*.DeletedText = buf.ptr;
        @memmove(buf, bbl[0..len]);
    }

//    wnd->DeletedText=DFrealloc(wnd->DeletedText,len);
//    memmove(wnd->DeletedText, bbl, len);
}
