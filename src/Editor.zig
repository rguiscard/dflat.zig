const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const editbox = @import("EditBox.zig");
const normal = @import("Normal.zig");

const pTab = '\t' + 0x80;
const sTab = 0x0C + 0x80; // '\f'

// ---------- SETTEXT Message ------------
fn SetTextMsg(win:*Window,p1:df.PARAM) bool {
    const wnd = win.win;
    const pp:usize = @intCast(p1);
    return if (df.cSetTextMsg(wnd, @ptrFromInt(pp)) == df.TRUE) true else false;
}

// --------- KEYBOARD Message ----------
fn KeyboardMsg(win:*Window,p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;

    var pn:df.PARAM = p1;
    if (normal.WindowMoving or normal.WindowSizing or ((p2 & df.ALTKEY)>0))
        return false;

    switch (p1) {
        df.PGUP,
        df.PGDN,
        df.UP,
        df.DN => {
            pn = df.BS;
            // fall through
            _ = root.zBaseWndProc(df.EDITOR, win, df.KEYBOARD, p1, p2);
            TurnOffDisplay(win);
//            while (*df.CurrChar == pTab) {
            while (df.zCurrChar(wnd)[0] == pTab) {
                _ = root.zBaseWndProc(df.EDITOR, win, df.KEYBOARD, pn, p2);
            }
            TurnOnDisplay(win);
            return true;
        },
        df.FWD,
        df.BS => {
            _ = root.zBaseWndProc(df.EDITOR, win, df.KEYBOARD, p1, p2);
            TurnOffDisplay(win);
//            while (*df.CurrChar == pTab) {
            while (df.zCurrChar(wnd)[0] == pTab) {
                _ = root.zBaseWndProc(df.EDITOR, win, df.KEYBOARD, pn, p2);
            }
            TurnOnDisplay(win);
            return true;
        },
        df.DEL => {
            TurnOffDisplay(win);
//            const delnl = (*df.CurrChar == '\n' or df.TextBlockMarked(wnd));
            const delnl = (df.zCurrChar(wnd)[0] == '\n' or df.TextBlockMarked(wnd));
            _ = root.zBaseWndProc(df.EDITOR, win, df.KEYBOARD, p1, p2);
//            while (*df.CurrChar == pTab) {
            while (df.zCurrChar(wnd)[0] == pTab) {
                _ = root.zBaseWndProc(df.EDITOR, win, df.KEYBOARD, p1, p2);
            }
            df.AdjustTab(wnd);
            TurnOnDisplay(win);
            RepaintLine(win);
            if (delnl) {
                _ = win.sendMessage(df.PAINT, 0, 0);
            }
            return true;
        },
        '\t' => {
            TurnOffDisplay(win);
            _ = root.zBaseWndProc(df.EDITOR, win, df.KEYBOARD, @intCast(sTab), p2);
            while (@rem(wnd.*.CurrCol, df.cfg.Tabs) != 0) {
                _ = root.zBaseWndProc(df.EDITOR, win, df.KEYBOARD, @intCast(pTab), p2);
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
                _ = root.zBaseWndProc(df.EDITOR, win, df.KEYBOARD, p1, p2);
                df.AdjustTab(wnd);
                TurnOnDisplay(win);
                RepaintLine(win);
                if (p1 == '\r') {
                    _ = win.sendMessage(df.PAINT, 0, 0);
                }
                return true;
            }
        }
    }
    return false;
}

// ------- Window processing module for EDITBOX class ------ 
pub fn EditorProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    switch (msg) {
        df.KEYBOARD => {
            if (KeyboardMsg(win, p1, p2))
                return true;
        },
        df.SETTEXT => {
            return SetTextMsg(win, p1);
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.EDITOR, win, msg, p1, p2);
}

fn TurnOffDisplay(win:*Window) void {
    _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
    win.ClearVisible();
}

fn TurnOnDisplay(win:*Window) void {
    win.SetVisible();
    _ = q.SendMessage(null, df.SHOW_CURSOR, 0, 0);
}

fn RepaintLine(win:*Window) void {
    const wnd = win.win;
    _ = win.sendMessage(df.KEYBOARD_CURSOR, editbox.WndCol(win), @intCast(wnd.*.WndRow));
    df.WriteTextLine(wnd, null, wnd.*.CurrLine, df.FALSE);
}
