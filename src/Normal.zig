const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const lists = @import("Lists.zig");
const rect = @import("Rect.zig");

var dummyWnd:?Window = null;

fn getDummy() df.WINDOW {
    if(dummyWnd == null) {
        dummyWnd = Window.init(&df.dwnd, root.global_allocator);
        df.dwnd.zin = @ptrCast(@alignCast(&dummyWnd.?));
        Window.set_NormalProc(&df.dwnd); // doesn't seem necessary

//        dummyWnd = Window.create(df.DUMMY, null, -1, -1, -1, -1, null, null, NormalProc, 0);
    }
    const wnd = dummyWnd.?.win;
    return wnd;
}

// --------- CREATE_WINDOW Message ----------
fn CreateWindowMsg(win:*Window) void {
    const wnd = win.win;
    lists.AppendWindow(wnd);
    const rtn = df.SendMessage(null, df.MOUSE_INSTALLED, 0, 0);
    if (rtn == 0) {
        win.ClearAttribute(df.VSCROLLBAR | df.HSCROLLBAR);
    }
    if (win.TestAttribute(df.SAVESELF) and df.isVisible(wnd)>0) {
        df.GetVideoBuffer(wnd);
    }
}

// --------- SHOW_WINDOW Message ----------
fn ShowWindowMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    if (Window.GetParent(wnd) == null or df.isVisible(Window.GetParent(wnd))>0) {
        if (win.TestAttribute(df.SAVESELF) and
                        (wnd.*.videosave == null)) {
            df.GetVideoBuffer(wnd);
        }
        win.SetVisible();

        _ = win.sendMessage(df.PAINT, 0, df.TRUE);
        _ = win.sendMessage(df.BORDER, 0, 0);
        // --- show the children of this window ---
        var cwnd = Window.FirstWindow(wnd);
        while (cwnd) |cw| {
            if (cw.*.condition != df.ISCLOSING) {
                _ = df.SendMessage(cw, df.SHOW_WINDOW, p1, p2);
            }
            cwnd = Window.NextWindow(cw);
        }
    }
}

// --------- HIDE_WINDOW Message ----------
fn HideWindowMsg(win:*Window) void {
    const wnd = win.win;
    if (df.isVisible(wnd)>0) {
        win.ClearVisible();
        // --- paint what this window covered ---
        if (win.TestAttribute(df.SAVESELF)) {
            df.PutVideoBuffer(wnd);
        } else {
            df.PaintOverLappers(wnd);
        }
        wnd.*.wasCleared = df.FALSE;
    }
}

// ----- test if screen coordinates are in a window ----
fn InsideWindow(win:*Window, x:c_int, y:c_int) c_int {
    const wnd = win.win;
    var rc = df.WindowRect(wnd);
    if (win.TestAttribute(df.NOCLIP))    {
        var pwnd = Window.GetParent(wnd);
        while (pwnd != null) {
            rc = df.subRectangle(rc, df.ClientRect(pwnd));
            pwnd = Window.GetParent(pwnd);
        }
    }
    if (rect.InsideRect(x, y, rc)) {
        return df.TRUE;
    }
    return df.FALSE;
}

// --------- KEYBOARD Message ----------
fn KeyboardMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    const dwnd = getDummy();
    if ((df.WindowMoving>0) or (df.WindowSizing>0)) {
        // -- move or size a window with keyboard --
        var x = if (df.WindowMoving>0) df.GetLeft(dwnd) else df.GetRight(dwnd);
        var y = if (df.WindowMoving>0) df.GetTop(dwnd) else df.GetBottom(dwnd);
        switch (p1)    {
            df.ESC => {
                df.TerminateMoveSize();
                return true;
            },
            df.UP => {
                if (y>0)
                    y -= 1;
            },
            df.DN => {
                if (y < df.SCREENHEIGHT-1)
                    y += 1;
            },
            df.FWD => {
                if (x < df.SCREENWIDTH-1)
                    x += 1;
            },
            df.BS => {
                if (x>0)
                    x -= 1;
            },
            '\r' => {
                _ = win.sendMessage(df.BUTTON_RELEASED,x,y);
            },
            else => {
                return true;
            }
        }
        _ = df.SendMessage(wnd, df.MOUSE_CURSOR, x, y);
        _ = df.SendMessage(wnd, df.MOUSE_MOVED, x, y);
        return true;
    }
    switch (p1) {
        df.F1 => {
            _ = win.sendMessage(df.COMMAND, df.ID_HELP, 0);
            return true;
        },
        ' ' => {
            const p2_i:isize = p2;
            if ((p2_i & df.ALTKEY) > 0) {
                if (win.TestAttribute(df.HASTITLEBAR)) {
                    if (win.TestAttribute(df.CONTROLBOX)) {
                        df.BuildSystemMenu(wnd);
                    }
                }
            }
            return true;
        },
        df.CTRL_F4 => {
            if (win.TestAttribute(df.CONTROLBOX)) {
                _ = win.sendMessage(df.CLOSE_WINDOW, 0, 0);
                df.SkipApplicationControls();
                return true;
            }
        },
        else => {
        }
    }
    return false;
}

pub fn NormalProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            CreateWindowMsg(win);
        },
        df.SHOW_WINDOW => {
            ShowWindowMsg(win, p1, p2);
        },
        df.HIDE_WINDOW => {
            HideWindowMsg(win);
        },
        df.INSIDE_WINDOW => {
            return InsideWindow(win, @intCast(p1), @intCast(p2));
        },
        df.KEYBOARD => {
            if (KeyboardMsg(win, p1, p2))
                return df.TRUE;
            // ------- fall through -------
            if (Window.GetParent(wnd) != null)
                df.PostMessage(Window.GetParent(wnd), msg, p1, p2);
        },
        df.ADDSTATUS, df.SHIFT_CHANGED => {
            if (Window.GetParent(wnd) != null)
                df.PostMessage(Window.GetParent(wnd), msg, p1, p2);
        },
//        df.PAINT => {
//            if (df.isVisible(wnd)>0) {
//                if (wnd.*.wasCleared > 0) {
//                    df.PaintUnderLappers(wnd);
//                } else {
//                    wnd.*.wasCleared = df.TRUE;
//
//                    var pp1:?*df.RECT = null;
//                    if (p1>0) {
//                        const p1_addr:usize = @intCast(p1);
//                        pp1 = @ptrFromInt(p1_addr);
//                    }
//
//                    df.ClearWindow(wnd, pp1, ' ');
//                }
//            }
//        },
//        df.BORDER => {
//            if (df.isVisible(wnd)>0) {
//                var pp1:?*df.RECT = null;
//                if (p1>0) {
//                    const p1_addr:usize = @intCast(p1);
//                    pp1 = @ptrFromInt(p1_addr);
//                }
//
//                if (df.TestAttribute(wnd, df.HASBORDER)>0) {
//                    df.RepaintBorder(wnd, pp1);
//                } else if (df.TestAttribute(wnd, df.HASTITLEBAR)>0) {
//                    df.DisplayTitle(wnd, pp1);
//                }
//            }
//        },
//        df.COMMAND => {
//            CommandMsg(wnd, p1);
//        },
//        df.SETFOCUS => {
//            df.SetFocusMsg(wnd, p1);
//        },
//        df.DOUBLE_CLICK => {
//            DoubleClickMsg(wnd, p1, p2);
//        },
//        df.LEFT_BUTTON => {
//            LeftButtonMsg(wnd, p1, p2);
//        },
//        df.MOUSE_MOVED => {
//            if (MouseMovedMsg(wnd, p1, p2)) {
//                return df.TRUE;
//            }
//        },
//        df.BUTTON_RELEASED => {
//            if ((df.WindowMoving>0) or (df.WindowSizing>0)) {
//                const dwnd = getDummy();
//                if (df.WindowMoving > 0) {
//                    df.PostMessage(wnd,df.MOVE,dwnd.*.rc.lf,dwnd.*.rc.tp);
//                } else {
//                    df.PostMessage(wnd,df.SIZE,dwnd.*.rc.rt,dwnd.*.rc.bt);
//                }
//                TerminateMoveSize(dwnd);
//            }
//        },
//        df.MOVE => {
//            MoveMsg(wnd, p1, p2);
//        },
//        df.SIZE => {
//            SizeMsg(wnd, p1, p2);
//        },
//        df.CLOSE_WINDOW => {
//            CloseWindowMsg(wnd);
//        },
//        case MAXIMIZE:
//            if (wnd->condition != ISMAXIMIZED)
//                MaximizeMsg(wnd);
//            break;
//        case MINIMIZE:
//            if (wnd->condition != ISMINIMIZED)
//                MinimizeMsg(wnd);
//            break;
//        case RESTORE:
//            if (wnd->condition != ISRESTORED)    {
//                if (wnd->oldcondition == ISMAXIMIZED)
//                    SendMessage(wnd, MAXIMIZE, 0, 0);
//                else
//                    RestoreMsg(wnd);
//            }
//            break;
//        df.DISPLAY_HELP => {
//            const p1_addr:usize = @intCast(p1);
//            const pp1:[*c]u8 = @ptrFromInt(p1_addr);
//            return helpbox.DisplayHelp(wnd, std.mem.span(pp1));
//        },
        else => {
            return df.cNormalProc(wnd, msg, p1, p2);
        }
    }
    return df.TRUE;
}
