const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const k = @import("Classes.zig").CLASS;
const editbox = @import("EditBox.zig");
const textbox = @import("TextBox.zig");
const normal = @import("Normal.zig");
const GapBuffer = @import("GapBuffer.zig");
const cfg = @import("Config.zig");

const VOID = q.VOID;

const pTab:u16 = '\t' + 0x80;
const sTab:u16 = 0x0C + 0x80; // '\f'

// ---------- SETTEXT Message ------------
fn SetTextMsg(win:*Window,p1:[]const u8) bool {
    const src:[*c]u8 = @constCast(p1.ptr);
    var idx:usize = 0; // source
    var x:usize = 0;   // per line
    const tabs:usize = cfg.config.Tabs;

    var buf:*GapBuffer = undefined;
    if (GapBuffer.init(root.global_allocator, 10)) |b| {
        buf = b;
    } else |_| {
        // error
        return false;
    }
    defer buf.deinit();

    buf.moveCursor(0);
    while(true) {
        if (src[idx] == 0)
            break;
        // --- put the character (\t, too) into the buffer ---
        x += 1;
        // --- expand tab into subst tab (\f + 0x80)
        //     and expansions (\t + 0x80) --- 
        if (src[idx] == '\t') {
            if (buf.insert(sTab)) {} else |_| {} // --- substitute tab character ---
            while (@mod(x, tabs) != 0) {
                if (buf.insert(pTab)) {} else |_| {}
                x += 1;
            }
        } else {
            if (buf.insert(src[idx])) {} else |_| {}
            if (src[idx] == '\n') {
                x = 0;
            }
        }
//        if (if (*tp == '\t') {
//            *ttp++ = sTab;  /* --- substitute tab character --- */
//            while ((x % cfg.Tabs) != 0) {
//                *ttp++ = pTab, x++;
//            }
//        } else {
//            *ttp++ = *tp;
//            if (*tp == '\n')
//                x = 0;
//        }
//        tp++;
   
        idx += 1;
    }
    // if (buf.insert(0)) {} else |_| {} // gapbuf insert 0 actually
    //  *ttp = '\0';

    return root.BaseWndProc(k.EDITOR, win, df.SETTEXT, .{.slice=buf.toString()});
//    return if (df.cSetTextMsg(wnd, @ptrFromInt(pp)) == df.TRUE) true else false;
}

// --------- KEYBOARD Message ----------
fn KeyboardMsg(win:*Window,p1:u16, p2:u8) bool {
    if (normal.WindowMoving or normal.WindowSizing or ((p2 & df.ALTKEY)>0))
        return false;

    var pn:u16 = p1;
    switch (p1) {
        df.PGUP,
        df.PGDN,
        df.UP,
        df.DN => {
            pn = df.BS;
            // fall through
            _ = root.BaseWndProc(k.EDITOR, win, df.KEYBOARD, .{.char=.{p1, p2}});
            TurnOffDisplay(win);
//            while (*df.CurrChar == pTab) {
//            while (df.zCurrChar(wnd)[0] == pTab) {
            while (win.text[win.currPos()] == pTab) {
                _ = root.BaseWndProc(k.EDITOR, win, df.KEYBOARD, .{.char=.{pn, p2}});
            }
            TurnOnDisplay(win);
            return true;
        },
        df.FWD,
        df.BS => {
            _ = root.BaseWndProc(k.EDITOR, win, df.KEYBOARD, .{.char=.{p1, p2}});
            TurnOffDisplay(win);
//            while (*df.CurrChar == pTab) {
//            while (df.zCurrChar(wnd)[0] == pTab) {
            while (win.text[win.currPos()] == pTab) {
                _ = root.BaseWndProc(k.EDITOR, win, df.KEYBOARD, .{.char=.{pn, p2}});
            }
            TurnOnDisplay(win);
            return true;
        },
        df.DEL => {
            TurnOffDisplay(win);
//            const delnl = (*df.CurrChar == '\n' or df.TextBlockMarked(wnd));
//            const delnl = (df.zCurrChar(wnd)[0] == '\n' or textbox.TextBlockMarked(win));
            const delnl = (win.text[win.currPos()] == '\n' or textbox.TextBlockMarked(win));
            _ = root.BaseWndProc(k.EDITOR, win, df.KEYBOARD, .{.char=.{p1, p2}});
//            while (*df.CurrChar == pTab) {
//            while (df.zCurrChar(wnd)[0] == pTab) {
            while (win.text[win.currPos()] == pTab) {
                _ = root.BaseWndProc(k.EDITOR, win, df.KEYBOARD, .{.char=.{p1, p2}});
            }
            AdjustTab(win);
            TurnOnDisplay(win);
            RepaintLine(win);
            if (delnl) {
                _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            }
            return true;
        },
        '\t' => {
            TurnOffDisplay(win);
            _ = root.BaseWndProc(k.EDITOR, win, df.KEYBOARD, .{.char=.{sTab, p2}});
            const tabs:usize = @intCast(cfg.config.Tabs);
            while (@rem(win.CurrCol, tabs) != 0) {
                _ = root.BaseWndProc(k.EDITOR, win, df.KEYBOARD, .{.char=.{pTab, p2}});
            }
            TurnOnDisplay(win);
            RepaintLine(win);
            return true;
        },
        else => {
//            if ( ((p1 & ~0x7F) == 0) and           // FIXME unicode
//                                (df.isprint(p1) or p1 == '\r')) {
            if ( (p1 < 128) and           // FIXME unicode
                                (std.ascii.isPrint(@intCast(p1)) or p1 == '\r')) {
                TurnOffDisplay(win);
                _ = root.BaseWndProc(k.EDITOR, win, df.KEYBOARD, .{.char=.{p1, p2}});
                AdjustTab(win);
                TurnOnDisplay(win);
                RepaintLine(win);
                if (p1 == '\r') {
                    _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
                }
                return true;
            }
        }
    }
    return false;
}

// not in use
//void CollapseTabs(WINDOW wnd)
//{
//        unsigned char *cp = wnd->text, *cp2;
//        while (*cp)     {
//                if (*cp == sTab)        {
//                        *cp = '\t';
//                        cp2 = cp;
//                        while (*++cp2 == pTab)
//                                ;
//                        memmove(cp+1, cp2, strlen(cp2)+1);
//                }
//                cp++;
//        }
//}

// not in use
//void ExpandTabs(WINDOW wnd)
//{
//        int Holdwtop = wnd->wtop;
//        int Holdwleft = wnd->wleft;
//        int HoldRow = wnd->CurrLine;
//        int HoldCol = wnd->CurrCol;
//        int HoldwRow = wnd->WndRow;
//        SendMessage(wnd, SETTEXT, (PARAM) wnd->text, 0);
//        wnd->wtop = Holdwtop;
//        wnd->wleft = Holdwleft;
//        wnd->CurrLine = HoldRow;
//        wnd->CurrCol = HoldCol;
//        wnd->WndRow = HoldwRow;
//        SendMessage(wnd, PAINT, 0, 0);
//        SendMessage(wnd, KEYBOARD_CURSOR, 0, wnd->WndRow);
//}

// --- When inserting or deleting, adjust next following tab, same line ---
//  not sure it work properly
fn AdjustTab(win:*Window) void {
    // turn visibility off when use this function
    // ---- test if there is a tab beyond this character ---- 
    var col = win.CurrCol;
    var curr_pos = win.currPos();
    var cc = win.text[curr_pos];
    while ((curr_pos < win.textlen) and (cc != '\n')) {
        if (cc == sTab) {
            const tabs:usize = @intCast(cfg.config.Tabs);
            var exp = (tabs-1) - @mod(col, tabs);
            col += 1;
            curr_pos += 1;
            cc = win.text[curr_pos];
            while (cc == pTab) {
                _ = root.BaseWndProc(k.EDITOR, win, df.KEYBOARD, .{.char=.{df.DEL, 0}});
            }
            while (exp > 0) {
                exp -= 1;
                _ = root.BaseWndProc(k.EDITOR, win, df.KEYBOARD, .{.char=.{pTab, 0}});
            }
            break;
        }
        col += 1;
        curr_pos += 1;
        cc = win.text[curr_pos];
    }
//    while (*CurrChar && *CurrChar != '\n')    {
//                if (*CurrChar == sTab)  {
//                        int exp = (cfg.Tabs - 1) - (wnd->CurrCol % cfg.Tabs);
//                wnd->CurrCol++;
//                        while (*CurrChar == pTab)
//                                BaseWndProc(EDITOR, wnd, KEYBOARD, DEL, 0);
//                        while (exp--)
//                                BaseWndProc(EDITOR, wnd, KEYBOARD, pTab, 0);
//                        break;
//                }
//        wnd->CurrCol++;
//    }

//    wnd.*.CurrCol = col; // we do not change CurrCol 
}

// ------- Window processing module for EDITBOX class ------ 
pub fn EditorProc(win:*Window, msg:df.MESSAGE, params:q.Params) bool {
    switch (msg) {
        df.KEYBOARD => {
            const p1 = params.char[0];
            const p2 = params.char[1];
            if (KeyboardMsg(win, p1, p2))
                return true;
        },
        df.SETTEXT => {
            return SetTextMsg(win, params.slice);
        },
        else => {
        }
    }
    return root.BaseWndProc(k.EDITOR, win, msg, params);
}

fn TurnOffDisplay(win:*Window) void {
    _ = q.SendMessage(null, df.HIDE_CURSOR, q.none);
    win.ClearVisible();
}

fn TurnOnDisplay(win:*Window) void {
    win.SetVisible();
    _ = q.SendMessage(null, df.SHOW_CURSOR, .{.yes=false});
}

fn RepaintLine(win:*Window) void {
    _ = win.sendMessage(df.KEYBOARD_CURSOR,
                        .{.position=.{@intCast(editbox.WndCol(win)), win.WndRow}});
    textbox.WriteTextLine(win, null, win.CurrLine, false);
}

// for editbox.c
//pub export fn GetCurrChar(wnd:df.WINDOW) [*c]u8 {
//    if (Window.get_zin(wnd)) |win| {
//        const pos = win.currPos();
//        if (pos < win.textlen) {
//            return wnd.*.text+pos;
//        }
//    }
//    return 0;
//}
//
//pub export fn GetCurrLine(wnd:df.WINDOW) c_int {
//    if (Window.get_zin(wnd)) |win| {
//        return @intCast(win.CurrLine);
//    }
//    return 0;
//}
//
//pub export fn SetCurrLine(wnd:df.WINDOW, line:c_int) void {
//    if (Window.get_zin(wnd)) |win| {
//        win.CurrLine = @intCast(line);
//    }
//}
//
//pub export fn GetCurrCol(wnd:df.WINDOW) c_int {
//    if (Window.get_zin(wnd)) |win| {
//        return @intCast(win.CurrCol);
//    }
//    return 0;
//}
//
//pub export fn SetCurrCol(wnd:df.WINDOW, col:c_int) void {
//    if (Window.get_zin(wnd)) |win| {
//        win.CurrCol = @intCast(col);
//    }
//}
