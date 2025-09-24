const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");
const textbox = @import("TextBox.zig");
const search = @import("Search.zig");
const clipboard = @import("Clipboard.zig");
const normal = @import("Normal.zig");
const c = @import("Commands.zig").Command;

// -------- local variables --------
var KeyBoardMarking = false;
var ButtonDown = false;
var TextMarking = false;
var ButtonX:c_int = 0;
var ButtonY:c_int = 0;
var PrevY:c_int = -1;

fn isWhite(chr:u8) bool {
    return (chr == ' ') or (chr == '\n') or (chr == 12) or (chr == '\t'); // '\f' is 12 in ASCII
}

fn EditBufLen(win:*Window) c_uint {
    const wnd = win.win;
    return if (df.isMultiLine(wnd)>0) df.EDITLEN else df.ENTRYLEN;
}

pub fn WndCol(win:*Window) c_int {
    const wnd = win.win;
    return wnd.*.CurrCol-wnd.*.wleft;
}

// ----------- CREATE_WINDOW Message ----------
fn CreateWindowMsg(win:*Window) bool {
    const wnd = win.win;
    const rtn = root.zBaseWndProc(df.EDITBOX, win, df.CREATE_WINDOW, 0, 0);
    wnd.*.MaxTextLength = df.MAXTEXTLEN+1;
    wnd.*.textlen = EditBufLen(win);
//    win.textlen = EditBufLen(win);
    wnd.*.InsertMode = df.TRUE;
    if (df.isMultiLine(wnd)>0)
        wnd.*.WordWrapMode = df.TRUE;
    _ = win.sendMessage(df.CLEARTEXT, 0, 0);
    return rtn;
}

// ----------- ADDTEXT Message ----------
fn AddTextMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    var rtn = false;
    const pp1:usize = @intCast(p1);
    const ptext:[*c]u8 = @ptrFromInt(pp1);

//    if (df.strlen(ptext)+wnd.*.textlen <= wnd.*.MaxTextLength) {
    const len = if (win.gapbuf) |buf| buf.len() else 0;
    if (df.strlen(ptext)+len <= wnd.*.MaxTextLength) {
        rtn = root.zBaseWndProc(df.EDITBOX, win, df.ADDTEXT, p1, p2);
        if (rtn) {
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
fn SetTextMsg(win:*Window,p1:df.PARAM) bool {
    const wnd = win.win;
    var rtn = false;
    const pp1:usize = @intCast(p1);
    const ptext:[*c]u8 = @ptrFromInt(pp1);
    if (df.strlen(ptext) <= wnd.*.MaxTextLength) {
        rtn = root.zBaseWndProc(df.EDITBOX, win, df.SETTEXT, p1, 0);
        win.TextChanged = false;
    }
    return rtn;
}

// ----------- CLEARTEXT Message ------------
fn ClearTextMsg(win:*Window) bool {
    const wnd = win.win;
    const rtn = root.zBaseWndProc(df.EDITBOX, win, df.CLEARTEXT, 0, 0);
//    const blen = EditBufLen(win)+2;

//    if (win.text) |buf| {
//        @memset(buf, 0);
//        wnd.*.text = buf.ptr;
//    }
//    wnd.*.text = @ptrCast(df.DFrealloc(wnd.*.text, blen));
//    _ = df.memset(wnd.*.text, 0, blen);
    wnd.*.wlines = 0;
    wnd.*.CurrLine = 0;
    wnd.*.CurrCol = 0;
    wnd.*.WndRow = 0;
    wnd.*.wleft = 0;
    wnd.*.wtop = 0;
    wnd.*.textwidth = 0;
    win.TextChanged = false;
    return rtn;
}

// ----------- GETTEXT Message ---------- 
fn GetTextMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    const pp:usize = @intCast(p1);
    const dst:[*c]u8 = @ptrFromInt(pp);
    var len:usize = @intCast(p2);
    if (wnd.*.text) |text| {
        if (std.mem.indexOfScalar(u8, text[0..wnd.*.textlen], '\n')) |pos| {
            // pos is usize, overflow if minus 1.
            len = if (pos > 0) @min(len, pos-1) else 0; 
        } else {
            len = @min(len, wnd.*.textlen-1); // null at the end
        }
        @memmove(dst, text[0..len]);
        dst[len] = 0;
//        while (p2-- && *cp2 && *cp2 != '\n')
//            *cp1++ = *cp2++;
//        *cp1 = '\0';
        return true;
    }
    return false;
}

// ----------- SETTEXTLENGTH Message ----------
fn SetTextLengthMsg(win:*Window, p1:df.PARAM) bool {
    const wnd = win.win;
    var len:c_int = @intCast(p1);
    len += 1;
    if (len < df.MAXTEXTLEN) {
        wnd.*.MaxTextLength = @intCast(len);
        if (win.gapbuf) |buf| {
            if (len < buf.len()) {
                // this is for trancate
                buf.trancate(@intCast(len));
                if (buf.insert('\n')) { } else |_| { } // 0 or \n ?
                if (buf.insert(0)) { } else |_| { }
                wnd.*.text = @constCast(buf.toString().ptr);
                wnd.*.textlen = @intCast(buf.len());
                textbox.BuildTextPointers(win);
            }
        }
//            wnd->text=DFrealloc(wnd->text, len+2);
//            wnd->textlen = len;
//            *((wnd->text)+len) = '\0';
//            *((wnd->text)+len+1) = '\0';
//            BuildTextPointers(wnd);
//        }
        return true;
    }
    return false;
}

// ----------- KEYBOARD_CURSOR Message ----------
fn KeyboardCursorMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    wnd.*.CurrCol = @intCast(p1 + wnd.*.wleft);
    wnd.*.WndRow = @intCast(p2);
    wnd.*.CurrLine = @intCast(p2 + wnd.*.wtop);
    if (win == Window.inFocus) {
        if (df.CharInView(wnd, @intCast(p1), @intCast(p2))>0)
            _ = q.SendMessage(null, df.SHOW_CURSOR,
                      if ((wnd.*.InsertMode>0) and (TextMarking == false)) df.TRUE else df.FALSE,
                      0);
    } else {
        _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
    }
}

// ----------- SIZE Message ----------
fn SizeMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) bool {
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
fn ScrollMsg(win:*Window, p1:df.PARAM) bool {
    const wnd = win.win;
    var rtn = false;
    if (df.isMultiLine(wnd)>0) {
        rtn = root.zBaseWndProc(df.EDITBOX,win,df.SCROLL,p1,0);
        if (rtn) {
            if (p1>0) {
                // -------- scrolling up ---------
                if (wnd.*.WndRow == 0)    {
                    wnd.*.CurrLine += 1;
                    StickEnd(win);
                } else {
                    wnd.*.WndRow -= 1;
                }
            } else {
                // -------- scrolling down ---------
                if (wnd.*.WndRow == win.ClientHeight()-1)    {
                    if (wnd.*.CurrLine > 0) {
                        wnd.*.CurrLine -= 1;
                    }
                    StickEnd(win);
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
fn HorizScrollMsg(win:*Window, p1:df.PARAM) bool {
    const wnd = win.win;
    var rtn = false;
//    char *currchar = CurrChar;
    const curr_char = df.zCurrChar(wnd);
    if (((p1>0) and (wnd.*.CurrCol == wnd.*.wleft) and
               (curr_char[0] == '\n')) == false)  {
        rtn = root.zBaseWndProc(df.EDITBOX, win, df.HORIZSCROLL, p1, 0);
        if (rtn) {
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
fn ScrollPageMsg(win:*Window,p1:df.PARAM) bool {
    const wnd = win.win;
    var rtn = false;
    if (df.isMultiLine(wnd)>0)    {
        rtn = root.zBaseWndProc(df.EDITBOX, win, df.SCROLLPAGE, p1, 0);
//        SetLinePointer(wnd, wnd->wtop+wnd->WndRow);
        wnd.*.CurrLine = wnd.*.wtop+wnd.*.WndRow;
        StickEnd(win);
        _ = win.sendMessage(df.KEYBOARD_CURSOR,@intCast(WndCol(win)), @intCast(wnd.*.WndRow));
    }
    return rtn;
}
// ----------- HORIZSCROLLPAGE Message ----------
fn HorizPageMsg(win:*Window, p1:df.PARAM) bool {
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
    if (normal.WindowMoving or normal.WindowSizing)
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
                if (win.sendMessage(msg, dir, 0)) {
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
        const pos = df.strchr(lp, '\n');
        var len:c_int = 0;
        if (pos != null) {
            len = @intCast(df.strchr(lp, '\n') - lp);
        }

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
        SetAnchor(win, @intCast(ButtonX+wnd.*.wleft), @intCast(ButtonY+wnd.*.wtop));
        TextMarking = true;
        rc = win.WindowRect();
        _ = q.SendMessage(null,df.MOUSE_TRAVEL,@intCast(@intFromPtr(&rc)), 0);
        ButtonDown = false;
    }
    if (TextMarking and !(normal.WindowMoving or normal.WindowSizing)) {
        df.ExtendBlock(wnd, MouseX, MouseY);
        return true;
    }
    return false;
}

// ----------- BUTTON_RELEASED Message ----------
fn ButtonReleasedMsg(win:*Window) bool {
    ButtonDown = false;
    if (TextMarking and !(normal.WindowMoving or normal.WindowSizing)) {
        // release the mouse ouside the edit box
        _ = q.SendMessage(null, df.MOUSE_TRAVEL, 0, 0);
        StopMarking(win);
        return true;
    }
    PrevY = -1;
    return false;
}

// --------- All displayable typed keys -------------
fn KeyTyped(win:*Window, cc:c_int) void {
    const wnd = win.win;
    if (win.getGapBuffer(1)) |buf| {
        var currchar = df.zCurrChar(wnd);
        if ((cc != '\n' and cc < ' ') or (cc & 0x1000)>0) {
            // ---- not recognized by editor ---
            return;
        }
        if (df.isMultiLine(wnd)==0 and df.TextBlockMarked(wnd)) {
            _ = win.sendMessage(df.CLEARTEXT, 0, 0);
            currchar = df.zCurrChar(wnd);
        }
        // ---- test typing at end of text ----
        const currpos = df.CurrPos(wnd);
//        if (currchar == (char *)wnd->text+wnd->MaxTextLength)    {
        if (currpos == wnd.*.MaxTextLength) {
            // ---- typing at the end of maximum buffer ----
            df.beep();
            return;
        }
        const len = buf.len();
//        if (currchar == 0) {
        if (currpos == len) {
            // --- insert a newline at end of text ---
            if (buf.insert('\n')) {} else |_| {}
            if (buf.insert(0)) {} else |_| {}
            wnd.*.text = @constCast(buf.toString().ptr);
            wnd.*.textlen = @intCast(buf.len());
//            *currchar = '\n';
//            *(currchar+1) = '\0';
            textbox.BuildTextPointers(win);
        }
        // --- displayable char or newline ---
//        if (c == '\n' or wnd.*.InsertMode or currchar == '\n') {
//            // ------ inserting the keyed character ------ */
//            if (wnd->textlen == 0 || wnd->text[wnd->textlen-1] != '\0')    {
//                /* --- the current text buffer is full --- */
//                if (wnd->textlen == wnd->MaxTextLength)    {
//                    /* --- text buffer is at maximum size --- */
//                    beep();
//                    return;
//                }
//                /* ---- increase the text buffer size ---- */
//                wnd->textlen += GROWLENGTH;
//                /* --- but not above maximum size --- */
//                if (wnd->textlen > wnd->MaxTextLength)
//                    wnd->textlen = wnd->MaxTextLength;
//                wnd->text = DFrealloc(wnd->text, wnd->textlen+2);
//                wnd->text[wnd->textlen-1] = '\0';
//                currchar = CurrChar;
//            }
//
//            memmove(currchar+1, currchar, strlen(currchar)+1);
//            ModTextPointers(win, wnd.*.CurrLine+1, 1);
//            if (df.isMultiLine(wnd) and wnd.*.wlines > 1) {
//                wnd.*.textwidth = @max(wnd.*.textwidth,
//                    buf.indexOfLine(wnd.*.CurrLine+1) - buf.indexOfLine(wnd.*.CurrLine));
//                    (int) (TextLine(wnd, wnd->CurrLine+1)-
//                    TextLine(wnd, wnd->CurrLine)));
//            } else {
//                wnd.*.textwidth = @max(wnd.*.textwidth, buf.len()+1);
//                    strlen(wnd->text));
//            }
//            df.WriteTextLine(wnd, null,
//                wnd.*.wtop+wnd.*.WndRow, df.FALSE);
//        }
        // ----- put the char in the buffer -----
        buf.moveCursor(currpos);
        if (buf.insert(@intCast(cc))) {} else |_| {}
        wnd.*.text = @constCast(buf.toString().ptr);
        wnd.*.textlen = @intCast(buf.len());
        textbox.BuildTextPointers(win);
        _ = win.sendMessage(df.PAINT, 0, 0);
        win.TextChanged = true;

        if (cc == '\n')    {
            wnd.*.wleft = 0;
            textbox.BuildTextPointers(win);
            End(win);
            Forward(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return;
        }

        // ---------- test end of window --------- 
        if (WndCol(win) == win.ClientWidth()-1) {
            if (df.isMultiLine(wnd) == 0)  {
//                if (!(currchar == (char *)wnd->text+wnd->MaxTextLength-2))
//                    SendMessage(wnd, HORIZSCROLL, TRUE, 0);
                if (!(currpos == wnd.*.MaxTextLength))
                    _ = win.sendMessage(df.HORIZSCROLL, df.TRUE, 0);
            } else {
                var cp = currchar;
                const lchr:u8 = @intCast(df.TextLine(wnd, wnd.*.CurrLine)[0]);
                while (cp != ' ' and cp != lchr)
                    cp -= 1;
                if (cp == lchr or (wnd.*.WordWrapMode == df.FALSE)) {
                    _ = win.sendMessage(df.HORIZSCROLL, df.TRUE, 0);
                } else {
//                    int dif = 0;
//                    if (c != ' ')    {
//                        dif = (int) (currchar - cp);
//                        wnd->CurrCol -= dif;
//                        SendMessage(wnd, KEYBOARD, DEL, 0);
//                        --dif;
//                    }
//                    SendMessage(wnd, KEYBOARD, '\n', 0);
//                    currchar = CurrChar;
//                    wnd->CurrCol = dif;
//                    if (c == ' ')
//                        return;
                }
            }
        }
        // ------ display the character ------
        df.SetStandardColor(wnd);
//        if (wnd.*.protect)
//            c = '*';
//        PutWindowChar(wnd, c, WndCol, wnd->WndRow);
        // ----- advance the pointers ------
        wnd.*.CurrCol += 1;
    }
}

// -------------- Del key ----------------
fn DelKey(win:*Window) void {
    const wnd = win.win;
    const curr_pos = df.CurrPos(wnd);
    const curr_char = wnd.*.text[curr_pos];
//    const repaint = (curr_char == '\n');

    if (df.TextBlockMarked(wnd))    {
        _ = win.sendCommandMessage(c.ID_DELETETEXT, 0);
        _ = win.sendMessage(df.PAINT, 0, 0);
        return;
    }
    if (df.isMultiLine(wnd)>0 and curr_char == '\n' and  wnd.*.text[curr_pos+1] == 0)
        return;
    if (win.gapbuf) |buf| {
        buf.moveCursor(curr_pos);
        buf.delete();
        wnd.*.text = @constCast(buf.toString().ptr);
        wnd.*.textlen = @intCast(buf.len());
        // always repaint for now
        textbox.BuildTextPointers(win);
        _ = win.sendMessage(df.PAINT, 0, 0);
    }

//    memmove(currchar, currchar+1, strlen(currchar+1));
//    if (repaint) {
//        BuildTextPointers(win);
//        _ = win.sendMessage(df.PAINT, 0, 0);
//    } else {
//        ModTextPointers(win, wnd->CurrLine+1, -1);
//        WriteTextLine(wnd, NULL, wnd->WndRow+wnd->wtop, FALSE);
//    }
    win.TextChanged = true;
}


// ------------ screen changing key strokes -------------
fn DoKeyStroke(win:*Window, cc:c_int, p2:df.PARAM) void {
    const wnd = win.win;
    switch (cc) {
        df.RUBOUT => {
            if (wnd.*.CurrCol > 0 or wnd.*.CurrLine > 0) {
                _ = win.sendMessage(df.KEYBOARD, df.BS, 0);
                _ = win.sendMessage(df.KEYBOARD, df.DEL, 0);
            }
        },
        df.DEL => {
            DelKey(win);
        },
        df.SHIFT_HT => {
            df.ShiftTabKey(wnd, p2);
        },
        '\t' => {
            df.TabKey(wnd, p2);
        },
        '\r' => {
            if (df.isMultiLine(wnd) == df.FALSE)    {
                _ = q.PostMessage(win.getParent().win, df.KEYBOARD, cc, p2);
            } else {
                const chr = '\n';
                // fall through
                if (df.TextBlockMarked(wnd)) {
                    _ = win.sendCommandMessage(c.ID_DELETETEXT, 0);
                    _ = win.sendMessage(df.PAINT, 0, 0);
                }
                KeyTyped(win, chr);
            }
        },
        else => {
            if (df.TextBlockMarked(wnd)) {
                _ = win.sendCommandMessage(c.ID_DELETETEXT, 0);
                _ = win.sendMessage(df.PAINT, 0, 0);
            }
            KeyTyped(win, cc);
        }
    }
}

// ----------- KEYBOARD Message ----------
fn KeyboardMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    if (normal.WindowMoving or normal.WindowSizing or ((p2 & df.ALTKEY)>0))
        return false;
    switch (p1) {
        // --- these keys get processed by lower classes ---
        df.ESC,
        df.F1,
        df.F2,
        df.F3,
        df.F4,
        df.F5,
        df.F6,
        df.F7,
        df.F8,
        df.F9,
        df.F10,
        df.INS,
        df.SHIFT_INS,
        df.SHIFT_DEL => {
            return false;
        },
        // --- these keys get processed here ---
        df.CTRL_FWD,
        df.CTRL_BS,
        df.CTRL_HOME,
        df.CTRL_END,
        df.CTRL_PGUP,
        df.CTRL_PGDN => {
        },
        else => {
            // other ctrl keys get processed by lower classes
            if ((p2 & df.CTRLKEY) > 0)
                return false;
            // --- all other keys get processed here ---
        }
    }
    DoMultiLines(win, p1, p2);
    if (DoScrolling(win, @intCast(p1), p2)) {
        if (KeyBoardMarking)
            df.ExtendBlock(wnd, WndCol(win), wnd.*.WndRow);
    } else if (win.TestAttribute(df.READONLY) == false) {
        DoKeyStroke(win, @intCast(p1), p2);
        _ = win.sendMessage(df.KEYBOARD_CURSOR, WndCol(win), wnd.*.WndRow);
    } else if (p1 == '\t') {
        q.PostMessage(win.getParent().win, df.KEYBOARD, @intCast('\t'), p2);
    } else {
        df.beep();
    }
    return true;
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
        win.TextChanged = true;
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
        textbox.BuildTextPointers(win);
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
        textbox.BuildTextPointers(win);
        _ = win.sendMessage(df.KEYBOARD_CURSOR, @intCast(WndCol(win)), @intCast(wnd.*.WndRow));
        win.TextChanged = true;

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
//        _ = df.PasteText(wnd, wnd.*.DeletedText, wnd.*.DeletedLength);
        _ = clipboard.PasteText(win, text, @intCast(text.len));
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

    // ---- forming paragraph from cursor position ---
    const fl = wnd.*.wtop + wnd.*.WndRow;
    const bl = df.TextLine(wnd, wnd.*.CurrLine);
    var bc = wnd.*.CurrCol;
    if (bc >= win.ClientWidth()) {
        bc = 0;
    }
    Home(win);

    df.cParagraphCmd(wnd);

    textbox.BuildTextPointers(win);
    // --- put cursor back at beginning ---
    wnd.*.CurrLine = df.TextLineNumber(wnd, bl);
    wnd.*.CurrCol = bc;
    if (fl < wnd.*.wtop)
        wnd.*.wtop = fl;
    wnd.*.WndRow = fl - wnd.*.wtop;

    _ = win.sendMessage(df.PAINT, 0, 0);
    _ = win.sendMessage(df.KEYBOARD_CURSOR, @intCast(WndCol(win)), @intCast(wnd.*.WndRow));
    win.TextChanged = true;
    textbox.BuildTextPointers(win);
}

// ----------- COMMAND Message ----------
fn CommandMsg(win:*Window,p1:df.PARAM) bool {
    const cmd:c = @enumFromInt(p1);
    switch (cmd) {
        .ID_SEARCH => {
            search.SearchText(win);
            return true;
        },
        .ID_REPLACE => {
            search.ReplaceText(win);
            return true;
        },
        .ID_SEARCHNEXT => {
            search.SearchNext(win);
            return true;
        },
        .ID_CUT => {
            clipboard.CopyToClipboard(win);
            _ = win.sendCommandMessage(c.ID_DELETETEXT, 0);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        .ID_COPY => {
            clipboard.CopyToClipboard(win);
            textbox.ClearTextBlock(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        .ID_PASTE => {
            _ = clipboard.PasteFromClipboard(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        .ID_DELETETEXT => {
            DeleteTextCmd(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        .ID_CLEAR => {
            ClearCmd(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        .ID_UNDO => {
            UndoCmd(win);
            _ = win.sendMessage(df.PAINT, 0, 0);
            return true;
        },
        .ID_PARAGRAPH => {
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
fn CloseWindowMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
    if (win.DeletedText) |text| {
        root.global_allocator.free(text);

        // May not necessary. Not in original code
        wnd.*.DeletedText = null;
        win.DeletedText = null;
    }

    const rtn = root.zBaseWndProc(df.EDITBOX, win, df.CLOSE_WINDOW, p1, p2);
//    if (win.text) |text| {
//        root.global_allocator.free(text);
//        win.text = null;
//        wnd.*.text = null;
//    }
    // This is free at editbox instead of textbox ?
    if (win.gapbuf) |buf| {
        buf.deinit();
        win.gapbuf = null;
        wnd.*.text = null;
    }
    return rtn;
}

pub fn EditBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
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
        df.GETTEXT => {
            return GetTextMsg(win, p1, p2);
        },
        df.SETTEXTLENGTH => {
            return SetTextLengthMsg(win, p1);
        },
        df.KEYBOARD_CURSOR => {
            KeyboardCursorMsg(win, p1, p2);
            return true;
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
                return true;
        },
        df.MOUSE_MOVED => {
            if (MouseMovedMsg(win, p1, p2))
                return true;
        },
        df.BUTTON_RELEASED => {
            if (ButtonReleasedMsg(win))
                return true;
        },
        df.KEYBOARD => {
            if (KeyboardMsg(win, p1, p2))
                return true;
        },
        df.SHIFT_CHANGED => {
            ShiftChangedMsg(win, p1);
        },
        df.COMMAND => {
            if (CommandMsg(win, p1))
                return true;
        },
        df.CLOSE_WINDOW => {
            return CloseWindowMsg(win, p1, p2);
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.EDITBOX, win, msg, p1, p2);
}

// ---- Process text block keys for multiline text box ----
fn DoMultiLines(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    if (!KeyBoardMarking)    {
        if ((p2 & (df.LEFTSHIFT | df.RIGHTSHIFT))>0) {
            switch (p1) {
                df.HOME,
                df.CTRL_HOME,
                df.CTRL_BS,
                df.PGUP,
                df.CTRL_PGUP,
                df.UP,
                df.BS,
                df.END,
                df.CTRL_END,
                df.PGDN,
                df.CTRL_PGDN,
                df.DN,
                df.FWD,
                df.CTRL_FWD => {
                    KeyBoardMarking = true;
                    TextMarking = true;
                    SetAnchor(win, wnd.*.CurrCol, wnd.*.CurrLine);
                },
                else => {
                }
            }
        }
    }
}

// ---------- page/scroll keys -----------
fn ScrollingKey(win:*Window, cc:c_int, p2:df.PARAM) bool {
    const wnd = win.win;
    switch (cc) {
        df.PGUP,
        df.PGDN => {
            if (df.isMultiLine(wnd)>0)
                _ = root.zBaseWndProc(df.EDITBOX, win, df.KEYBOARD, cc, p2);
        },
        df.CTRL_PGUP,
        df.CTRL_PGDN => {
            _ = root.zBaseWndProc(df.EDITBOX, win, df.KEYBOARD, cc, p2);
        },
        df.HOME => {
            Home(win);
        },
        df.END => {
            End(win);
        },
        df.CTRL_FWD => {
            NextWord(win);
        },
        df.CTRL_BS => {
            PrevWord(win);
        },
        df.CTRL_HOME => {
            if (df.isMultiLine(wnd)>0) {
                _ = win.sendMessage(df.SCROLLDOC, df.TRUE, 0);
                wnd.*.CurrLine = 0;
                wnd.*.WndRow = 0;
            }
            Home(win);
        },
        df.CTRL_END => {
            if (df.isMultiLine(wnd)>0 and
                wnd.*.WndRow+wnd.*.wtop+1 < wnd.*.wlines and
                wnd.*.wlines > 0) {
                _ = win.sendMessage(df.SCROLLDOC, df.FALSE, 0);
                wnd.*.CurrLine = wnd.*.wlines-1;
//                _ = df.SetLinePointer(wnd, wnd.*.wlines-1);
                wnd.*.WndRow =
                    @intCast(@min(win.ClientHeight()-1, wnd.*.wlines-1));
                Home(win);
            }
            End(win);
        },
        df.UP => {
            if (df.isMultiLine(wnd)>0)
                Upward(win);
        },
        df.DN => {
            if (df.isMultiLine(wnd)>0)
                Downward(win);
        },
        df.FWD => {
            Forward(win);
        },
        df.BS => {
            Backward(win);
        },
        else => {
            return false;
        }
    }

    return true;
}

// ---------- page/scroll keys -----------
fn DoScrolling(win:*Window,p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    const rtn = ScrollingKey(win, @intCast(p1), p2);
    if (rtn == false) {
        return false;
    }

    if (!KeyBoardMarking and df.TextBlockMarked(wnd)) {
        textbox.ClearTextBlock(win);
        _ = win.sendMessage(df.PAINT, 0, 0);
    }
    _ = win.sendMessage(df.KEYBOARD_CURSOR, WndCol(win), wnd.*.WndRow);
    return true;
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
        if (root.global_allocator.allocSentinel(u8, len, 0)) |buf| {
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

// ---- cursor right key: right one character position ----
fn Forward(win:*Window) void {
    const wnd = win.win;
    const pos = df.CurrPos(wnd);
    const cc = wnd.*.text[pos+1];
    if (cc == 0)
        return;
    if (cc == '\n') {
        Home(win);
        Downward(win);
    } else {
        wnd.*.CurrCol += 1;
        if (WndCol(win) == win.ClientWidth())
            _ = win.sendMessage(df.HORIZSCROLL, df.TRUE, 0);
    }
//    char *cc = CurrChar+1;
//    if (*cc == '\0')
//        return;
//    if (*CurrChar == '\n')    {
//        Home(wnd);
//        Downward(wnd);
//    }
//    else    {
//        wnd->CurrCol++;
//        if (WndCol == ClientWidth(wnd))
//            SendMessage(wnd, HORIZSCROLL, TRUE, 0);
//    }
}

// ----- stick the moving cursor to the end of the line ----
fn StickEnd(win:*Window) void {
    const wnd = win.win;
    const curr_pos = wnd.*.TextPointers[@intCast(wnd.*.CurrLine)];
    var len:usize = 0;
    if (std.mem.indexOfScalarPos(u8, wnd.*.text[0..wnd.*.textlen], curr_pos, '\n')) |end_pos| {
        len = end_pos-curr_pos;
    } else {
        len = wnd.*.textlen-curr_pos-1; // consider end null -1 ?
    }
    wnd.*.CurrCol = @min(len, wnd.*.CurrCol);
    if (wnd.*.wleft > wnd.*.CurrCol) {
        wnd.*.wleft = @max(0, wnd.*.CurrCol - 4);
    } else if (wnd.*.CurrCol-wnd.*.wleft >= win.ClientWidth()) {
        wnd.*.wleft = @intCast(wnd.*.CurrCol - (win.ClientWidth()-1));
    }
    _ = win.sendMessage(df.PAINT, 0, 0);
    
//    char *cp = TextLine(wnd, wnd->CurrLine);
//    char *cp1 = strchr(cp, '\n');
//    int len = cp1 ? (int) (cp1 - cp) : 0;
//    wnd->CurrCol = min(len, wnd->CurrCol);
//    if (wnd->wleft > wnd->CurrCol)    {
//        wnd->wleft = max(0, wnd->CurrCol - 4);
//        SendMessage(wnd, PAINT, 0, 0);
//    }
//    else if (wnd->CurrCol-wnd->wleft >= ClientWidth(wnd))    {
//        wnd->wleft = wnd->CurrCol - (ClientWidth(wnd)-1);
//        SendMessage(wnd, PAINT, 0, 0);
//    }

}

// --------- cursor down key: down one line ---------
fn Downward(win:*Window) void {
    const wnd = win.win;
    if (df.isMultiLine(wnd)>0 and
            wnd.*.WndRow+wnd.*.wtop+1 < wnd.*.wlines)  {
        wnd.*.CurrLine += 1;
        if (wnd.*.WndRow == win.ClientHeight()-1)
            _ = win.sendMessage(df.SCROLL, df.TRUE, 0);
        wnd.*.WndRow += 1;
        StickEnd(win);
    }
}

// -------- cursor up key: up one line ------------
fn Upward(win:*Window) void {
    const wnd = win.win;
    if (df.isMultiLine(wnd)>0 and wnd.*.CurrLine != 0) {
        wnd.*.CurrLine -= 1;
        if (wnd.*.WndRow == 0)
            _ = win.sendMessage(df.SCROLL, df.FALSE, 0);
        wnd.*.WndRow -= 1;
        StickEnd(win);
    }
}

// ---- cursor left key: left one character position ----
fn Backward(win:*Window) void {
    const wnd = win.win;
    if (wnd.*.CurrCol>0) {
        wnd.*.CurrCol -= 1;
        if (wnd.*.CurrCol < wnd.*.wleft)
            _ = win.sendMessage(df.HORIZSCROLL, df.FALSE, 0);
    } else if (df.isMultiLine(wnd)>0 and wnd.*.CurrLine != 0) {
        Upward(win);
        End(win);
    }
}

// -------- End key: to end of line -------
fn End(win:*Window) void {
    const wnd = win.win;
    const curr_pos = wnd.*.TextPointers[@intCast(wnd.*.CurrLine)];
    if (std.mem.indexOfScalarPos(u8, wnd.*.text[0..@intCast(wnd.*.textlen)], curr_pos, '\n')) |pos| {
        wnd.*.CurrCol = @intCast(pos-curr_pos);
    } else {
        wnd.*.CurrCol = @intCast(wnd.*.textlen-curr_pos-1);
    }
    if (WndCol(win) >= win.ClientWidth()) {
        wnd.*.wleft = @intCast(wnd.*.CurrCol - (win.ClientWidth()-1));
        _ = win.sendMessage(df.PAINT, 0, 0);
    }
//    while (*CurrChar && *CurrChar != '\n')
//        ++wnd->CurrCol;
//    if (WndCol >= ClientWidth(wnd))    {
//        wnd->wleft = wnd->CurrCol - (ClientWidth(wnd)-1);
//        SendMessage(wnd, PAINT, 0, 0);
//    }
}

// -------- Home key: to beginning of line -------
fn Home(win:*Window) void {
    const wnd = win.win;
    wnd.*.CurrCol = 0;
    if (wnd.*.wleft != 0) {
        wnd.*.wleft = 0;
        _ = win.sendMessage(df.PAINT, 0, 0);
    }
}

// -- Ctrl+cursor right key: to beginning of next word -- 
// not really tested. Key binding doesn't work
// modern escape does not have \f
fn NextWord(win:*Window) void {
    const wnd = win.win;
    const savetop = wnd.*.wtop;
    const saveleft = wnd.*.wleft;
    win.ClearVisible();

    var curr_pos:usize = @intCast(df.CurrPos(wnd));
    var cc:u8 = @intCast(wnd.*.text[curr_pos]&0x7f);
    while(!isWhite(cc)) {
        if (wnd.*.text[curr_pos+1] == 0)
            break;
        Forward(win);
        curr_pos = @intCast(df.CurrPos(wnd));
        cc = @intCast(wnd.*.text[curr_pos]&0x7f);
    }
    while(isWhite(cc)) {
        if (wnd.*.text[curr_pos+1] == 0)
            break;
        Forward(win);
        curr_pos = @intCast(df.CurrPos(wnd));
        cc = @intCast(wnd.*.text[curr_pos]&0x7f);
    }
//    while (!isWhite(*CurrChar)) {
//        char *cc = CurrChar+1;
//        if (*cc == '\0')
//            break;
//        Forward(wnd);
//    }
//    while (isWhite(*CurrChar))    {
//        char *cc = CurrChar+1;
//        if (*cc == '\0')
//            break;
//        Forward(wnd);
//    }
    win.SetVisible();
    _ = win.sendMessage(df.KEYBOARD_CURSOR, @intCast(WndCol(win)), @intCast(wnd.*.WndRow));
    if (wnd.*.wtop != savetop or wnd.*.wleft != saveleft)
        _ = win.sendMessage(df.PAINT, 0, 0);
}

// -- Ctrl+cursor left key: to beginning of previous word --
// not tested as NextWord()
fn PrevWord(win:*Window) void {
    const wnd = win.win;
    const savetop = wnd.*.wtop;
    const saveleft = wnd.*.wleft;
    win.ClearVisible();
    Backward(win);

    var curr_pos:usize = @intCast(df.CurrPos(wnd));
    var cc:u8 = @intCast(wnd.*.text[curr_pos]&0x7f);
    while(isWhite(cc)) {
        if ((wnd.*.CurrLine == 0) and (wnd.*.CurrCol == 0))
            break;
        Backward(win);
        curr_pos = @intCast(df.CurrPos(wnd));
        cc = @intCast(wnd.*.text[curr_pos]&0x7f);
    }
    while(wnd.*.CurrCol != 0 and !isWhite(cc)) {
        Backward(win);
        curr_pos = @intCast(df.CurrPos(wnd));
        cc = @intCast(wnd.*.text[curr_pos]&0x7f);
    }
    if (isWhite(cc)) {
        Forward(win);
    }
//    while (isWhite(*CurrChar))    {
//        if (wnd->CurrLine == 0 && wnd->CurrCol == 0)
//            break;
//        Backward(wnd);
//    }
//    while (wnd->CurrCol != 0 && !isWhite(*CurrChar))
//        Backward(wnd);
//    if (isWhite(*CurrChar))
//        Forward(wnd);
    win.SetVisible();
    if (wnd.*.wleft != saveleft) {
        if (wnd.*.CurrCol >= saveleft) {
            if (wnd.*.CurrCol - saveleft < win.ClientWidth())
                wnd.*.wleft = saveleft;
        }
    }
    _ = win.sendMessage(df.KEYBOARD_CURSOR, WndCol(win), wnd.*.WndRow);
    if (wnd.*.wtop != savetop or wnd.*.wleft != saveleft)
        _ = win.sendMessage(df.PAINT, 0, 0);
}

// ----- set anchor point for marking text block -----
fn SetAnchor(win:*Window, mx:c_int, my:c_int) void {
    const wnd = win.win;
    textbox.ClearTextBlock(win);
    // ------ set the anchor ------
    wnd.*.BlkBegLine = my;
    wnd.*.BlkEndLine = my;
    wnd.*.BlkBegCol = mx;
    wnd.*.BlkEndCol = mx;
    _ = win.sendMessage(df.PAINT, 0, 0);
}
  
// ----- modify text pointers from a specified position
//                by a specified plus or minus amount -----
// Not in use, but could be useful
fn ModTextPointers(win:*Window, lineno:usize, incr:c_int) void {
    const wnd = win.win;
    for (lineno..wnd.*.wlines) |idx| {
        wnd.*.TextPointers[idx] += incr;
    }
//    while (lineno < wnd->wlines)
//        *((wnd->TextPointers) + lineno++) += var;
}
