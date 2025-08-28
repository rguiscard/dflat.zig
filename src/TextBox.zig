const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

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
//        case LEFT_BUTTON:
//            if (WindowSizing || WindowMoving)
//                return FALSE;
//            if (LeftButtonMsg(wnd, p1, p2))
//                return TRUE;
//            break;
//        case MOUSE_MOVED:
//            if (MouseMovedMsg(wnd, p1, p2))
//                return TRUE;
//            break;
//        case BUTTON_RELEASED:
//            ButtonReleasedMsg(wnd);
//            break;
//        case SCROLL:
//            return ScrollMsg(wnd, p1);
//        case HORIZSCROLL:
//            return HorizScrollMsg(wnd, p1);
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
