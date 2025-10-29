const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const k = @import("Classes.zig").CLASS;
const colors = @import("Colors.zig");
const rect = @import("Rect.zig");
const normal = @import("Normal.zig");
const GapBuffer = @import("GapBuffer.zig");
const video = @import("Video.zig");
const console = @import("Console.zig");

pub var VSliding = false; // also used in ListBox
var HSliding = false;

// ------------ ADDTEXT Message --------------
fn AddTextMsg(win:*Window, txt:[]const u8) bool {
    const wnd = win.win;
    // --- append text to the textbox's buffer ---
    const adln:usize = txt.len;
    if (adln > 0xfff0)
        return false;

    if (win.getGapBuffer(txt.len)) |buf| {
        // ---- append the text ----
        if (buf.insertSlice(txt)) { } else |_| { }
        if (buf.insert('\n')) { } else |_| { }
        wnd.*.text = @constCast(buf.toString().ptr);
        wnd.*.textlen = @intCast(buf.len());

        BuildTextPointers(win);
        return true;
    }

    win.TextChanged = true;
    return false;
}

// ------------ DELETETEXT Message --------------
fn DeleteTextMsg(win:*Window, lno:usize) void {
    const wnd = win.win;
    win.wlines -|= 1;

    if (win.gapbuf) |buf| {
        const pos2 = buf.indexOfLine(lno+1, false);
        const pos1 = buf.indexOfLine(lno, true);
        for(pos1..pos2) |_| {
            buf.delete();
        }
        wnd.*.text = @constCast(buf.toString().ptr);
        wnd.*.textlen = @intCast(buf.len());

        BuildTextPointers(win);
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
//    BuildTextPointers(wnd);
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

        BuildTextPointers(win);
        win.TextChanged = true;
    }
//    BuildTextPointers(wnd);
//    wnd.*.TextChanged = df.TRUE;
//    if (AddTextMsg(win, txt)) {
//        df.InsertTextAt(wnd, @constCast(txt.ptr), lno);
//        BuildTextPointers(wnd);
//        wnd.*.TextChanged = df.TRUE;
//    }
}


// ------------ SETTEXT Message --------------
fn SetTextMsg(win:*Window, txt:[]const u8) void {
    const wnd = win.win;
    // -- assign new text value to textbox buffer --
    _ = win.sendMessage(df.CLEARTEXT, q.none);
    
    if (win.getGapBuffer(txt.len)) |buf| {
        buf.clear();
        if (buf.insertSlice(txt)) { } else |_| { }
        wnd.*.text = @constCast(buf.toString().ptr);
        wnd.*.textlen = @intCast(buf.len());
        BuildTextPointers(win);
    }
}

fn ClearTextMsg(win:*Window) void {
    const wnd = win.win;
    // ----- clear text from textbox -----
    if (win.gapbuf) |buf| {
        buf.clear();
        wnd.*.text = null;
        wnd.*.textlen = 0;
        win.wlines = 0;
        wnd.*.textwidth = 0;
        win.wtop = 0;
        wnd.*.wleft = 0;
    }

    ClearTextBlock(win);
    ClearTextPointers(win);

}  

// ------------ KEYBOARD Message --------------
fn KeyboardMsg(win:*Window, p1:u16) bool {
    var rtn = false;

    switch (p1) {
        df.UP => {
            rtn = win.sendMessage(df.SCROLL,.{.yes=false});
        },
        df.DN => {
            rtn = win.sendMessage(df.SCROLL,.{.yes=true});
        },
        df.FWD => {
            rtn = win.sendMessage(df.HORIZSCROLL,.{.yes=true});
        },
        df.BS => {
            rtn = win.sendMessage(df.HORIZSCROLL,.{.yes=false});
        },
        df.PGUP => {
            rtn = win.sendMessage(df.SCROLLPAGE,.{.yes=false});
        },
        df.PGDN => {
            rtn = win.sendMessage(df.SCROLLPAGE,.{.yes=true});
        },
        df.CTRL_PGUP => {
            rtn = win.sendMessage(df.HORIZPAGE,.{.yes=false});
        },
        df.CTRL_PGDN => {
            rtn = win.sendMessage(df.HORIZPAGE,.{.yes=true});
        },
        df.HOME => {
            rtn = win.sendMessage(df.SCROLLDOC,.{.yes=true});
        },
        df.END => {
            rtn = win.sendMessage(df.SCROLLDOC,.{.yes=false});
        },
        else => {
        }
    }
    return rtn;
}

// ------------ LEFT_BUTTON Message --------------
fn LeftButtonMsg(win:*Window, x:usize, y:usize) bool {
    const mx:usize = if (x > win.GetLeft()) x - win.GetLeft() else 0;
    const my:usize = if (y > win.GetTop()) y - win.GetTop() else 0;
    if (win.TestAttribute(df.VSCROLLBAR) and
                        mx == win.WindowWidth()-1) {
        // -------- in the right border -------
        if ((my == 0) or (my == win.ClientHeight()+1)) {
            // --- above or below the scroll bar ---
            return false;
        }
        if (my == 1) {
            // -------- top scroll button ---------
            return win.sendMessage(df.SCROLL, .{.yes=false});
        }
        if (my == win.ClientHeight()) {
            // -------- bottom scroll button ---------
            return win.sendMessage(df.SCROLL, .{.yes=true});
        }
        // ---------- in the scroll bar -----------
        if ((VSliding == false) and (my-1 == win.VScrollBox)) {
            VSliding = true;
            const rc:df.RECT = .{
                .lf = @intCast(win.GetRight()),
                .rt = @intCast(win.GetRight()),
                .tp = @intCast(win.GetTop()+2),
                .bt = @intCast(win.GetBottom()-2),
            };
            return q.SendMessage(null, df.MOUSE_TRAVEL, .{.area = rc});
        }
        if (my-1 < win.VScrollBox) {
            return win.sendMessage(df.SCROLLPAGE,.{.yes=false});
        }
        if (my-1 > win.VScrollBox) {
            return win.sendMessage(df.SCROLLPAGE,.{.yes=true});
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
            return win.sendMessage(df.HORIZSCROLL,.{.yes=false});
        }
        if (mx == win.WindowWidth()-2) {
            return win.sendMessage(df.HORIZSCROLL,.{.yes=true});
        }
        if ((HSliding == false) and (mx-1 == win.HScrollBox)) {
            // --- hit the scroll box ---
            HSliding = true;
            const rc:df.RECT = .{
                .lf = @intCast(win.GetLeft()+2),
                .rt = @intCast(win.GetRight()-2),
                .tp = @intCast(win.GetBottom()),
                .bt = @intCast(win.GetBottom()),
            };
            // - keep the mouse in the scroll bar -
            _ = q.SendMessage(null, df.MOUSE_TRAVEL, .{.area = rc});
            return true;
        }
        if (mx-1 < win.HScrollBox) {
            return win.sendMessage(df.HORIZPAGE,.{.yes=false});
        }
        if (mx-1 > win.HScrollBox) {
            return win.sendMessage(df.HORIZPAGE,.{.yes=true});
        }
    }
    return false;
}

fn MouseMovedMsg(win:*Window, x:usize, y:usize) bool {
    const mx:usize = if (x > win.GetLeft()) x-win.GetLeft() else 0;
    const my:usize = if (y > win.GetTop()) y-win.GetTop() else 0;
    if (VSliding) {
        // ---- dragging the vertical scroll box ---
        if (my-1 != win.VScrollBox) {
            df.foreground = colors.FrameForeground(win);
            df.background = colors.FrameBackground(win);
            video.wputch(win, df.SCROLLBARCHAR, win.WindowWidth()-1, win.VScrollBox+1);
            win.VScrollBox = @intCast(my-1);
            video.wputch(win, df.SCROLLBOXCHAR, win.WindowWidth()-1, my);
        }
        return true;
    }
    if (HSliding) {
        // --- dragging the horizontal scroll box ---
        if (mx-1 != win.HScrollBox) {
            df.foreground = colors.FrameForeground(win);
            df.background = colors.FrameBackground(win);
            video.wputch(win, df.SCROLLBARCHAR, win.HScrollBox+1, win.WindowHeight()-1);
            win.HScrollBox = @intCast(mx-1);
            video.wputch(win, df.SCROLLBOXCHAR, mx, win.WindowHeight()-1);
        }
        return true;
    }
    return false;
}

// ------------ BUTTON_RELEASED Message --------------
fn ButtonReleasedMsg(win:*Window) void {
    if (HSliding or VSliding) {
        // release the mouse ouside the scroll bar
        _ = q.SendMessage(null, df.MOUSE_TRAVEL, .{.area=null});
        if (VSliding) {
            ComputeWindowTop(win);
        } else {
            ComputeWindowLeft(win);
        }
        _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
        _ = win.sendMessage(df.KEYBOARD_CURSOR, .{.position=.{0, 0}});
        VSliding = false;
        HSliding = false;
    }
}

// ------------ SCROLL Message --------------
fn ScrollMsg(win:*Window,p1:bool) bool {
    const wnd = win.win;
    // ---- vertical scroll one line ----
    if (p1) {
        // ----- scroll one line up -----
        if (win.wtop+win.ClientHeight() >= win.wlines) {
            return false;
        }
        win.wtop += 1;
    } else {
        // ----- scroll one line down -----
        if (win.wtop == 0) {
            return false;
        }
        win.wtop -|= 1;
    }
    if (win.isVisible()) {
        const rc = df.ClipRectangle(wnd, rect.ClientRect(win));
        if (df.ValidRect(rc))    {
            // ---- scroll the window ----- 
            if (win != Window.inFocus) {
                _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            } else {
                console.scroll_window(win, rc, if (p1) 1 else 0);
                if (p1 == false) {
                    // -- write top line (down) --
                    WriteTextLine(win,null,win.wtop,false);
                } else {
                    // -- write bottom line (up) --
                    const y:usize=@as(usize, @intCast(rc.bt))-win.GetClientTop();
                    WriteTextLine(win,null,win.wtop+y,false);
                }
            }
        }
        // ---- reset the scroll box ----
        if (win.TestAttribute(df.VSCROLLBAR)) {
            const vscrollbox = ComputeVScrollBox(win);
            if (vscrollbox != win.VScrollBox) {
                MoveScrollBox(win, vscrollbox);
            }
        }
    }
    return true;
}

fn HorizScrollMsg(win:*Window,p1:bool) bool {
    const wnd = win.win;
    // --- horizontal scroll one column ---
    if (p1) {
        // --- scroll left ---
        if (wnd.*.wleft + @as(c_int, @intCast(win.ClientWidth()))-1 >= wnd.*.textwidth) {
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
    _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
    return true;
}

// ------------  SCROLLPAGE Message --------------
fn ScrollPageMsg(win:*Window,p1:bool) void {
    const clientHeight:usize = win.ClientHeight();
    // --- vertical scroll one page ---
    if (p1 == false)    {
        // ---- page up ----
        if (win.wtop > 0) {
            win.wtop -|= clientHeight;
        }
    } else {
        // ---- page down ----
        if (win.wtop+clientHeight < win.wlines) {
            win.wtop += clientHeight;
            if (win.wtop>win.wlines-clientHeight) {
                win.wtop=win.wlines-clientHeight;
            }
        }
    }
//    if (wnd.*.wtop < 0) {
//        wnd.*.wtop = 0;
//    }
    _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
}

// ------------ HORIZSCROLLPAGE Message --------------
fn HorizScrollPageMsg(win:*Window,p1:bool) void {
    const wnd = win.win;
    const clientWidth: c_int = @intCast(win.ClientWidth());
    // --- horizontal scroll one page ---
    if (p1 == false) {
        // ---- page left -----
        wnd.*.wleft -= clientWidth;
    } else {
        // ---- page right -----
        wnd.*.wleft += clientWidth;
        if (wnd.*.wleft > wnd.*.textwidth-clientWidth) {
            wnd.*.wleft = @intCast(wnd.*.textwidth-clientWidth);
        }
    }
    if (wnd.*.wleft < 0) {
        wnd.*.wleft = 0;
    }
    _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
}

// ------------ SCROLLDOC Message --------------
fn ScrollDocMsg(win:*Window,p1:bool) void {
    const wnd = win.win;
    const clientHeight:usize = win.ClientHeight();
    // --- scroll to beginning or end of document ---
    if (p1) {
        win.wtop = 0;
        wnd.*.wleft = 0;
    } else if (win.wtop+clientHeight < win.wlines) {
        win.wtop = win.wlines-clientHeight;
        wnd.*.wleft = 0;
    }
    _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
}

// ------------ PAINT Message --------------
fn PaintMsg(win:*Window,p1:?df.RECT,p2:bool) void {
    const wnd = win.win;
    // ------ paint the client area -----
    var rc:df.RECT = undefined;

    // ----- build the rectangle to paint -----
    if (p1) |rect1| {
        rc = rect1;
    } else {
        rc = df.RelativeWindowRect(wnd, win.WindowRect());
    }
   
    if (win.TestAttribute(df.HASBORDER) and
            (rect.RectRight(rc) >= win.WindowWidth()-1)) {
        if (rect.RectLeft(rc) >= win.WindowWidth()-1) {
            return;
        }
        rc.rt = @intCast(win.WindowWidth()-2);
    }
    const rcc = win.AdjustRectangle(rc);

    if ((p2 == false) and (win != Window.inFocus)) {
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
        var yy:usize = 0;
        if (y > win.TopBorderAdj()) {
            yy = y-win.TopBorderAdj();
        }
        if (yy < win.wlines-win.wtop) {
            // ---- paint a text line ----
            WriteTextLine(win, rc, @intCast(yy+win.wtop), false);
        } else {
            // ---- paint a blank line ----
            df.SetStandardColor(wnd);
            win.writeline(@ptrCast(blankline[@intCast(rcc.lf)..]),
                    @as(usize, @intCast(rcc.lf))+win.BorderAdj(), y, false);
        }
    }

    // ------- position the scroll box -------
    if (win.TestAttribute(df.VSCROLLBAR|df.HSCROLLBAR)) {
        const hscrollbox = ComputeHScrollBox(win);
        const vscrollbox = ComputeVScrollBox(win);
        if ((hscrollbox != win.HScrollBox) or
                (vscrollbox != win.VScrollBox)) {
            win.HScrollBox = hscrollbox;
            win.VScrollBox = vscrollbox;
            _ = win.sendMessage(df.BORDER, .{.paint=.{p1, false}});
        }
    }
    if ((p2 == false) and (win != Window.inFocus)) {
        df.ClipString -= 1;
    }
}

// ------------ CLOSE_WINDOW Message --------------
fn CloseWindowMsg(win:*Window) void {
    const wnd = win.win;
    _ = win.sendMessage(df.CLEARTEXT, q.none);
    if (wnd.*.TextPointers != null) {
        root.global_allocator.free(wnd.*.TextPointers[0..win.wlines]);
        wnd.*.TextPointers = null;
    }
}

// ----------- TEXTBOX Message-processing Module -----------
pub fn TextBoxProc(win:*Window, msg: df.MESSAGE, params:q.Params) bool {
    switch (msg) {
        df.CREATE_WINDOW => {
            win.HScrollBox = 1;
            win.VScrollBox = 1;
            ClearTextPointers(win);
        },
        df.ADDTEXT => {
            return AddTextMsg(win, params.slice);
        },
        df.DELETETEXT => {
            const p1 = params.usize;
            DeleteTextMsg(win, p1);
            return true;
        },
        df.INSERTTEXT => {
            const p1:[]const u8 = params.put_text[0];
            const p2:usize = params.put_text[1];
            InsertTextMsg(win, p1, p2);
            return true;
        },
        df.SETTEXT => {
            SetTextMsg(win, params.slice);
            return true;
        },
        df.CLEARTEXT => {
            ClearTextMsg(win);
        },
        df.KEYBOARD => {
            const p1 = params.char[0];
            if ((normal.WindowMoving == false) and (normal.WindowSizing == false)) {
                if (KeyboardMsg(win, p1)) {
                    return true;
                }
            }
        },
        df.LEFT_BUTTON => {
            const x = params.position[0];
            const y = params.position[1];
            if (normal.WindowMoving or normal.WindowSizing) {
                return false;
            }
            if (LeftButtonMsg(win, x, y)) {
                return true;
            }
        },
        df.MOUSE_MOVED => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            if (MouseMovedMsg(win, p1, p2)) {
                return true;
            }
        },
        df.BUTTON_RELEASED => {
            ButtonReleasedMsg(win);
        },
        df.SCROLL => {
            return ScrollMsg(win, params.yes);
        },
        df.HORIZSCROLL => {
            return HorizScrollMsg(win, params.yes);
        },
        df.SCROLLPAGE => {
            ScrollPageMsg(win, params.yes);
            return true;
        },
        df.HORIZPAGE => {
            HorizScrollPageMsg(win, params.yes);
            return true;
        },
        df.SCROLLDOC => {
            ScrollDocMsg(win, params.yes);
            return true;
        },
        df.PAINT => {
            const p1:?df.RECT = params.paint[0];
            const p2:bool = params.paint[1];
            if (win.isVisible()) {
                PaintMsg(win, p1, p2);
                return false;
            }
        },
        df.CLOSE_WINDOW => {
            CloseWindowMsg(win);
        },
        else => {
        }
    }
    return root.BaseWndProc(k.TEXTBOX, win, msg, params);
}

//#define TextLine(wnd, sel) \
//      (wnd->text + *((wnd->TextPointers) + (unsigned int)sel))
//pub fn TextLine(wnd:df.WINDOW, sel:c_uint) [*c]u8 {
//    return wnd.*.text + wnd.*.TextPointers[sel];
//}

// ------ compute the vertical scroll box position from
//                   the text pointers ---------
fn ComputeVScrollBox(win:*Window) usize {
    // will this go negative ?
    var pagelen:usize = 0;
    if (win.wlines > win.ClientHeight()) {
        pagelen = win.wlines - win.ClientHeight();
    }
    const barlen:usize = if (win.ClientHeight()>2) win.ClientHeight()-2 else 0;
    var lines_tick:usize = 0;
    var vscrollbox:usize = 0;

    if (pagelen < 1 or barlen < 1) {
        vscrollbox = 1;
    } else {
        if (pagelen > barlen) {
            lines_tick = @intCast(@divFloor(pagelen, barlen));
        } else {
            lines_tick = @intCast(@divFloor(barlen, pagelen));
        }
        const wtop:usize = win.wtop;
        vscrollbox = 1 + @divFloor(wtop, lines_tick);
        if (vscrollbox > win.ClientHeight()-2 or
                win.wtop + win.ClientHeight() >= win.wlines) {
            vscrollbox = @intCast(win.ClientHeight()-2);
        }
    }
    return vscrollbox;
}

// ---- compute top text line from scroll box position ----
fn ComputeWindowTop(win:*Window) void {
    const pagelen:usize = if (win.wlines > win.ClientHeight()) win.wlines - win.ClientHeight() else 0;
    if (win.VScrollBox == 0) {
        win.wtop = 0;
    } else if (win.VScrollBox == win.ClientHeight()-2) {
        win.wtop = pagelen;
    } else {
        const barlen:usize = if (win.ClientHeight() > 2) win.ClientHeight()-2 else 0;
        var lines_tick:usize = 0;

        if (pagelen > barlen) {
            lines_tick = if (barlen>0) @divFloor(pagelen, barlen) else 0;
        } else {
            lines_tick = if (pagelen>0) @divFloor(barlen, pagelen) else 0;
        }
        win.wtop = @intCast((win.VScrollBox-1) * lines_tick);
        if (win.wtop + win.ClientHeight() > win.wlines)
            win.wtop = pagelen;
    }
//    if (win.*.wtop < 0)
//        wnd.*.wtop = 0;
}

// ------ compute the horizontal scroll box position from
//                 the text pointers ---------
fn ComputeHScrollBox(win:*Window) usize {
    const wnd = win.win;
    var pagewidth:usize = 0;
    if (wnd.*.textwidth > win.ClientWidth()) {
        pagewidth = @as(usize, @intCast(wnd.*.textwidth)) - win.ClientWidth();
    }
    const barlen:usize = if (win.ClientWidth() > 2) win.ClientWidth()-2 else 0;
    var chars_tick:usize = 0;
    var hscrollbox:usize = 0;

    if (pagewidth < 1 or barlen < 1) {
        hscrollbox = 1;
    } else {
        if (pagewidth > barlen) {
            chars_tick = if (barlen>0) @intCast(@divFloor(pagewidth, barlen)) else 0;
        } else {
            chars_tick = if (pagewidth>0) @intCast(@divFloor(barlen, pagewidth)) else 0;
        }
        const wleft:usize = @intCast(wnd.*.wleft);
        const diff:usize = if (chars_tick>0) @divFloor(wleft, chars_tick) else 0;
        hscrollbox = 1 + diff;
        if (hscrollbox > win.ClientWidth()-2 or
                wnd.*.wleft + @as(c_int, @intCast(win.ClientWidth())) >= wnd.*.textwidth) {
            hscrollbox = @intCast(win.ClientWidth()-2);
        }
    }
    return hscrollbox;
}

// ---- compute left column from scroll box position ----
fn ComputeWindowLeft(win:*Window) void {
    const wnd = win.win;
    const pagewidth:usize = @as(usize, @intCast(wnd.*.textwidth)) - win.ClientWidth();

    if (win.HScrollBox == 0) {
        wnd.*.wleft = 0;
    } else if (win.HScrollBox == win.ClientWidth()-2) {
        wnd.*.wleft = @intCast(pagewidth);
    } else {
        const barlen:usize = @intCast(win.ClientWidth()-2);
        var chars_tick:usize = 0;

        if (pagewidth > barlen) {
            chars_tick = @divFloor(pagewidth, barlen);
        } else {
            chars_tick = @divFloor(barlen, pagewidth);
        }
        wnd.*.wleft = @intCast((win.HScrollBox-1) * chars_tick);
        if (wnd.*.wleft + @as(c_int, @intCast(win.ClientWidth())) > wnd.*.textwidth)
            wnd.*.wleft = @intCast(pagewidth);
    }
    if (wnd.*.wleft < 0)
        wnd.*.wleft = 0;
}

// ------- write a line of text to a textbox window -------
pub fn WriteTextLine(win:*Window, rcc:?df.RECT, y:usize, reverse:bool) void {
    const wnd = win.win;

    // ------ make sure y is inside the window -----
    if (y < win.wtop or y >= win.wtop+win.ClientHeight())
        return;

    // ---- build the retangle within which can write ----
    var rc:df.RECT = undefined;
    if (rcc) |cc| {
        rc = cc;
    } else {
        rc = df.RelativeWindowRect(wnd, win.WindowRect());
        if (win.TestAttribute(df.HASBORDER) and
                rc.rt >= win.WindowWidth()-1) {
            rc.rt = @intCast(win.WindowWidth()-2);
        }
    }

    // ----- make sure rectangle is within window ------
    if (rc.lf >= win.WindowWidth()-1)
        return;
    if (rc.rt == 0)
        return;
    rc = win.AdjustRectangle(rc);
    if (y-win.wtop < rc.tp or y-win.wtop > rc.bt)
        return;

    // ----- get the text to a specified line -----
    // should check out of bound of y?
    const beg = win.TextPointers[@intCast(y)];
    if (std.mem.indexOfScalarPos(u8, wnd.*.text[0..wnd.*.textlen], beg, '\n')) |pos| {

        // FIXME: handle protect

        const len = pos-beg;
        if (root.global_allocator.alloc(u8, len+7)) |buf| {
            defer root.global_allocator.free(buf);
            @memset(buf, 0);
            @memmove(buf[0..len], wnd.*.text[beg..pos]);

            // -------- insert block color change controls -------
            var lnlen = df.LineLength(buf.ptr);
            if (TextBlockMarked(win)) {
                var bbl = win.BlkBegLine;
                var bel = win.BlkEndLine;
                var bbc = win.BlkBegCol;
                var bec = win.BlkEndCol;
                const by:usize = @intCast(y);

                // ----- put lowest marker first -----
                if (bbl > bel) {
                    var temp = bbl;
                    bbl = bel;
                    bel = temp;

                    temp = bbc;
                    bbc = bec;
                    bec = temp;
//                    swap(bbl, bel);
//                    swap(bbc, bec);
                }
                if (bbl == bel and bbc > bec) {
                    const temp = bbc;
                    bbc = bec;
                    bec = temp;
//                    swap(bbc, bec);
                }

                if (by >= bbl and by <= bel) {
                    // ------ the block includes this line -----
                    var blkbeg:usize = 0;
                    var blkend:usize = @intCast(lnlen);
                    if ((by > bbl and by < bel) == false) {
                        // --- the entire line is not in the block --
                        if (by == bbl) {
                            // ---- the block begins on this line ---
                            blkbeg = bbc;
                        }
                        if (by == bel) {
                            // ---- the block ends on this line ----
                            blkend = bec;
                        }
                    }
                    if (blkend == 0 and lnlen == 0)  {
                        buf[0] = ' ';
                        blkend += 1;
//                                strcpy(lp, " ");
//                                blkend++;
                    }
                    // ----- insert the reset color token -----
                    if (std.mem.indexOfScalarPos(u8, buf, blkend, 0)) |loc| {
                        @memmove(buf[blkend+1..loc+2], buf[blkend..loc+1]);
                        buf[blkend] = df.RESETCOLOR;
                    }
//                    memmove(lp+blkend+1,lp+blkend,strlen(lp+blkend)+1);
//                    lp[blkend] = RESETCOLOR;
                    // ----- insert the change color token -----
                    if (std.mem.indexOfScalarPos(u8, buf, blkbeg, 0)) |loc| {
                        @memmove(buf[blkbeg+3..loc+4], buf[blkbeg..loc+1]);
                        buf[blkbeg] = df.CHANGECOLOR;
                    }
//                    memmove(lp+blkbeg+3,lp+blkbeg,strlen(lp+blkbeg)+1);
//                    lp[blkbeg] = CHANGECOLOR;
                    // ----- insert the color tokens -----
                    colors.SetReverseColor(wnd);
                    buf[blkbeg+1] = @intCast(df.foreground | 0x80);
                    buf[blkbeg+2] = @intCast(df.background | 0x80);
                    lnlen += 4;
                }
            }

            var line = [_]u8{0}**df.MAXCOLS;

            df.cWriteTextLine(wnd, rc, lnlen, buf.ptr, @constCast(&line));

            var dif:usize = 0;
            // ------ establish the line's main color -----
            if (reverse) {
                colors.SetReverseColor(wnd);
                var loc:usize = 0;
                while(std.mem.indexOfScalarPos(u8, @constCast(&line), loc, df.CHANGECOLOR)) |l| {
                    loc = l+2;
                    line[loc] = @intCast(df.background | 0x80);
                    loc += 1;
                }
                if (line[0] == df.CHANGECOLOR) {
                    dif = 3;
                }
            } else {
                colors.SetStandardColor(wnd);
            }
            // ------- display the line --------
            win.writeline(@ptrCast(line[dif..]), @as(usize, @intCast(rc.lf))+win.BorderAdj(),
                                       y-win.wtop+win.TopBorderAdj(), false);

        } else |_| {
        }
    }
}

pub fn TextBlockMarked(win:*Window) bool {
    return (win.BlkBegLine>0) or (win.BlkBegCol>0) or
           (win.BlkEndLine>0) or (win.BlkEndCol>0);
}

// not in use
//void MarkTextBlock(WINDOW wnd, int BegLine, int BegCol,
//                               int EndLine, int EndCol)
//{
//    wnd->BlkBegLine = BegLine;
//    wnd->BlkEndLine = EndLine;
//    wnd->BlkBegCol = BegCol;
//    wnd->BlkEndCol = EndCol;
//}


pub fn ClearTextBlock(win:*Window) void {
    win.BlkBegLine = 0;
    win.BlkEndLine = 0;
    win.BlkBegCol = 0;
    win.BlkEndCol = 0;
}

// ----- clear and initialize text line pointer array -----
pub fn ClearTextPointers(win:*Window) void {
    const wnd = win.win;
    const allocator = root.global_allocator;
    var arraylist:std.ArrayList(c_uint) = undefined;
    if (win.TextPointers.len > 0) {
        arraylist = std.ArrayList(c_uint).fromOwnedSlice(win.TextPointers);
        arraylist.clearRetainingCapacity();
    } else {
        if (std.ArrayList(c_uint).initCapacity(allocator, 1)) |list| {
            arraylist = list;
        } else |_| {
            return;
        }
    }
//    if (wnd.*.TextPointers) |pointers| {
//        const slice = pointers[0..@intCast(wnd.*.wlines)];    
//        arraylist = std.ArrayList(c_uint).fromOwnedSlice(slice);
//        arraylist.clearRetainingCapacity();
//    } else {
//        if (std.ArrayList(c_uint).initCapacity(allocator, 1)) |list| {
//            arraylist = list;
//        } else |_| {
//            return;
//        }
//    }
    if (arraylist.append(allocator, 0)) {} else |_| {} // first line
    if (arraylist.toOwnedSlice(allocator)) |pointers| {
        win.TextPointers = pointers;
        wnd.*.TextPointers = pointers.ptr;
    } else |_| {}
    // set wnd.*.wlines to zero ?
    win.wlines = 0;

//    wnd->TextPointers = DFrealloc(wnd->TextPointers, sizeof(int));
//    *(wnd->TextPointers) = 0;
}

// ---- build array of pointers to text lines ----
pub fn BuildTextPointers(win:*Window) void {
    const wnd = win.win;
    const allocator = root.global_allocator;
    var arraylist:std.ArrayList(c_uint) = undefined;
    if (win.TextPointers.len > 0) {
        arraylist = std.ArrayList(c_uint).fromOwnedSlice(win.TextPointers);
        arraylist.clearRetainingCapacity();
    } else {
        if (std.ArrayList(c_uint).initCapacity(allocator, 100)) |list| {
            arraylist = list;
        } else |_| {
            return;
        }
    }

//    if (wnd.*.TextPointers) |pointers| {
//        arraylist = std.ArrayList(c_uint).fromOwnedSlice(pointers[0..@intCast(wnd.*.wlines)]);
//        arraylist.clearRetainingCapacity();
//    } else {
//        if (std.ArrayList(c_uint).initCapacity(allocator, 100)) |list| {
//            arraylist = list;
//        } else |_| {
//            return;
//        }
//    }

    // Need to consider gap. Not yet work.
//    if (Window.get_zin(wnd)) |win| {
//        if (win.gapbuf) |buf| {
//            wnd.*.wlines = 0;
//            wnd.*.textwidth = 0;
//            var prev_pos:usize= 0; // pos including gap
//            const diff = buf.gap_end - buf.gap_start;
//
//            if (arraylist.append(allocator, 0)) {} else |_| {} // first line
//            wnd.*.wlines += 1;
//
//            // this only cound to last '\n'
//            while (std.mem.indexOfScalarPos(u8, buf.items, pos, '\n')) |pos| {
//                if ((buf.gap_start <= pos) and (pos < buf.gap_end)) {
//                    pos = buf.gap_end;
//                    continue;
//                }
//       
//                wnd.*.textwidth = @intCast(@max(wnd.*.textwidth, pos-prev_pos));
//                // adjust for pos in gap
//                if ((prev_pos <= buf.gap_start) and (buf.gap_end < pos)) {
//                    wnd.*.textwidth -= @intCast(diff);
//                }
//
//                if (pos+1 < buf.len()) {
//                    // add next line if there are still content
//                    // otherwise, it is the end of line and end of text
//                    // adjust for gap
//                    var next_pos = pos+1; // pos excluding gap
//                    if (buf.gap_end < pos) {
//                        next_pos -= diff;
//                    }
//                    if (arraylist.append(allocator, @intCast(next_pos))) {} else |_| {} // next new line
//                    wnd.*.wlines += 1;
//                }
//                prev_pos = pos;
//                pos += 1;
//            }
//            if (pos+1 < buf.len()) {
//                // there is no '\n', but may still has text.
//                wnd.*.textwidth = @intCast(@max(wnd.*.textwidth, wnd.*.textlen-prev_pos));
//            }
//        }
//       
//    }

    if (wnd.*.text) |text| {
        win.wlines = 0;
        wnd.*.textwidth = 0;
        var next_pos:usize= 0;

        if (arraylist.append(allocator, 0)) {} else |_| {} // first line
        win.wlines += 1;

        // this only cound to last '\n'
        while (std.mem.indexOfScalarPos(u8, text[0..wnd.*.textlen], next_pos, '\n')) |pos| {
            wnd.*.textwidth = @intCast(@max(wnd.*.textwidth, pos-next_pos));
            next_pos = pos+1;
            if (next_pos < wnd.*.textlen) {
                // add next line if there are still content
                // otherwise, it is the end of line and end of text
                if (arraylist.append(allocator, @intCast(next_pos))) {} else |_| {} // next new line
                win.wlines += 1;
            }
        }
        if (next_pos < wnd.*.textlen) {
            // there is no '\n', but may still has text.
            wnd.*.textwidth = @intCast(@max(wnd.*.textwidth, wnd.*.textlen-next_pos));
        }
       
    }

    if (arraylist.toOwnedSlice(allocator)) |pointers| {
        win.TextPointers = pointers;
        wnd.*.TextPointers = pointers.ptr;
    } else |_| {}

//    char *cp = wnd->text, *cp1;
//    int incrs = INITLINES;
//    unsigned int off;
//    wnd->textwidth = wnd->wlines = 0;
//    while (*cp)    {
//        if (incrs == INITLINES)    {
//            incrs = 0;
//            wnd->TextPointers = DFrealloc(wnd->TextPointers,
//                    (wnd->wlines + INITLINES) * sizeof(int));
//        }
//        off = (unsigned int) (cp - (char *)wnd->text);
//        *((wnd->TextPointers) + wnd->wlines) = off;
//        wnd->wlines++;
//        incrs++;
//        cp1 = cp;
//        while (*cp && *cp != '\n')
//            cp++;
//        wnd->textwidth = max(wnd->textwidth,
//                        (unsigned int) (cp - cp1));
//        if (*cp)
//            cp++;
//    }
}

fn MoveScrollBox(win:*Window, vscrollbox:usize) void {
    df.foreground = colors.FrameForeground(win);
    df.background = colors.FrameBackground(win);
    video.wputch(win, df.SCROLLBARCHAR, win.WindowWidth()-1, win.VScrollBox+1);
    video.wputch(win, df.SCROLLBOXCHAR, win.WindowWidth()-1, vscrollbox+1);
    win.VScrollBox = vscrollbox;
}

pub fn TextLineNumber(win:*Window, pos:usize) usize {
    const len:usize = win.wlines;
    var line:usize = 0;
    for (win.TextPointers, 0..) |lp, idx| {
        if (pos > lp) {
            line = idx;
        } else {
            return line;
        }
    }
    return len-1;
}
