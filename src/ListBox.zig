const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const k = @import("Classes.zig").CLASS;
const rect = @import("Rect.zig");
const normal = @import("Normal.zig");
const textbox = @import("TextBox.zig");

var py:?usize = null;    // the previous y mouse coordinate

// --------- SHIFT_F8 Key ------------
fn AddModeKey(win:*Window) void {
    if (win.isMultiLine())    {
        win.AddMode ^= true;
        // parent could be null ?
        if (win.parent) |pw| {
            const t:[]const u8 = if (win.AddMode) "Add Mode" else "";
            _ = pw.sendTextMessage(df.ADDSTATUS, t);
//        } else {
//            _ = q.SendMessage(null, df.ADDSTATUS, .{.legacy=.{p1, 0}});
        }
    }
}

// --------- UP (Up Arrow) Key ------------
fn UpKey(win:*Window,p2:u8) void {
    const wnd = win.win;
    if (win.selection) |selection| {
        if (selection > 0) {
            if (selection == win.wtop) {
                _ = root.BaseWndProc(k.LISTBOX, win, df.KEYBOARD, .{.char=.{df.UP, p2}});
                q.PostMessage(win, df.LB_SELECTION, .{.select=.{selection-1,
                    if (win.isMultiLine()) p2 else 0}});
            } else {
                var newsel:usize = selection-1;
                if (win.wlines == win.ClientHeight()) {
                      var last = win.textLine(newsel);
                      while(wnd.*.text[last] == df.LINE) {
                          // Not sure this is really work.
                          newsel -|= 1; // check boundary ?
                          last = win.textLine(@intCast(newsel));
                      }
//                      var last = df.TextLine(wnd, newsel);
//                      while(last[0] == df.LINE) {
//                          // Not sure this is really work.
//                          newsel -= 1;
//                          last = df.TextLine(wnd, newsel);
//                      }
//                    while (*TextLine(wnd, newsel) == LINE)
//                        --newsel;
                }
                q.PostMessage(win, df.LB_SELECTION, .{.select=.{newsel,
                    if (win.isMultiLine()) p2 else 0}}); // EXTENDEDSELECTIONS
            }
        }
    }
}

// --------- DN (Down Arrow) Key ------------
fn DnKey(win:*Window, p2:u8) void {
    const wnd = win.win;
    if (win.selection) |selection| {
        if (selection < win.wlines-1) {
            if (selection == win.wtop+win.ClientHeight()-1) {
                _ = root.BaseWndProc(k.LISTBOX, win, df.KEYBOARD, .{.char=.{df.DN, p2}});
                q.PostMessage(win, df.LB_SELECTION, .{.select=.{selection+1,
                    if (win.isMultiLine()) p2 else 0}});
            } else {
                var newsel:usize = selection+1;
                if (win.wlines == win.ClientHeight()) {
                      var last = win.textLine(@intCast(newsel));
                      while(wnd.*.text[last] == df.LINE) {
                          // Not sure this is really work.
                          newsel +|= 1; // check boundary ?
                          last = win.textLine(newsel);
                      }
//                      var last = df.TextLine(wnd, newsel);
//                      while(last[0] == df.LINE) {
//                          // Not sure this is really work.
//                          newsel += 1;
//                          last = df.TextLine(wnd, newsel);
//                      }
//                    while (*TextLine(wnd, newsel) == LINE)
//                        newsel++;
                }
                q.PostMessage(win, df.LB_SELECTION, .{.select=.{newsel,
                    if (win.isMultiLine()) p2 else 0}});  // EXTENDEDSELECTIONS
            }
        }
    }
}

// --------- HOME and PGUP Keys ------------
fn HomePgUpKey(win:*Window, p1:u16, p2:u8) void {
    _ = root.BaseWndProc(k.LISTBOX, win, df.KEYBOARD, .{.char=.{p1, p2}});
    q.PostMessage(win, df.LB_SELECTION, .{.select=.{win.wtop,
        if (win.isMultiLine()) p2 else 0}});  // EXTENDEDSELECTIONS
}

// --------- END and PGDN Keys ------------
fn EndPgDnKey(win:*Window, p1:u16, p2:u8) void {
    _ = root.BaseWndProc(k.LISTBOX, win, df.KEYBOARD, .{.char=.{p1, p2}});
    var bot:usize = win.wtop+win.ClientHeight()-1;
    if (bot > win.wlines-1)
        bot = win.wlines-1;
    q.PostMessage(win, df.LB_SELECTION, .{.select=.{bot,
        if (win.isMultiLine()) p2 else 0}});  // EXTENDEDSELECTIONS
}

// --------- Space Bar Key ------------ 
fn SpacebarKey(win:*Window, p2:u8) void {
    if (win.isMultiLine()) {
        var sel:?usize = null;
        _ = win.sendMessage(df.LB_CURRENTSELECTION, .{.usize_addr=&sel});
        if (sel) |selection| {
            if (win.AddMode) {
                FlipSelection(win, selection);
            }
            if (ItemSelected(win, selection)) {
                const p2n = p2 & (df.LEFTSHIFT | df.RIGHTSHIFT);
                if (p2n == 0) {
                    win.AnchorPoint = @intCast(selection);
                }
                _ = ExtendSelections(win, selection, p2);
            } else {
                win.AnchorPoint = -1;
            }
            _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
        }
    }
}

// --------- Enter ('\r') Key ------------
fn EnterKey(win:*Window) void {
    if (win.selection) |selection| {
        _ = win.sendMessage(df.LB_SELECTION, .{.select=.{selection, 1}});
        _ = win.sendMessage(df.LB_CHOOSE, .{.select=.{selection, 0}});
    }
}

// --------- All Other Key Presses ------------
fn KeyPress(win:*Window,p1:u16, p2:u8) void {
    const wnd = win.win;
    var sel:usize = if (win.selection) |selection| selection+1 else 0;
    while (sel < win.wlines) {
//        var cp = df.TextLine(wnd, sel);
//        if (cp == null)
//            break;
//        if (win.isMultiLine())
//            cp += 1;
//
//        const first = cp[0];
        var pos = win.textLine(sel);
        if (pos >= wnd.*.textlen)
            break;
        if (win.isMultiLine())
            pos += 1;
        const first = wnd.*.text[pos];
        if ((first < 256) and (std.ascii.toLower(first) == p1)) {
            _ = win.sendMessage(df.LB_SELECTION, .{.select=.{sel,
                if (win.isMultiLine()) p2 else 0}});
            if (SelectionInWindow(win, sel) == false) {
                const x:usize = win.ClientHeight();
                win.wtop = 0;
                if (sel > x-1) {
                    win.wtop = @as(usize, @intCast(sel))-(x-1);
                }
                _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
            }
            break;
        }
//        if (tolower(*cp) == (int)p1)    {
//            SendMessage(wnd, LB_SELECTION, sel,
//                isMultiLine(wnd) ? p2 : FALSE);
//            if (!SelectionInWindow(wnd, sel))    {
//                wnd->wtop = sel-ClientHeight(wnd)+1;
//                SendMessage(wnd, PAINT, 0, 0);
//            }
//            break;
//        }
        sel += 1;
    }
}

// --------- KEYBOARD Message ------------
fn KeyboardMsg(win:*Window, p1:u16, p2:u8) bool {
    switch (p1) {
        df.SHIFT_F8 => {
            AddModeKey(win);
            return true;
        },
        df.UP => {
            TestExtended(win, p2);
            UpKey(win, p2);
            return true;
        },
        df.DN => {
            TestExtended(win, p2);
            DnKey(win, p2);
            return true;
        },
        df.PGUP,
        df.HOME => {
            TestExtended(win, p2);
            HomePgUpKey(win, p1, p2);
            return true;
        },
        df.PGDN,
        df.END => {
            TestExtended(win, p2);
            EndPgDnKey(win, p1, p2);
            return true;
        },
        ' ' => {
            SpacebarKey(win, p2);
        },
        '\r' => {
            EnterKey(win);
            return true;
        },
        else => {
            KeyPress(win, p1, p2);
        }
    }
    return false;
}

// ------- LEFT_BUTTON Message --------
fn LeftButtonMsg(win:*Window, x:usize, y:usize) bool {
    var my:usize = if (y > win.GetTop()) y - win.GetTop() else 0;
    if (my >= win.wlines-win.wtop)
        my = win.wlines - win.wtop;

    if (rect.InsideRect(@intCast(x), @intCast(y), rect.ClientRect(win)) == false) {
        return false;
    }
    if ((win.wlines > 0) and (if (py) |ysel| my != ysel else true)) {
        const sel = win.wtop+my-1;

//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        int sh = getshift();
//        if (!(sh & (LEFTSHIFT | RIGHTSHIFT)))    {
//            if (!(sh & CTRLKEY))
//                ClearAllSelections(wnd);
//            win.AnchorPoint = sel;
//            SendMessage(wnd, PAINT, 0, 0);
//        }
//#endif

        _ = win.sendMessage(df.LB_SELECTION, .{.select=.{sel, 1}});
        py = my;
    }
    return true;
}

// ------------- DOUBLE_CLICK Message ------------
fn DoubleClickMsg(win:*Window, x:usize, y:usize) bool {
    if (normal.WindowMoving or normal.WindowSizing)
        return false;
    if (win.wlines>0) {
        _ = root.BaseWndProc(k.LISTBOX, win, df.DOUBLE_CLICK, .{.position=.{x, y}});
        if (rect.InsideRect(@intCast(x), @intCast(y), rect.ClientRect(win)))
            _ = win.sendMessage(df.LB_CHOOSE, .{.select=.{win.selection, 0}});
    }
    return true;
}

// ------------ ADDTEXT Message --------------
fn AddTextMsg(win:*Window,p1:[]const u8) bool {
    const rtn = root.BaseWndProc(k.LISTBOX, win, df.ADDTEXT, .{.slice=p1});
    if (win.selection == null)
        _ = win.sendMessage(df.LB_SETSELECTION, .{.select=.{0, 0}});
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//    if (*(char *)p1 == LISTSELECTOR)
//        win.SelectCount += 1;
//#endif
    return rtn;
}

// --------- GETTEXT Message ------------
fn GetTextMsg(win:*Window, p1:[]u8, p2:usize) void {
    const wnd = win.win;
    const cp2 = win.textLine(p2);
    if (std.mem.indexOfAnyPos(u8, wnd.*.text[0..wnd.*.textlen], cp2, &[_]u8{0, '\n'})) |pos| {
        const len = pos-cp2;
        @memmove(p1[0..len], wnd.*.text[cp2..pos]);
        p1[len] = 0;
    }
}

pub fn ListBoxProc(win:*Window, msg:df.MESSAGE, params:q.Params) bool {
    switch (msg) {
        df.CREATE_WINDOW => {
            _ = root.BaseWndProc(k.LISTBOX, win, msg, params);
            win.selection = null;
            win.AnchorPoint = -1;
            return true;
        },
        df.KEYBOARD => {
            const p1 = params.char[0];
            const p2 = params.char[1];
            if ((normal.WindowMoving == false) and (normal.WindowSizing == false)) {
                if (KeyboardMsg(win, p1, p2))
                    return true;
            }
        },
        df.LEFT_BUTTON => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            if (LeftButtonMsg(win, p1, p2))
                return true;
        },
        df.DOUBLE_CLICK => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            if (DoubleClickMsg(win, p1, p2))
                return true;
        },
        df.BUTTON_RELEASED => {
            if (normal.WindowMoving or normal.WindowSizing or textbox.VSliding) {
            } else {
                py = null;
                return true;
            }
        },
        df.ADDTEXT => {
            return AddTextMsg(win, params.slice);
        },
        df.LB_GETTEXT => {
            const p1:[]u8 = params.get_text[0];
            const p2:usize = params.get_text[1];
            GetTextMsg(win, p1, p2);
            return true;
        },
        df.CLEARTEXT => {
            win.selection = null;
            win.AnchorPoint = -1;
            win.SelectCount = 0;
        },
        df.PAINT => {
            const p1:?df.RECT = params.paint[0];
            _ = root.BaseWndProc(k.LISTBOX, win, msg, params);
            if (win.selection) |selection| {
                if (p1) |rc| {
                    WriteSelection(win, selection, true, rc);
                } else {
                    WriteSelection(win, selection, true, null);
                }
            }
            return true;
        },
        df.SETFOCUS => {
            _ = root.BaseWndProc(k.LISTBOX, win, msg, params);
            if (params.yes) {
                if (win.selection) |selection| {
                    WriteSelection(win, selection, true, null);
                }
            }
            return true;
        },
        df.SCROLL,
        df.HORIZSCROLL,
        df.SCROLLPAGE,
        df.HORIZPAGE,
        df.SCROLLDOC => {
            _ = root.BaseWndProc(k.LISTBOX, win, msg, params);
            if (win.selection) |selection| {
                 WriteSelection(win, selection, true, null);
            }
            return true;
        },
        df.LB_CHOOSE => {
            _ = win.getParent().sendMessage(df.LB_CHOOSE, params);
            return true;
        },
        df.LB_SELECTION => {
            const p1:?usize = params.select[0];
            const p2:u8 = params.select[1];
            ChangeSelection(win, p1, p2);
            _ = win.getParent().sendMessage(df.LB_SELECTION, .{.select=.{win.selection, 0}});
            return true;
        },
        df.LB_CURRENTSELECTION => {
            const a:*?usize= params.usize_addr;
            a.* = win.selection;
            return if (win.selection == null) false else true;
        },
        df.LB_SETSELECTION => {
            const p1:?usize = params.select[0];
            ChangeSelection(win, p1, 0);
            return true;
        },
        df.CLOSE_WINDOW => {
            if (win.isMultiLine() and win.AddMode) {
                win.AddMode = false;
                _ = win.getParent().sendTextMessage(df.ADDSTATUS, "");
            }
        },
        else => {
        }
    }
    return root.BaseWndProc(k.LISTBOX, win, msg, params);
}

fn SelectionInWindow(win:*Window, sel:usize) bool {
    return ((win.wlines>0) and (sel >= win.wtop) and
            (sel < win.wtop+win.ClientHeight()));
}

fn WriteSelection(win:*Window, sel:usize, reverse:bool, rc:?df.RECT) void {
    if (win.isVisible()) {
        if (SelectionInWindow(win, sel)) {
            textbox.WriteTextLine(win, rc, sel, reverse);
        }
    }
}

// ----- Test for extended selections in the listbox -----
fn TestExtended(win:*Window, p2:df.PARAM) void {
    const p2n = p2 & (df.LEFTSHIFT | df.RIGHTSHIFT);
    if (win.isMultiLine() and (win.AddMode == false) and p2n == 0) {
        if (win.SelectCount > 1) {
            ClearAllSelections(win);
            _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
        }
    }
}

// ----- Clear selections in the listbox -----
fn ClearAllSelections(win:*Window) void {
    if (win.isMultiLine() and win.SelectCount > 0)    {
        for (0..win.wlines) |idx| {
            ClearSelection(win, @intCast(idx));
        }
//        int sel;
//        for (sel = 0; sel < wnd->wlines; sel++)
//            ClearSelection(wnd, sel);
    }
}

// ----- Invert a selection in the listbox -----
fn FlipSelection(win:*Window, sel:?usize) void {
    if (win.isMultiLine()) {
        if (ItemSelected(win, sel)) {
            ClearSelection(win, sel);
        } else {
            SetSelection(win, sel);
        }
    }
}

fn ExtendSelections(win:*Window, sel:usize, shift:u8) usize {
    if (((shift & (df.LEFTSHIFT | df.RIGHTSHIFT))>0) and
                        win.AnchorPoint >= 0) {
        const anchor:usize = @intCast(win.AnchorPoint);
        const i:usize = @max(sel, anchor);
        const j:usize = @min(sel, anchor);
        const rtn = i-j;

        for (j..i+1) |idx| {
            SetSelection(win, idx);
        }
//        int i = sel;
//        int j = wnd->AnchorPoint;
//        int rtn;
//        if (j > i)
//            swap(i,j);
//        rtn = i - j;
//        while (j <= i)
//            SetSelection(wnd, j++);
        return rtn;
    }
    return 0;
}

fn SetSelection(win:*Window,sel:?usize) void {
    const wnd = win.win;
    if (sel) |selection| {
        if (win.isMultiLine() and (ItemSelected(win, selection) == false)) {
            const lp = win.textLine(selection);
            wnd.*.text[lp] = df.LISTSELECTOR;
            win.SelectCount += 1;
        }
    }
}

fn ClearSelection(win:*Window,sel:?usize) void {
    const wnd = win.win;
    if (sel) |selection| {
        if (win.isMultiLine() and ItemSelected(win, selection)) {
            const lp = win.textLine(selection);
            wnd.*.text[lp] = ' ';
            win.SelectCount -= 1;
        }
    }
}

pub fn ItemSelected(win:*Window,sel:?usize) bool {
    const wnd = win.win;
    if (sel) |selection| {
        if (win.isMultiLine() and selection < win.wlines) {
            const cp = win.textLine(selection);
            return (wnd.*.text[cp] & 255) == df.LISTSELECTOR;
        }
    }
    return false;
}

fn ChangeSelection(win:*Window,sel:?usize,shift:u8) void {
    if (sel != win.selection) {
        if (sel) |selection| {
            if (win.isMultiLine()) {
                if (win.AddMode == false) {
                    ClearAllSelections(win);
                }
                const sels = ExtendSelections(win, selection, shift);
                if (sels > 1) {
                    _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
                }
                if (sels == 0 and win.AddMode == false) {
                    ClearSelection(win, win.selection);
                    SetSelection(win, selection);
                    win.AnchorPoint = @intCast(selection);
                }
            }
        }
        if (win.selection) |selection| { // old selection
            WriteSelection(win, selection, false, null);
        }
        win.selection = sel;
        if (sel) |selection|
            WriteSelection(win, selection, true, null);
    }
}
