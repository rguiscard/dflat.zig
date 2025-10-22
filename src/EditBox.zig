const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;
const k = @import("Classes.zig").CLASS;
const rect = @import("Rect.zig");
const textbox = @import("TextBox.zig");
const search = @import("Search.zig");
const clipboard = @import("Clipboard.zig");
const normal = @import("Normal.zig");
const cfg = @import("Config.zig");

// -------- local variables --------
var KeyBoardMarking = false;
var ButtonDown = false;
var TextMarking = false;
var ButtonX:usize = 0;
var ButtonY:usize = 0;
var PrevY:c_int = -1;

fn isWhite(chr:u8) bool {
    return (chr == ' ') or (chr == '\n') or (chr == 12) or (chr == '\t'); // '\f' is 12 in ASCII
}

fn EditBufLen(win:*Window) c_uint {
    return if (win.isMultiLine()) df.EDITLEN else df.ENTRYLEN;
}

pub fn WndCol(win:*Window) c_int {
    const wnd = win.win;
    return wnd.*.CurrCol-wnd.*.wleft;
}

// ----------- CREATE_WINDOW Message ----------
fn CreateWindowMsg(win:*Window) bool {
    const wnd = win.win;
    const rtn = root.BaseWndProc(k.EDITBOX, win, df.CREATE_WINDOW, q.none);
    win.MaxTextLength = df.MAXTEXTLEN+1;
    wnd.*.textlen = EditBufLen(win);
//    win.textlen = EditBufLen(win);
//    wnd.*.InsertMode = df.TRUE;
    win.InsertMode = true;
    if (win.isMultiLine())
        win.WordWrapMode = true;
    _ = win.sendMessage(df.CLEARTEXT, q.none);
    return rtn;
}

// ----------- ADDTEXT Message ----------
fn AddTextMsg(win:*Window,p1:[]const u8) bool {
    const wnd = win.win;
    var rtn = false;

//    if (df.strlen(ptext)+wnd.*.textlen <= wnd.*.MaxTextLength) {
    const len = if (win.gapbuf) |buf| buf.len() else 0;
    if (p1.len+len <= win.MaxTextLength) {
        rtn = root.BaseWndProc(k.EDITBOX, win, df.ADDTEXT, .{.slice=p1});
        if (rtn) {
            if (win.isMultiLine() == false)    {
                wnd.*.CurrLine = 0;
                wnd.*.CurrCol = @intCast(p1.len);
                if (wnd.*.CurrCol >= win.ClientWidth()) {
                    wnd.*.wleft = wnd.*.CurrCol-@as(c_int, @intCast(win.ClientWidth()));
                    wnd.*.CurrCol -= wnd.*.wleft;
                }
                win.BlkEndCol = @intCast(wnd.*.CurrCol);
                _ = win.sendMessage(df.KEYBOARD_CURSOR,
                                     .{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}}); // WndCol
            }
        }
    }
    return rtn;
}

// ----------- SETTEXT Message ----------
fn SetTextMsg(win:*Window,p1:[]const u8) bool {
    var rtn = false;
    if (p1.len <= win.MaxTextLength) {
        rtn = root.BaseWndProc(k.EDITBOX, win, df.SETTEXT, .{.slice=p1});
        win.TextChanged = false;
    }
    return rtn;
}

// ----------- CLEARTEXT Message ------------
fn ClearTextMsg(win:*Window) bool {
    const wnd = win.win;
    const rtn = root.BaseWndProc(k.EDITBOX, win, df.CLEARTEXT, q.none);
//    const blen = EditBufLen(win)+2;

//    if (win.text) |buf| {
//        @memset(buf, 0);
//        wnd.*.text = buf.ptr;
//    }
//    wnd.*.text = @ptrCast(df.DFrealloc(wnd.*.text, blen));
//    _ = df.memset(wnd.*.text, 0, blen);
    win.wlines = 0;
    wnd.*.CurrLine = 0;
    wnd.*.CurrCol = 0;
    wnd.*.WndRow = 0;
    wnd.*.wleft = 0;
    win.wtop = 0;
    wnd.*.textwidth = 0;
    win.TextChanged = false;
    return rtn;
}

// ----------- GETTEXT Message ---------- 
fn GetTextMsg(win:*Window, p1:[]u8, p2:usize) bool {
    const wnd = win.win;
//    const pp:usize = @intCast(p1);
    const dst:[]u8 = p1;
    var len:usize = p2;
    if (wnd.*.text) |text| {
        if (std.mem.indexOfScalar(u8, text[0..wnd.*.textlen], '\n')) |pos| {
            // pos is usize, overflow if minus 1.
            len = if (pos > 0) @min(len, pos-1) else 0; 
        } else {
            len = @min(len, wnd.*.textlen-1); // null at the end
        }
        @memmove(dst[0..len], text[0..len]);
        dst[len] = 0;
//        while (p2-- && *cp2 && *cp2 != '\n')
//            *cp1++ = *cp2++;
//        *cp1 = '\0';
        return true;
    }
    return false;
}

// ----------- SETTEXTLENGTH Message ----------
fn SetTextLengthMsg(win:*Window, p1:usize) bool {
    const wnd = win.win;
    var len:usize = p1;
    len += 1;
    if (len < df.MAXTEXTLEN) {
        win.MaxTextLength = @intCast(len);
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
fn KeyboardCursorMsg(win:*Window, col:usize, row:usize) void {
    const wnd = win.win;
    wnd.*.CurrCol = @as(c_int, @intCast(col)) + wnd.*.wleft;
    wnd.*.WndRow = @intCast(row);
    wnd.*.CurrLine = @intCast(row + win.wtop);
    if (win == Window.inFocus) {
        if (df.CharInView(wnd, @intCast(col), @intCast(row))>0)
            _ = q.SendMessage(null, df.SHOW_CURSOR,
                      .{.yes = if (win.InsertMode and (TextMarking == false)) true else false});
    } else {
        _ = q.SendMessage(null, df.HIDE_CURSOR, q.none);
    }
}

// ----------- SIZE Message ----------
fn SizeMsg(win:*Window, x:usize, y:usize) bool {
    const wnd = win.win;
    const rtn = root.BaseWndProc(k.EDITBOX, win, df.SIZE, .{.position=.{x, y}});
    const clientWidth: c_int = @intCast(win.ClientWidth());
    const clientHeight: c_int = @intCast(win.ClientHeight());
    if (WndCol(win) > clientWidth-1) {
        wnd.*.CurrCol = clientWidth-1 + wnd.*.wleft;
    }
    if (wnd.*.WndRow > clientHeight-1) {
        wnd.*.WndRow = clientHeight-1;
        wnd.*.CurrLine = wnd.*.WndRow+@as(c_int, @intCast(win.wtop));
    }
    _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}});
    return rtn;
}

// ----------- SCROLL Message ----------
fn ScrollMsg(win:*Window, p1:bool) bool {
    const wnd = win.win;
    var rtn = false;
    if (win.isMultiLine()) {
        rtn = root.BaseWndProc(k.EDITBOX, win, df.SCROLL, .{.yes=p1});
        if (rtn) {
            if (p1) {
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
            _ = win.sendMessage(df.KEYBOARD_CURSOR,.{.position=.{@intCast(WndCol(win)),@intCast(wnd.*.WndRow)}});
        }
    }
    return rtn;
}

// ----------- HORIZSCROLL Message ----------
fn HorizScrollMsg(win:*Window, p1:bool) bool {
    const wnd = win.win;
    var rtn = false;
//    char *currchar = CurrChar;
    const curr_char = df.zCurrChar(wnd);
    if ((p1 and (wnd.*.CurrCol == wnd.*.wleft) and
               (curr_char[0] == '\n')) == false)  {
        rtn = root.BaseWndProc(k.EDITBOX, win, df.HORIZSCROLL, .{.yes=p1});
        if (rtn) {
            if (wnd.*.CurrCol < wnd.*.wleft) {
                wnd.*.CurrCol += 1;
            } else if (WndCol(win) == win.ClientWidth()) {
                wnd.*.CurrCol -= 1;
            }
            _ = win.sendMessage(df.KEYBOARD_CURSOR,.{.position=.{@intCast(WndCol(win)),@intCast(wnd.*.WndRow)}});
        }
    }
    return rtn;
}

// ----------- SCROLLPAGE Message ----------
fn ScrollPageMsg(win:*Window,p1:bool) bool {
    const wnd = win.win;
    var rtn = false;
    if (win.isMultiLine())    {
        rtn = root.BaseWndProc(k.EDITBOX, win, df.SCROLLPAGE, .{.yes=p1});
//        SetLinePointer(wnd, wnd->wtop+wnd->WndRow);
        wnd.*.CurrLine = @as(c_int, @intCast(win.wtop))+wnd.*.WndRow;
        StickEnd(win);
        _ = win.sendMessage(df.KEYBOARD_CURSOR,.{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}});
    }
    return rtn;
}
// ----------- HORIZSCROLLPAGE Message ----------
fn HorizPageMsg(win:*Window, p1:bool) bool {
    const wnd = win.win;
    const rtn = root.BaseWndProc(k.EDITBOX, win, df.HORIZPAGE, .{.yes=p1});
    const clientWidth:c_int = @intCast(win.ClientWidth());
    if (p1 == false) {
        if (wnd.*.CurrCol > wnd.*.wleft+clientWidth-1)
            wnd.*.CurrCol = @intCast(wnd.*.wleft+clientWidth-1);
    } else if (wnd.*.CurrCol < wnd.*.wleft) {
        wnd.*.CurrCol = wnd.*.wleft;
    }
    _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}});
    return rtn;
}

// ----- Extend the marked block to the new x,y position ----
fn ExtendBlock(win:*Window, xx:usize, yy:usize) void {
    const wnd = win.win;
    var x = xx;
    var y = yy;
    var ptop:usize = @min(win.BlkBegLine, win.BlkEndLine);
    var pbot:usize = @max(win.BlkBegLine, win.BlkEndLine);
//    const lp = df.TextLine(wnd, wnd.*.wtop+y);
//    const len:c_int = @intCast(df.strchr(lp, '\n') - lp);
    const lp = win.textLine(win.wtop+y);
    var len:usize = 0;
    if (std.mem.indexOfScalarPos(u8, wnd.*.text[0..wnd.*.textlen], lp, '\n')) |pos| {
        len = @intCast(pos-lp);
    }
    x = @max(0, @min(x, len));
    y = @max(0, y);
    win.BlkEndCol = @min(len, x+@as(usize, @intCast(wnd.*.wleft)));
    win.BlkEndLine = y+win.wtop;
    const bbl:usize = @min(win.BlkBegLine, win.BlkEndLine);
    const bel:usize = @max(win.BlkBegLine, win.BlkEndLine);
    while (ptop < bbl) {
        textbox.WriteTextLine(win, null, ptop, false);
        ptop += 1;
    }
    for (bbl..bel+1) |ydx| {
        textbox.WriteTextLine(win, null, ydx, false);
    }
//    for (y = bbl; y <= bel; y++)
//        WriteTextLine(wnd, NULL, y, FALSE);
    while (pbot > bel) {
        textbox.WriteTextLine(win, null, pbot, false);
        pbot -|= 1;
    }
}

// ----------- LEFT_BUTTON Message ---------- 
fn LeftButtonMsg(win:*Window,p1:usize, p2:usize) bool {
    const wnd = win.win;
    var MouseX:usize = if (p1 > win.GetClientLeft()) p1 - win.GetClientLeft() else 0;
    var MouseY:usize = if (p2 > win.GetClientTop()) p2 - win.GetClientTop() else 0;
    const rc = rect.ClientRect(win);
    if (KeyBoardMarking)
        return true;
    if (normal.WindowMoving or normal.WindowSizing)
        return false;

    if (TextMarking) {
        if (rect.InsideRect(@intCast(p1), @intCast(p2), rc) == false) {
            var x = MouseX;
            var y = MouseY;
            var dir = false;
            var msg:df.MESSAGE = 0;
            if (p2 == win.GetTop()) {
                y +|= 1;
                dir = false;
                msg = df.SCROLL;
            } else if (p2 == win.GetBottom()) {
                y -|= 1;
                dir = true;
                msg = df.SCROLL;
            } else if (p1 == win.GetLeft()) {
                x -|= 1;
                dir = false;
                msg = df.HORIZSCROLL;
            } else if (p1 == win.GetRight()) {
                x +|= 1;
                dir = true;
                msg = df.HORIZSCROLL;
            }
            if (msg != 0)   {
                if (win.sendMessage(msg, .{.yes=dir})) {
                    ExtendBlock(win, x, y);
                }
                _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            }
        }
        return true;
    }
    if (rect.InsideRect(@intCast(p1), @intCast(p2), rc) == false)
        return false;
    if (textbox.TextBlockMarked(win)) {
        textbox.ClearTextBlock(win);
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
    }
    if (win.wlines>0) {
        if (MouseY > win.wlines-1)
            return true;
        const sel:usize = MouseY+win.wtop;
//        const lp = df.TextLine(wnd, sel);
//        const pos = df.strchr(lp, '\n');
//        var len:c_int = 0;
//        if (pos != null) {
//            len = @intCast(df.strchr(lp, '\n') - lp);
//        }
        const lp = win.textLine(sel);
        var len:usize = 0;
        if (std.mem.indexOfScalarPos(u8, wnd.*.text[0..wnd.*.textlen], lp, '\n')) |pos| {
            len = pos-lp;
        }
        MouseX = @min(MouseX, len);
        if (MouseX < wnd.*.wleft) {
            MouseX = 0;
            _ = win.sendMessage(df.KEYBOARD, .{.char=.{df.HOME, 0}});
        }
        ButtonDown = true;
        ButtonX = MouseX;
        ButtonY = MouseY;
    } else {
        MouseX = 0;
        MouseY = 0;
    }
    wnd.*.WndRow = @intCast(MouseY);
    wnd.*.CurrLine = @intCast(MouseY+win.wtop);

    if (win.isMultiLine() or
        ((textbox.TextBlockMarked(win) == false) and
            (MouseX+@as(usize, @intCast(wnd.*.wleft)) < df.strlen(wnd.*.text)))) {
        wnd.*.CurrCol = @as(c_int, @intCast(MouseX))+wnd.*.wleft;
    }
    _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}});
    return true;
}

// ----------- MOUSE_MOVED Message ----------
fn MouseMovedMsg(win:*Window, x:usize, y:usize) bool {
    const wnd = win.win;
    const MouseX = if (x > win.GetClientLeft()) x - win.GetClientLeft() else 0;
    const MouseY = if (y > win.GetClientTop()) y - win.GetClientTop() else 0;
    var rc = rect.ClientRect(win);
    if (rect.InsideRect(@intCast(x), @intCast(y), rc) == false)
        return false;
    var wlines = win.wlines;
    wlines -|= 1;
    if (MouseY > wlines)
        return false;
    if (ButtonDown) {
        SetAnchor(win, ButtonX+@as(usize, @intCast(wnd.*.wleft)), @intCast(ButtonY+win.wtop));
        TextMarking = true;
        rc = win.WindowRect();
        _ = q.SendMessage(null,df.MOUSE_TRAVEL,.{.area=rc});
        ButtonDown = false;
    }
    if (TextMarking and !(normal.WindowMoving or normal.WindowSizing)) {
        ExtendBlock(win, MouseX, MouseY);
        return true;
    }
    return false;
}

// ----------- BUTTON_RELEASED Message ----------
fn ButtonReleasedMsg(win:*Window) bool {
    ButtonDown = false;
    if (TextMarking and !(normal.WindowMoving or normal.WindowSizing)) {
        // release the mouse ouside the edit box
        _ = q.SendMessage(null, df.MOUSE_TRAVEL, .{.area=null});
        StopMarking(win);
        return true;
    }
    PrevY = -1;
    return false;
}

// --------- All displayable typed keys -------------
fn KeyTyped(win:*Window, cc:u16) void {
    const wnd = win.win;
    if (win.getGapBuffer(1)) |buf| {
        var currchar = df.zCurrChar(wnd);
        if ((cc != '\n' and cc < ' ') or (cc & 0x1000)>0) {
            // ---- not recognized by editor ---
            return;
        }
        if (win.isMultiLine()==false and textbox.TextBlockMarked(win)) {
            _ = win.sendMessage(df.CLEARTEXT, q.none);
            currchar = df.zCurrChar(wnd);
        }
        // ---- test typing at end of text ----
        const currpos = win.currPos();
//        if (currchar == (char *)wnd->text+wnd->MaxTextLength)    {
        if (currpos == win.MaxTextLength) {
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
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
        win.TextChanged = true;

        if (cc == '\n')    {
            wnd.*.wleft = 0;
            textbox.BuildTextPointers(win);
            End(win);
            Forward(win);
            _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            return;
        }

        // ---------- test end of window --------- 
        if (WndCol(win) == win.ClientWidth()-1) {
            if (win.isMultiLine() == false)  {
                if (!(currpos == win.MaxTextLength))
                    _ = win.sendMessage(df.HORIZSCROLL, .{.yes=true});
            } else {
                var cp = currchar;
                const pos = win.textLine(@intCast(wnd.*.CurrLine));
                const lchr = wnd.*.text[pos];
                while (cp != ' ' and cp != lchr)
                    cp -= 1;
                if (cp == lchr or (win.WordWrapMode == false)) {
                    _ = win.sendMessage(df.HORIZSCROLL, .{.yes=true});
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
//        win.PutWindowChar(c, df.WndCol(), wnd.*.WndRow);
        // ----- advance the pointers ------
        wnd.*.CurrCol += 1;
    }
}

// -------------- Del key ----------------
fn DelKey(win:*Window) void {
    const wnd = win.win;
    const curr_pos = win.currPos();
    const curr_char = wnd.*.text[curr_pos];
//    const repaint = (curr_char == '\n');

    if (textbox.TextBlockMarked(win))    {
        _ = win.sendCommandMessage(c.ID_DELETETEXT, 0);
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
        return;
    }
    if (win.isMultiLine() and curr_char == '\n' and  wnd.*.text[curr_pos+1] == 0)
        return;
    if (win.gapbuf) |buf| {
        buf.moveCursor(curr_pos);
        buf.delete();
        wnd.*.text = @constCast(buf.toString().ptr);
        wnd.*.textlen = @intCast(buf.len());
        // always repaint for now
        textbox.BuildTextPointers(win);
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
    }

//    memmove(currchar, currchar+1, strlen(currchar+1));
//    if (repaint) {
//        BuildTextPointers(win);
//        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
//    } else {
//        ModTextPointers(win, wnd->CurrLine+1, -1);
//        WriteTextLine(wnd, NULL, wnd->WndRow+wnd->wtop, FALSE);
//    }
    win.TextChanged = true;
}

// ------------ Tab key ------------
fn TabKey(win:*Window, p2:u8) void {
    const wnd = win.win;
    const tabs:c_int = @intCast(cfg.config.Tabs);
    if (win.isMultiLine()) {
        const insmd = win.InsertMode;
        const pos = win.currPos();
        for (pos+1..win.MaxTextLength) |idx| {
            if (insmd == false and wnd.*.text[idx] == 0)
                break;
            if (wnd.*.textlen == win.MaxTextLength)
                break;
            _ = win.sendMessage(df.KEYBOARD, .{.char=.{if (insmd) ' ' else df.FWD, 0}});
            if (@mod(wnd.*.CurrCol, tabs) == 0)
                break;
        }
    } else {
        q.PostMessage(win.parent, df.KEYBOARD, .{.char=.{'\t', p2}});
    }
}

// ------------ Shift+Tab key ------------
// not tested
fn ShiftTabKey(win:*Window, p2:u8) void {
    const wnd = win.win;
    const tabs:c_int = @intCast(cfg.config.Tabs);
    if (win.isMultiLine()) {
        while(true) {
            const pos = win.currPos();
            if (pos == 0)
                break;
            if (@mod(wnd.*.CurrCol, tabs) == 0)
                break;
        }
    } else {
        q.PostMessage(win.parent, df.KEYBOARD, .{.char=.{df.SHIFT_HT, p2}});
    }
}

// ------------ screen changing key strokes -------------
fn DoKeyStroke(win:*Window, cc:u16, p2:u8) void {
    const wnd = win.win;
    switch (cc) {
        df.RUBOUT => {
            if (wnd.*.CurrCol > 0 or wnd.*.CurrLine > 0) {
                _ = win.sendMessage(df.KEYBOARD, .{.char=.{df.BS, 0}});
                _ = win.sendMessage(df.KEYBOARD, .{.char=.{df.DEL, 0}});
            }
        },
        df.DEL => {
            DelKey(win);
        },
        df.SHIFT_HT => {
            ShiftTabKey(win, p2);
        },
        '\t' => {
            TabKey(win, p2);
        },
        '\r' => {
            if (win.isMultiLine() == false)    {
                _ = q.PostMessage(win.parent, df.KEYBOARD, .{.char=.{cc, p2}});
            } else {
                const chr = '\n';
                // fall through
                if (textbox.TextBlockMarked(win)) {
                    _ = win.sendCommandMessage(c.ID_DELETETEXT, 0);
                    _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
                }
                KeyTyped(win, chr);
            }
        },
        else => {
            if (textbox.TextBlockMarked(win)) {
                _ = win.sendCommandMessage(c.ID_DELETETEXT, 0);
                _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            }
            KeyTyped(win, cc);
        }
    }
}

// ----------- KEYBOARD Message ----------
fn KeyboardMsg(win:*Window,p1:u16, p2:u8) bool {
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
            ExtendBlock(win, @intCast(WndCol(win)), @intCast(wnd.*.WndRow));
    } else if (win.TestAttribute(df.READONLY) == false) {
        DoKeyStroke(win, @intCast(p1), p2);
        _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}});
    } else if (p1 == '\t') {
        q.PostMessage(win.parent, df.KEYBOARD, .{.char=.{'\t', p2}});
    } else {
        df.beep();
    }
    return true;
}

// ----------- SHIFT_CHANGED Message ----------
fn ShiftChangedMsg(win:*Window, p1:u16) void {
    const v = p1 & (df.LEFTSHIFT | df.RIGHTSHIFT);
    if ((v == 0) and KeyBoardMarking) {
        StopMarking(win);
        KeyBoardMarking = false;
    }
}

// ----------- ID_DELETETEXT Command ----------
fn DeleteTextCmd(win:*Window) void {
    const wnd = win.win;
    if (textbox.TextBlockMarked(win)) {
        const beg_sel = win.BlkBegLine;
        const end_sel = win.BlkEndLine;
        const beg_col = win.BlkBegCol;
        const end_col = win.BlkEndCol;

//        const bbl=df.TextLine(wnd,beg_sel)+beg_col;
//        const bel=df.TextLine(wnd,end_sel)+end_col;
//        const len:c_int = @intCast(bel - bbl);
//        SaveDeletedText(win, bbl, @intCast(len));
        // FIMXE: seems off a few characters
        const bbl=win.textLine(beg_sel)+beg_col;
        const bel=win.textLine(end_sel)+end_col;
        SaveDeletedText(win, bbl, bel);
        win.TextChanged = true;
        _ = df.memmove(&wnd.*.text[bbl], &wnd.*.text[bel], wnd.*.textlen-bel);
//        const bcol:usize = @intCast(wnd.*.BlkBegCol); // could we reuse beg_col?
//        wnd.*.CurrLine = df.TextLineNumber(wnd, bbl-bcol);
        wnd.*.CurrLine = @intCast(win.BlkBegLine);
        wnd.*.CurrCol = @intCast(win.BlkBegCol);
        const begline:usize = win.BlkBegLine;
        wnd.*.WndRow = @intCast(begline - win.wtop);
        if (wnd.*.WndRow < 0) {
            win.wtop = win.BlkBegLine;
            wnd.*.WndRow = 0;
        }
        _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}});
        textbox.ClearTextBlock(win);
        textbox.BuildTextPointers(win);
    }
}

// ----------- ID_CLEAR Command ----------
fn ClearCmd(win:*Window) void {
    const wnd = win.win;
    if (textbox.TextBlockMarked(win))    {
        const beg_sel = win.BlkBegLine;
        const end_sel = win.BlkEndLine;
        const beg_col = win.BlkBegCol;
        const end_col = win.BlkEndCol;

//        const bbl=df.TextLine(wnd,beg_sel)+beg_col;
//        const bel=df.TextLine(wnd,end_sel)+end_col;
//        const len:c_int = @intCast(bel - bbl);
//        SaveDeletedText(win, bbl, @intCast(len));
        // FIMXE: seems off a few characters
        const bbl=win.textLine(beg_sel)+beg_col;
        const bel=win.textLine(end_sel)+end_col;
        SaveDeletedText(win, bbl, bel);
//        wnd.*.CurrLine = df.TextLineNumber(wnd, bbl);
        wnd.*.CurrLine = @intCast(win.BlkBegLine);
        wnd.*.CurrCol = @intCast(win.BlkBegCol);
        const begline:usize = win.BlkBegLine;
        wnd.*.WndRow = @intCast(begline - win.wtop);
        if (wnd.*.WndRow < 0) {
            wnd.*.WndRow = 0;
            win.wtop = win.BlkBegLine;
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
        df.TextBlockToN(&wnd.*.text[bbl], &wnd.*.text[bel]);
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
        _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}});
        win.TextChanged = true;

//        ClearTextBlock(wnd);
//        BuildTextPointers(wnd);
//        SendMessage(wnd, KEYBOARD_CURSOR, WndCol, wnd->WndRow);
//        wnd->TextChanged = TRUE;
    }
}

// ----------- ID_UNDO Command ----------
fn UndoCmd(win:*Window) void {
    if (win.DeletedText) |text| {
        _ = clipboard.PasteText(win, text, @intCast(text.len));
        root.global_allocator.free(text);
        win.DeletedText = null;
        win.DeletedLength = 0;
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
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
    const fl:usize = win.wtop + @as(usize, @intCast(wnd.*.WndRow));
//    const bl = df.TextLine(wnd, wnd.*.CurrLine);
    const saved_line = wnd.*.CurrLine;
    var bc = wnd.*.CurrCol;
    if (bc >= win.ClientWidth()) {
        bc = 0;
    }
    Home(win);

    df.cParagraphCmd(wnd);

    textbox.BuildTextPointers(win);
    // --- put cursor back at beginning ---
//    wnd.*.CurrLine = df.TextLineNumber(wnd, bl);
    wnd.*.CurrLine = saved_line;
    wnd.*.CurrCol = bc;
    if (fl < win.wtop)
        win.wtop = fl;
    wnd.*.WndRow = @intCast(fl - win.wtop);

    _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
    _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}});
    win.TextChanged = true;
    textbox.BuildTextPointers(win);
}

// ----------- COMMAND Message ----------
fn CommandMsg(win:*Window,p1:c) bool {
    const cmd:c = p1;
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
            _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            return true;
        },
        .ID_COPY => {
            clipboard.CopyToClipboard(win);
            textbox.ClearTextBlock(win);
            _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            return true;
        },
        .ID_PASTE => {
            _ = clipboard.PasteFromClipboard(win);
            _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            return true;
        },
        .ID_DELETETEXT => {
            DeleteTextCmd(win);
            _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            return true;
        },
        .ID_CLEAR => {
            ClearCmd(win);
            _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            return true;
        },
        .ID_UNDO => {
            UndoCmd(win);
            _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            return true;
        },
        .ID_PARAGRAPH => {
            ParagraphCmd(win);
            _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            return true;
        },
        else => {
        }
    }
    return false;
}

// ---------- CLOSE_WINDOW Message -----------
fn CloseWindowMsg(win:*Window) bool {
    const wnd = win.win;
    _ = q.SendMessage(null, df.HIDE_CURSOR, q.none);
    if (win.DeletedText) |text| {
        root.global_allocator.free(text);

        // May not necessary. Not in original code
        win.DeletedText = null;
    }

    const rtn = root.BaseWndProc(k.EDITBOX, win, df.CLOSE_WINDOW, .{.yes=false});
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

pub fn EditBoxProc(win:*Window, msg:df.MESSAGE, params:q.Params) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win);
        },
        df.ADDTEXT => {
            return AddTextMsg(win, params.slice);
        },
        df.SETTEXT => {
            return SetTextMsg(win, params.slice);
        },
        df.CLEARTEXT => {
            return ClearTextMsg(win);
        },
        df.GETTEXT => {
            const p1:[]u8 = params.get_text[0];
            const p2:usize = params.get_text[1];
            return GetTextMsg(win, p1, p2);
        },
        df.SETTEXTLENGTH => {
            const p1:usize = params.usize;
            return SetTextLengthMsg(win, p1);
        },
        df.KEYBOARD_CURSOR => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            KeyboardCursorMsg(win, p1, p2);
            return true;
        },
        df.SETFOCUS => {
            if (params.yes == false) {
                _ = q.SendMessage(null, df.HIDE_CURSOR, q.none);
            }
            // fall through?
            const rtn = root.BaseWndProc(k.EDITBOX, win, msg, params);
            const x:usize = if (wnd.*.CurrCol > wnd.*.wleft) @intCast(wnd.*.CurrCol-wnd.*.wleft) else 0;
            const y:usize = @intCast(wnd.*.WndRow);
            _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{x, y}});
            return rtn;
        },
        df.PAINT,
        df.MOVE => {
            const rtn = root.BaseWndProc(k.EDITBOX, win, msg, params);
            const x:usize = if (wnd.*.CurrCol > wnd.*.wleft) @intCast(wnd.*.CurrCol-wnd.*.wleft) else 0;
            const y:usize = @intCast(wnd.*.WndRow);
            _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{x, y}});
            return rtn;
        },
        df.SIZE => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            return SizeMsg(win, p1, p2);
        },
        df.SCROLL => {
            return ScrollMsg(win, params.yes);
        },
        df.HORIZSCROLL => {
            return HorizScrollMsg(win, params.yes);
        },
        df.SCROLLPAGE => {
            return ScrollPageMsg(win, params.yes);
        },
        df.HORIZPAGE => {
            return HorizPageMsg(win, params.yes);
        },
        df.LEFT_BUTTON => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            if (LeftButtonMsg(win, p1, p2))
                return true;
        },
        df.MOUSE_MOVED => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            if (MouseMovedMsg(win, p1, p2))
                return true;
        },
        df.BUTTON_RELEASED => {
            if (ButtonReleasedMsg(win))
                return true;
        },
        df.KEYBOARD => {
            const p1 = params.char[0];
            const p2 = params.char[1];
            if (KeyboardMsg(win, p1, p2))
                return true;
        },
        df.SHIFT_CHANGED => {
            const p1 = params.char[0];
            ShiftChangedMsg(win, p1);
        },
        df.COMMAND => {
            const p1:c = params.command[0];
            if (CommandMsg(win, p1))
                return true;
        },
        df.CLOSE_WINDOW => {
            return CloseWindowMsg(win);
        },
        else => {
        }
    }
    return root.BaseWndProc(k.EDITBOX, win, msg, params);
}

// ---- Process text block keys for multiline text box ----
fn DoMultiLines(win:*Window, p1:u16, p2:u8) void {
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
                    SetAnchor(win, @intCast(wnd.*.CurrCol), @intCast(wnd.*.CurrLine));
                },
                else => {
                }
            }
        }
    }
}

// ---------- page/scroll keys -----------
fn ScrollingKey(win:*Window, cc:u16, p2:u8) bool {
    const wnd = win.win;
    switch (cc) {
        df.PGUP,
        df.PGDN => {
            if (win.isMultiLine())
                _ = root.BaseWndProc(k.EDITBOX, win, df.KEYBOARD, .{.char=.{cc, p2}});
        },
        df.CTRL_PGUP,
        df.CTRL_PGDN => {
            _ = root.BaseWndProc(k.EDITBOX, win, df.KEYBOARD, .{.char=.{cc, p2}});
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
            if (win.isMultiLine()) {
                _ = win.sendMessage(df.SCROLLDOC, .{.yes=true});
                wnd.*.CurrLine = 0;
                wnd.*.WndRow = 0;
            }
            Home(win);
        },
        df.CTRL_END => {
            if (win.isMultiLine() and
                @as(usize, @intCast(wnd.*.WndRow))+win.wtop+1 < win.wlines and
                win.wlines > 0) {
                _ = win.sendMessage(df.SCROLLDOC, .{.yes=false});
                wnd.*.CurrLine = @as(c_int, @intCast(win.wlines-1));
//                _ = df.SetLinePointer(wnd, win.wlines-1);
                wnd.*.WndRow =
                    @intCast(@min(win.ClientHeight()-1, win.wlines-1));
                Home(win);
            }
            End(win);
        },
        df.UP => {
            if (win.isMultiLine())
                Upward(win);
        },
        df.DN => {
            if (win.isMultiLine())
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
fn DoScrolling(win:*Window,p1:u16, p2:u8) bool {
    const wnd = win.win;
    const rtn = ScrollingKey(win, p1, p2);
    if (rtn == false) {
        return false;
    }

    if (!KeyBoardMarking and textbox.TextBlockMarked(win)) {
        textbox.ClearTextBlock(win);
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
    }
    _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}});
    return true;
}

fn swap(a:*usize, b:*usize) void {
    const x = a.*;
    a.* = b.*;
    b.* = x;
}

fn StopMarking(win:*Window) void {
    TextMarking = false;
    if (win.BlkBegLine > win.BlkEndLine) {
        swap(&win.BlkBegLine, &win.BlkEndLine);
        swap(&win.BlkBegCol, &win.BlkEndCol);
    }
    if ((win.BlkBegLine == win.BlkEndLine) and
            (win.BlkBegCol > win.BlkEndCol)) {
        swap(&win.BlkBegCol, &win.BlkEndCol);
    }
}

// ------ save deleted text for the Undo command ------
//fn SaveDeletedText(win:*Window, bbl:[*c]u8, len:usize) void {
fn SaveDeletedText(win:*Window, bbl:usize, bel:usize) void {
    const wnd = win.win;
    const len = bel-bbl;
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
//        wnd.*.DeletedText = buf.ptr;
        @memmove(buf, wnd.*.text[bbl..bel]);
    }

//    wnd->DeletedText=DFrealloc(wnd->DeletedText,len);
//    memmove(wnd->DeletedText, bbl, len);
}

// ---- cursor right key: right one character position ----
fn Forward(win:*Window) void {
    const wnd = win.win;
    const pos = win.currPos();
    const cc = wnd.*.text[pos+1];
    if (cc == 0)
        return;
    if (cc == '\n') {
        Home(win);
        Downward(win);
    } else {
        wnd.*.CurrCol += 1;
        if (WndCol(win) == win.ClientWidth())
            _ = win.sendMessage(df.HORIZSCROLL, .{.yes=true});
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
        wnd.*.wleft = wnd.*.CurrCol - @as(c_int, @intCast(win.ClientWidth()-1));
    }
    _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
    
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
    if (win.isMultiLine() and
            @as(usize, @intCast(wnd.*.WndRow))+win.wtop+1 < win.wlines)  {
        wnd.*.CurrLine += 1;
        if (wnd.*.WndRow == win.ClientHeight()-1)
            _ = win.sendMessage(df.SCROLL, .{.yes=true});
        wnd.*.WndRow += 1;
        StickEnd(win);
    }
}

// -------- cursor up key: up one line ------------
fn Upward(win:*Window) void {
    const wnd = win.win;
    if (win.isMultiLine() and wnd.*.CurrLine != 0) {
        wnd.*.CurrLine -= 1;
        if (wnd.*.WndRow == 0)
            _ = win.sendMessage(df.SCROLL, .{.yes=false});
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
            _ = win.sendMessage(df.HORIZSCROLL, .{.yes=false});
    } else if (win.isMultiLine() and wnd.*.CurrLine != 0) {
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
        wnd.*.wleft = wnd.*.CurrCol - @as(c_int, @intCast(win.ClientWidth()-1));
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
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
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
    }
}

// -- Ctrl+cursor right key: to beginning of next word -- 
// not really tested. Key binding doesn't work
// modern escape does not have \f
fn NextWord(win:*Window) void {
    const wnd = win.win;
    const savetop = win.wtop;
    const saveleft = wnd.*.wleft;
    win.ClearVisible();

    var curr_pos:usize = win.currPos();
    var cc:u8 = @intCast(wnd.*.text[curr_pos]&0x7f);
    while(!isWhite(cc)) {
        if (wnd.*.text[curr_pos+1] == 0)
            break;
        Forward(win);
        curr_pos = win.currPos();
        cc = @intCast(wnd.*.text[curr_pos]&0x7f);
    }
    while(isWhite(cc)) {
        if (wnd.*.text[curr_pos+1] == 0)
            break;
        Forward(win);
        curr_pos = win.currPos();
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
    _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}});
    if (win.wtop != savetop or wnd.*.wleft != saveleft)
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
}

// -- Ctrl+cursor left key: to beginning of previous word --
// not tested as NextWord()
fn PrevWord(win:*Window) void {
    const wnd = win.win;
    const savetop = win.wtop;
    const saveleft = wnd.*.wleft;
    win.ClearVisible();
    Backward(win);

    var curr_pos:usize = win.currPos();
    var cc:u8 = @intCast(wnd.*.text[curr_pos]&0x7f);
    while(isWhite(cc)) {
        if ((wnd.*.CurrLine == 0) and (wnd.*.CurrCol == 0))
            break;
        Backward(win);
        curr_pos = win.currPos();
        cc = @intCast(wnd.*.text[curr_pos]&0x7f);
    }
    while(wnd.*.CurrCol != 0 and !isWhite(cc)) {
        Backward(win);
        curr_pos = win.currPos();
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
    _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{@intCast(WndCol(win)), @intCast(wnd.*.WndRow)}});
    if (win.wtop != savetop or wnd.*.wleft != saveleft)
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
}

// ----- set anchor point for marking text block -----
fn SetAnchor(win:*Window, mx:usize, my:usize) void {
    textbox.ClearTextBlock(win);
    // ------ set the anchor ------
    win.BlkBegLine = my;
    win.BlkEndLine = my;
    win.BlkBegCol = mx;
    win.BlkEndCol = mx;
    _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
}
  
// ----- modify text pointers from a specified position
//                by a specified plus or minus amount -----
// Not in use, but could be useful
fn ModTextPointers(win:*Window, lineno:usize, incr:c_int) void {
    const wnd = win.win;
    for (lineno..win.wlines) |idx| {
        wnd.*.TextPointers[idx] += incr;
    }
//    while (lineno < wnd->wlines)
//        *((wnd->TextPointers) + lineno++) += var;
}
