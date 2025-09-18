const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");
const normal = @import("Normal.zig");
const GapBuffer = @import("GapBuffer.zig");

pub var VSliding = false; // also used in ListBox
var HSliding = false;

// ------------ ADDTEXT Message --------------
fn AddTextMsg(win:*Window, txt:[]const u8) bool {
    const wnd = win.win;
    // --- append text to the textbox's buffer ---
    const adln:usize = txt.len;
    if (adln > 0xfff0)
        return false;
//    if (win.text) |t| {
//        // ---- appending to existing text ----
//        const txln:usize = @intCast(df.strlen(wnd.*.text)); // more accurate than win.text because \0 ?
//        if (txln+adln > 0xfff0) { // consider overflow ?
//            return false;
//        }
//        if (txln+adln > wnd.*.textlen) {
//            if (root.global_allocator.realloc(t, txln+adln+3)) |buf| {
//                win.text = buf;
//                wnd.*.text = buf.ptr;
//                win.textlen = txln+adln+1;
//                wnd.*.textlen = @intCast(txln+adln+1);
//            } else |_| {
//            }
//        }
//    } else {
//        // ------ 1st text appended ------
//        if (root.global_allocator.allocSentinel(u8, adln+3, 0)) |buf| {
//            @memset(buf, 0);
//            win.text = buf;
//            wnd.*.text = buf.ptr;
//            win.textlen = adln+1;
//            wnd.*.textlen = @intCast(adln+1);
//        } else |_| {
//        }
//    }

    if (win.getGapBuffer(txt.len)) |buf| {
        // ---- append the text ----
        if (buf.insertSlice(txt)) { } else |_| { }
        if (buf.insert('\n')) { } else |_| { }
        wnd.*.text = @constCast(buf.toString().ptr);
        wnd.*.textlen = @intCast(buf.len());

        df.BuildTextPointers(wnd);
        return true;
    }


//    if (wnd->text != NULL)    {
//        /* ---- appending to existing text ---- */
//        unsigned txln = strlen(wnd->text);
//        if ((long)txln+adln > (unsigned) 0xfff0)
//            return FALSE;
//        if (txln+adln > wnd->textlen)    {
//            wnd->text = DFrealloc(wnd->text, txln+adln+3);
//            wnd->textlen = txln+adln+1;
//        }
//    }
//    else    {
//        /* ------ 1st text appended ------ */
//        wnd->text = DFcalloc(1, adln+3);
//        wnd->textlen = adln+1;
//    }

    wnd.*.TextChanged = df.TRUE;
//    if (win.text) |buf| {
        // ---- append the text ----
//        if (std.mem.indexOfScalar(u8, buf, 0)) |idx| {
//            @memcpy(buf.ptr[idx..idx+txt.len], txt);
//            @memcpy(buf.ptr[idx+txt.len..idx+txt.len+1], "\n");
//            @memcpy(buf.ptr[idx+txt.len+1..idx+txt.len+2], "\x00");
//            buf.ptr[idx+txt.len] = '\n';
//            buf.ptr[idx+txt.len+1] = 0;
//        }
//        strcat(wnd->text, txt);
//        strcat(wnd->text, "\n");

//        df.BuildTextPointers(wnd);
//        return true;
//    }
    return false;
}

// ------------ DELETETEXT Message --------------
fn DeleteTextMsg(win:*Window, lno:usize) void {
    const wnd = win.win;
    wnd.*.wlines -= 1;

    if (win.gapbuf) |buf| {
        const pos2 = buf.indexOfLine(lno+1, false);
        const pos1 = buf.indexOfLine(lno, true);
        for(pos1..pos2) |_| {
            buf.delete();
        }
        wnd.*.text = @constCast(buf.toString().ptr);
        wnd.*.textlen = @intCast(buf.len());

        df.BuildTextPointers(wnd);
    }

//    const pos1 = 
//        char *cp1 = TextLine(wnd, lno);
//        --wnd->wlines;
//        if (lno == wnd->wlines)
//                *cp1 = '\0';
//        else    {
//                char *cp2 = TextLine(wnd, lno+1);
//                memmove(cp1, cp2, strlen(cp2)+1);
//        }
//    df.BuildTextPointers(wnd);
}

// ------------ INSERTTEXT Message --------------
fn InsertTextMsg(win:*Window, txt:[]const u8, lno:usize) void {
    const wnd = win.win;

    if (win.getGapBuffer(txt.len)) |buf| {
        buf.compact();
        // find line
        _ = buf.indexOfLine(lno, true);

        // ---- append the text ----
        if (buf.insertSlice(txt)) { } else |_| { }
        if (buf.insert('\n')) { } else |_| { }
        wnd.*.text = @constCast(buf.toString().ptr);
        wnd.*.textlen = @intCast(buf.len());

        df.BuildTextPointers(wnd);
        wnd.*.TextChanged = df.TRUE;
    }
//    df.BuildTextPointers(wnd);
//    wnd.*.TextChanged = df.TRUE;
//    if (AddTextMsg(win, txt)) {
//        df.InsertTextAt(wnd, @constCast(txt.ptr), lno);
//        df.BuildTextPointers(wnd);
//        wnd.*.TextChanged = df.TRUE;
//    }
}


// ------------ SETTEXT Message --------------
fn SetTextMsg(win:*Window, txt:[]const u8) void {
    const wnd = win.win;
    // -- assign new text value to textbox buffer --
//    const len = txt.len+1;
    _ = win.sendMessage(df.CLEARTEXT, 0, 0);
    
//    if (win.text) |t| {
//        if (root.global_allocator.realloc(t, @intCast(len+1))) |buf| {
//            win.text = buf;
//        } else |_| {
//        }
//    } else {
//        if (root.global_allocator.allocSentinel(u8, @intCast(len+1), 0)) |buf| {
//            @memset(buf, 0);
//            win.text = buf;
//        } else |_| {
//        }
//    }
//
//    if (win.text) |buf| {
//        @memset(buf, 0);
//        @memcpy(buf[0..len-1], txt);
//        wnd.*.textlen = @intCast(len);
//        win.textlen = @intCast(len);
//        wnd.*.text = buf.ptr;
//        wnd.*.text[len] = 0;
//    }

    if (win.getGapBuffer(txt.len)) |buf| {
        buf.clear();
        if (buf.insertSlice(txt)) { } else |_| { }
        wnd.*.text = @constCast(buf.toString().ptr);
        wnd.*.textlen = @intCast(buf.len());
        df.BuildTextPointers(wnd);
    }
}

fn ClearTextMsg(win:*Window) void {
    const wnd = win.win;
    // ----- clear text from textbox -----
//    if (win.text) |text| {
//        root.global_allocator.free(text);
//        win.text = null;
//    }
//    wnd.*.text = null;
//    wnd.*.textlen = 0;
//    win.textlen = 0;
//    wnd.*.wlines = 0;
//    wnd.*.textwidth = 0;
//    wnd.*.wtop = 0;
//    wnd.*.wleft = 0;

    if (win.gapbuf) |buf| {
        buf.clear();
        wnd.*.text = null;
        wnd.*.textlen = 0;
        wnd.*.wlines = 0;
        wnd.*.textwidth = 0;
        wnd.*.wtop = 0;
        wnd.*.wleft = 0;
    }

    ClearTextBlock(win);
    df.ClearTextPointers(wnd);

}  

// ------------ KEYBOARD Message --------------
fn KeyboardMsg(win:*Window, p1:df.PARAM) bool {
    var rtn = false;

    switch (p1) {
        df.UP => {
            rtn = win.sendMessage(df.SCROLL,df.FALSE,0);
        },
        df.DN => {
            rtn = win.sendMessage(df.SCROLL,df.TRUE,0);
        },
        df.FWD => {
            rtn = win.sendMessage(df.HORIZSCROLL,df.TRUE,0);
        },
        df.BS => {
            rtn = win.sendMessage(df.HORIZSCROLL,df.FALSE,0);
        },
        df.PGUP => {
            rtn = win.sendMessage(df.SCROLLPAGE,df.FALSE,0);
        },
        df.PGDN => {
            rtn = win.sendMessage(df.SCROLLPAGE,df.TRUE,0);
        },
        df.CTRL_PGUP => {
            rtn = win.sendMessage(df.HORIZPAGE,df.FALSE,0);
        },
        df.CTRL_PGDN => {
            rtn = win.sendMessage(df.HORIZPAGE,df.TRUE,0);
        },
        df.HOME => {
            rtn = win.sendMessage(df.SCROLLDOC,df.TRUE,0);
        },
        df.END => {
            rtn = win.sendMessage(df.SCROLLDOC,df.FALSE,0);
        },
        else => {
        }
    }
    return rtn;
}

// ------------ LEFT_BUTTON Message --------------
fn LeftButtonMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    const mx = p1 - win.GetLeft();
    const my = p2 - win.GetTop();
    if (win.TestAttribute(df.VSCROLLBAR) and
                        mx == win.WindowWidth()-1) {
        // -------- in the right border -------
        if ((my == 0) or (my == win.ClientHeight()+1)) {
            // --- above or below the scroll bar ---
            return false;
        }
        if (my == 1) {
            // -------- top scroll button ---------
            return win.sendMessage(df.SCROLL, df.FALSE, 0);
        }
        if (my == win.ClientHeight()) {
            // -------- bottom scroll button ---------
            return win.sendMessage(df.SCROLL, df.TRUE, 0);
        }
        // ---------- in the scroll bar -----------
        if ((VSliding == false) and (my-1 == wnd.*.VScrollBox)) {
            VSliding = true;
            const rc:df.RECT = .{
                .lf = @intCast(win.GetRight()),
                .rt = @intCast(win.GetRight()),
                .tp = @intCast(win.GetTop()+2),
                .bt = @intCast(win.GetBottom()-2),
            };
            return (df.TRUE == q.SendMessage(null, df.MOUSE_TRAVEL, @intCast(@intFromPtr(&rc)), 0));
        }
        if (my-1 < wnd.*.VScrollBox) {
            return win.sendMessage(df.SCROLLPAGE,df.FALSE,0);
        }
        if (my-1 > wnd.*.VScrollBox) {
            return win.sendMessage(df.SCROLLPAGE,df.TRUE,0);
        }
    }
    if (win.TestAttribute(df.HSCROLLBAR) and
                        (my == win.WindowHeight()-1)) {
        // -------- in the bottom border ------- 
        if ((mx == 0) or (my == win.ClientWidth()+1)) {
            // ------  outside the scroll bar ----
            return false;
        }
        if (mx == 1) {
            return win.sendMessage(df.HORIZSCROLL,df.FALSE,0);
        }
        if (mx == win.WindowWidth()-2) {
            return win.sendMessage(df.HORIZSCROLL,df.TRUE,0);
        }
        if ((HSliding == false) and (mx-1 == wnd.*.HScrollBox)) {
            // --- hit the scroll box ---
            HSliding = true;
            const rc:df.RECT = .{
                .lf = @intCast(win.GetLeft()+2),
                .rt = @intCast(win.GetRight()-2),
                .tp = @intCast(win.GetBottom()),
                .bt = @intCast(win.GetBottom()),
            };
            // - keep the mouse in the scroll bar -
            _ = q.SendMessage(null, df.MOUSE_TRAVEL, @intCast(@intFromPtr(&rc)), 0);
            return true;
        }
        if (mx-1 < wnd.*.HScrollBox) {
            return win.sendMessage(df.HORIZPAGE,df.FALSE,0);
        }
        if (mx-1 > wnd.*.HScrollBox) {
            return win.sendMessage(df.HORIZPAGE,df.TRUE,0);
        }
    }
    return false;
}

fn MouseMovedMsg(win:*Window,p1:df.PARAM,p2:df.PARAM) bool {
    const wnd = win.win;
    const mx = p1 - win.GetLeft();
    const my = p2 - win.GetTop();
    if (VSliding) {
        // ---- dragging the vertical scroll box ---
        if (my-1 != wnd.*.VScrollBox) {
            df.foreground = df.FrameForeground(wnd);
            df.background = df.FrameBackground(wnd);
            df.wputch(wnd, df.SCROLLBARCHAR, @intCast(win.WindowWidth()-1), wnd.*.VScrollBox+1);
            wnd.*.VScrollBox = @intCast(my-1);
            df.wputch(wnd, df.SCROLLBOXCHAR, @intCast(win.WindowWidth()-1), @intCast(my));
        }
        return true;
    }
    if (HSliding) {
        // --- dragging the horizontal scroll box ---
        if (mx-1 != wnd.*.HScrollBox) {
            df.foreground = df.FrameForeground(wnd);
            df.background = df.FrameBackground(wnd);
            df.wputch(wnd, df.SCROLLBARCHAR, wnd.*.HScrollBox+1, @intCast(win.WindowHeight()-1));
            wnd.*.HScrollBox = @intCast(mx-1);
            df.wputch(wnd, df.SCROLLBOXCHAR, @intCast(mx), @intCast(win.WindowHeight()-1));
        }
        return true;
    }
    return false;
}

// ------------ BUTTON_RELEASED Message --------------
fn ButtonReleasedMsg(win:*Window) void {
    const wnd = win.win;
    if (HSliding or VSliding) {
        // release the mouse ouside the scroll bar
        _ = q.SendMessage(null, df.MOUSE_TRAVEL, 0, 0);
        if (VSliding) {
            df.ComputeWindowTop(wnd);
        } else {
            df.ComputeWindowLeft(wnd);
        }
        _ = win.sendMessage(df.PAINT, 0, 0);
        _ = win.sendMessage(df.KEYBOARD_CURSOR, 0, 0);
        VSliding = false;
        HSliding = false;
    }
}

// ------------ SCROLL Message --------------
fn ScrollMsg(win:*Window,p1:df.PARAM) bool {
    const wnd = win.win;
    // ---- vertical scroll one line ----
    if (p1>0) {
        // ----- scroll one line up -----
        if (wnd.*.wtop+win.ClientHeight() >= wnd.*.wlines) {
            return false;
        }
        wnd.*.wtop += 1;
    } else {
        // ----- scroll one line down -----
        if (wnd.*.wtop == 0) {
            return false;
        }
        wnd.*.wtop -= 1;
    }
    if (normal.isVisible(win)) {
        const rc = df.ClipRectangle(wnd, rect.ClientRect(win));
        if (df.ValidRect(rc))    {
            // ---- scroll the window ----- 
            if (win != Window.inFocus) {
                _ = win.sendMessage(df.PAINT, 0, 0);
            } else {
                df.scroll_window(wnd, rc, @intCast(p1));
                if (p1 == 0) {
                    // -- write top line (down) --
                    df.WriteTextLine(wnd,null,wnd.*.wtop,df.FALSE);
                } else {
                    // -- write bottom line (up) --
                    const y=df.RectBottom(rc)-win.GetClientTop();
                    df.WriteTextLine(wnd,null,@intCast(wnd.*.wtop+y), df.FALSE);
                }
            }
        }
        // ---- reset the scroll box ----
        if (win.TestAttribute(df.VSCROLLBAR)) {
            const vscrollbox = df.ComputeVScrollBox(wnd);
            if (vscrollbox != wnd.*.VScrollBox) {
                df.MoveScrollBox(wnd, vscrollbox);
            }
        }
    }
    return true;
}

fn HorizScrollMsg(win:*Window,p1:df.PARAM) bool {
    const wnd = win.win;
    // --- horizontal scroll one column ---
    if (p1>0) {
        // --- scroll left ---
        if (wnd.*.wleft + win.ClientWidth()-1 >= wnd.*.textwidth) {
            return false;
        }
        wnd.*.wleft += 1;
    } else {
        // --- scroll right ---
        if (wnd.*.wleft == 0) {
            return false;
        }
        wnd.*.wleft -= 1;
    }
    _ = win.sendMessage(df.PAINT, 0, 0);
    return true;
}

// ------------  SCROLLPAGE Message --------------
fn ScrollPageMsg(win:*Window,p1:df.PARAM) void {
    const wnd = win.win;
    // --- vertical scroll one page ---
    if (p1 == df.FALSE)    {
        // ---- page up ----
        if (wnd.*.wtop>0) {
            wnd.*.wtop -= @intCast(win.ClientHeight());
        }
    } else {
        // ---- page down ----
        if (wnd.*.wtop+win.ClientHeight() < wnd.*.wlines) {
            wnd.*.wtop += @intCast(win.ClientHeight());
            if (wnd.*.wtop>wnd.*.wlines-win.ClientHeight()) {
                wnd.*.wtop=@intCast(wnd.*.wlines-win.ClientHeight());
            }
        }
    }
    if (wnd.*.wtop < 0) {
        wnd.*.wtop = 0;
    }
    _ = win.sendMessage(df.PAINT, 0, 0);
}

// ------------ HORIZSCROLLPAGE Message --------------
fn HorizScrollPageMsg(win:*Window,p1:df.PARAM) void {
    const wnd = win.win;
    // --- horizontal scroll one page ---
    if (p1 == df.FALSE) {
        // ---- page left -----
        wnd.*.wleft -= @intCast(win.ClientWidth());
    } else {
        // ---- page right -----
        wnd.*.wleft += @intCast(win.ClientWidth());
        if (wnd.*.wleft > wnd.*.textwidth-win.ClientWidth()) {
            wnd.*.wleft = @intCast(wnd.*.textwidth-win.ClientWidth());
        }
    }
    if (wnd.*.wleft < 0) {
        wnd.*.wleft = 0;
    }
    _ = win.sendMessage(df.PAINT, 0, 0);
}

// ------------ SCROLLDOC Message --------------
fn ScrollDocMsg(win:*Window,p1:df.PARAM) void {
    const wnd = win.win;
    // --- scroll to beginning or end of document ---
    if (p1>0) {
        wnd.*.wtop = 0;
        wnd.*.wleft = 0;
    } else if (wnd.*.wtop+win.ClientHeight() < wnd.*.wlines) {
        wnd.*.wtop = @intCast(wnd.*.wlines-win.ClientHeight());
        wnd.*.wleft = 0;
    }
    _ = win.sendMessage(df.PAINT, 0, 0);
}

// ------------ PAINT Message --------------
fn PaintMsg(win:*Window,p1:df.PARAM,p2:df.PARAM) void {
    const wnd = win.win;
    // ------ paint the client area -----
    var rc:df.RECT = undefined;

    // ----- build the rectangle to paint -----
    if (p1 == 0) { // does it equal to (RECT *)p1 == NULL ?
        rc = df.RelativeWindowRect(wnd, win.WindowRect());
    } else {
        const pp1:usize = @intCast(p1);
        const rect1:*df.RECT = @ptrFromInt(pp1);
        rc = rect1.*;
    }
   
    if (win.TestAttribute(df.HASBORDER) and
            (rect.RectRight(rc) >= win.WindowWidth()-1)) {
        if (rect.RectLeft(rc) >= win.WindowWidth()-1) {
            return;
        }
        rc.rt = @intCast(win.WindowWidth()-2);
    }
    const rcc = df.AdjustRectangle(wnd, rc);

    if ((p2 == 0) and (win != Window.inFocus)) {
        df.ClipString += 1;
    }

    // ----- blank line for padding -----
    var blankline = [_]u8{' '}**df.MAXCOLS;
    blankline[@intCast(rect.RectRight(rcc)+1)] = 0;

//    char blankline[df.MAXCOLS];
//    memset(blankline, ' ', SCREENWIDTH);
//    blankline[RectRight(rcc)+1] = '\0';

    // ------- each line within rectangle ------
//    for (y = RectTop(rc); y <= RectBottom(rc); y++){
    for (@intCast(rect.RectTop(rc))..@intCast(rect.RectBottom(rc)+1)) |y| {
        // ---- test outside of Client area ----
        if (win.TestAttribute(df.HASBORDER | df.HASTITLEBAR)) {
            if (y < win.TopBorderAdj()) {
                continue;
            }
            if (y > win.WindowHeight()-2) {
                continue;
            }
        }
        const yi:isize = @intCast(y);
        const yy = yi-win.TopBorderAdj(); // not sure this number will be negative
        if (yy < wnd.*.wlines-wnd.*.wtop) {
            // ---- paint a text line ----
            df.WriteTextLine(wnd, &rc,
                        @intCast(yy+wnd.*.wtop), df.FALSE);
        } else {
            // ---- paint a blank line ----
            df.SetStandardColor(wnd);
            df.writeline(wnd, &blankline[@intCast(rect.RectLeft(rcc))],
                    @intCast(rect.RectLeft(rcc)+win.BorderAdj()), @intCast(yi), df.FALSE);
        }
    }

    // ------- position the scroll box -------
    if (win.TestAttribute(df.VSCROLLBAR|df.HSCROLLBAR)) {
        const hscrollbox = df.ComputeHScrollBox(wnd);
        const vscrollbox = df.ComputeVScrollBox(wnd);
        if ((hscrollbox != wnd.*.HScrollBox) or
                (vscrollbox != wnd.*.VScrollBox)) {
            wnd.*.HScrollBox = hscrollbox;
            wnd.*.VScrollBox = vscrollbox;
            _ = win.sendMessage(df.BORDER, p1, 0);
        }
    }
    if ((p2 == 0) and (win != Window.inFocus)) {
        df.ClipString -= 1;
    }
}

// ----------- TEXTBOX Message-processing Module -----------
pub fn TextBoxProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            wnd.*.HScrollBox = 1;
            wnd.*.VScrollBox = 1;
            df.ClearTextPointers(wnd);
        },
        df.ADDTEXT => {
            const pp1:usize = @intCast(p1);
            const txt:[*c]u8 = @ptrFromInt(pp1);
            const len = df.strlen(txt);
            return AddTextMsg(win, txt[0..len]);
        },
        df.DELETETEXT => {
            DeleteTextMsg(win, @intCast(p1));
            return true;
        },
        df.INSERTTEXT => {
            const pp1:usize = @intCast(p1);
            const txt:[*c]u8 = @ptrFromInt(pp1);
            const len = df.strlen(txt);
            InsertTextMsg(win, txt[0..len], @intCast(p2));
            return true;
        },
        df.SETTEXT => {
            const pp1:usize = @intCast(p1);
            const txt:[*c]u8 = @ptrFromInt(pp1);
            const len = df.strlen(txt);
            SetTextMsg(win, txt[0..len]);
            return true;
        },
        df.CLEARTEXT => {
            ClearTextMsg(win);
        },
        df.KEYBOARD => {
            if ((normal.WindowMoving == false) and (normal.WindowSizing == false)) {
                if (KeyboardMsg(win, p1)) {
                    return true;
                }
            }
        },
        df.LEFT_BUTTON => {
            if (normal.WindowMoving or normal.WindowSizing) {
                return false;
            }
            if (LeftButtonMsg(win, p1, p2)) {
                return true;
            }
        },
        df.MOUSE_MOVED => {
            if (MouseMovedMsg(win, p1, p2)) {
                return true;
            }
        },
        df.BUTTON_RELEASED => {
            ButtonReleasedMsg(win);
        },
        df.SCROLL => {
            return ScrollMsg(win, p1);
        },
        df.HORIZSCROLL => {
            return HorizScrollMsg(win, p1);
        },
        df.SCROLLPAGE => {
            ScrollPageMsg(win, p1);
            return true;
        },
        df.HORIZPAGE => {
            HorizScrollPageMsg(win, p1);
            return true;
        },
        df.SCROLLDOC => {
            ScrollDocMsg(win, p1);
            return true;
        },
        df.PAINT => {
            if (df.isVisible(wnd)>0) {
                PaintMsg(win, p1, p2);
                return false;
            }
        },
        df.CLOSE_WINDOW => {
            df.CloseWindowMsg(wnd);
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.TEXTBOX, win, msg, p1, p2);
}

pub fn ClearTextBlock(win:*Window) void {
    const wnd = win.win;
    wnd.*.BlkBegLine = 0;
    wnd.*.BlkEndLine = 0;
    wnd.*.BlkBegCol = 0;
    wnd.*.BlkEndCol = 0;
}
