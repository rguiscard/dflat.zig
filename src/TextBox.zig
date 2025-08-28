const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const rect = @import("Rect.zig");

pub var VSliding = false; // also used in ListBox
var HSliding = false;

// ------------ SETTEXT Message --------------
fn SetTextMsg(win:*Window, txt:[]const u8) void {
    const wnd = win.win;
    // -- assign new text value to textbox buffer --
    const len = txt.len;
    _ = win.sendMessage(df.CLEARTEXT, 0, 0);
    
    if (root.global_allocator.alloc(u8, len+1)) |buf| {
        @memcpy(buf[0..len], txt);
        wnd.*.textlen = @intCast(len);
        wnd.*.text = buf.ptr;
        wnd.*.text[len] = 0;
    } else |_| {
        // error 
    }
    df.BuildTextPointers(wnd);
}

fn ClearTextMsg(win:*Window) void {
    const wnd = win.win;
    // ----- clear text from textbox -----
    if (wnd.*.text) |text| {
        df.free(text);
    }
    wnd.*.text = null;
    wnd.*.textlen = 0;
    wnd.*.wlines = 0;
    wnd.*.textwidth = 0;
    wnd.*.wtop = 0;
    wnd.*.wleft = 0;
    ClearTextBlock(win);
    df.ClearTextPointers(wnd);
}  

// ------------ KEYBOARD Message --------------
fn KeyboardMsg(win:*Window, p1:df.PARAM) bool {
    var rtn:c_uint = df.FALSE;

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
    return (rtn == df.TRUE);
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
            return (df.TRUE == win.sendMessage(df.SCROLL, df.FALSE, 0));
        }
        if (my == win.ClientHeight()) {
            // -------- bottom scroll button ---------
            return (df.TRUE == win.sendMessage(df.SCROLL, df.TRUE, 0));
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
            return (df.TRUE == win.sendMessage(df.SCROLLPAGE,df.FALSE,0));
        }
        if (my-1 > wnd.*.VScrollBox) {
            return (df.TRUE == win.sendMessage(df.SCROLLPAGE,df.TRUE,0));
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
            return (df.TRUE == win.sendMessage(df.HORIZSCROLL,df.FALSE,0));
        }
        if (mx == win.WindowWidth()-2) {
            return (df.TRUE == win.sendMessage(df.HORIZSCROLL,df.TRUE,0));
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
            return (df.TRUE == win.sendMessage(df.HORIZPAGE,df.FALSE,0));
        }
        if (mx-1 > wnd.*.HScrollBox) {
            return (df.TRUE == win.sendMessage(df.HORIZPAGE,df.TRUE,0));
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
fn ScrollMsg(win:*Window,p1:df.PARAM) c_int {
    const wnd = win.win;
    // ---- vertical scroll one line ----
    if (p1>0) {
        // ----- scroll one line up -----
        if (wnd.*.wtop+win.ClientHeight() >= wnd.*.wlines) {
            return df.FALSE;
        }
        wnd.*.wtop += 1;
    } else {
        // ----- scroll one line down -----
        if (wnd.*.wtop == 0) {
            return df.FALSE;
        }
        wnd.*.wtop -= 1;
    }
    if (df.isVisible(wnd)>0) {
        const rc = df.ClipRectangle(wnd, rect.ClientRect(win));
        if (df.ValidRect(rc))    {
            // ---- scroll the window ----- 
            if (wnd != df.inFocus) {
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
    return df.TRUE;
}

fn HorizScrollMsg(win:*Window,p1:df.PARAM) c_int {
    const wnd = win.win;
    // --- horizontal scroll one column ---
    if (p1>0) {
        // --- scroll left ---
        if (wnd.*.wleft + win.ClientWidth()-1 >= wnd.*.textwidth) {
            return df.FALSE;
        }
        wnd.*.wleft += 1;
    } else {
        // --- scroll right ---
        if (wnd.*.wleft == 0) {
            return df.FALSE;
        }
        wnd.*.wleft -= 1;
    }
    _ = win.sendMessage(df.PAINT, 0, 0);
    return df.TRUE;
}

// ----------- TEXTBOX Message-processing Module -----------
pub fn TextBoxProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            wnd.*.HScrollBox = 1;
            wnd.*.VScrollBox = 1;
            df.ClearTextPointers(wnd);
        },
        df.ADDTEXT => {
            const pp:usize = @intCast(p1);
            const rtn = df.AddTextMsg(wnd, @ptrFromInt(pp));
            return @intCast(rtn);
        },
        df.DELETETEXT => {
            df.DeleteTextMsg(wnd, @intCast(p1));
            return df.TRUE;
        },
        df.INSERTTEXT => {
            const pp1:usize = @intCast(p1);
            df.InsertTextMsg(wnd, @ptrFromInt(pp1), @intCast(p2));
            return df.TRUE;
        },
        df.SETTEXT => {
            const pp1:usize = @intCast(p1);
            const txt:[*c]u8 = @ptrFromInt(pp1);
            const len = df.strlen(txt);
            SetTextMsg(win, txt[0..len]);
            return df.TRUE;
        },
        df.CLEARTEXT => {
            ClearTextMsg(win);
        },
        df.KEYBOARD => {
            if ((df.WindowMoving == 0) and (df.WindowSizing == 0)) {
                if (KeyboardMsg(win, p1)) {
                    return df.TRUE;
                }
            }
        },
        df.LEFT_BUTTON => {
            if ((df.WindowMoving > 0) or (df.WindowSizing > 0)) {
                return df.FALSE;
            }
            if (LeftButtonMsg(win, p1, p2)) {
                return df.TRUE;
            }
        },
        df.MOUSE_MOVED => {
            if (MouseMovedMsg(win, p1, p2)) {
                return df.TRUE;
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
//        case SCROLLPAGE:
//            ScrollPageMsg(wnd, p1);
//            return TRUE;
//        case HORIZPAGE:
//            HorizScrollPageMsg(wnd, p1);
//            return TRUE;
//        case SCROLLDOC:
//            ScrollDocMsg(wnd, p1);
//            return TRUE;
//        case PAINT:
//            if (isVisible(wnd))    {
//                PaintMsg(wnd, p1, p2);
//                return FALSE;
//            }
//            break;
//        case CLOSE_WINDOW:
//            CloseWindowMsg(wnd);
//            break;
        else => {
            return df.cTextBoxProc(wnd, msg, p1, p2);
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
