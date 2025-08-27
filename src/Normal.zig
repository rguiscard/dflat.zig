const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const lists = @import("Lists.zig");
const rect = @import("Rect.zig");
const Klass = @import("Classes.zig");
const q = @import("Message.zig");

var dummyWnd:?Window = null;
//var px:c_int = -1;
//var py:c_int = -1;
//var diff:c_int = 0;

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
    const rtn = q.SendMessage(null, df.MOUSE_INSTALLED, 0, 0);
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
                _ = q.SendMessage(cw, df.SHOW_WINDOW, p1, p2);
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
                TerminateMoveSize();
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
        _ = q.SendMessage(wnd, df.MOUSE_CURSOR, x, y);
        _ = q.SendMessage(wnd, df.MOUSE_MOVED, x, y);
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
                lists.SkipApplicationControls();
                return true;
            }
        },
        else => {
        }
    }
    return false;
}

// --------- COMMAND Message ----------
fn CommandMsg(win:*Window, p1:df.PARAM) void {
    const wnd = win.win;
    const dwnd = getDummy();
    const dwnd_p2:df.PARAM = @intCast(@intFromPtr(dwnd));
    switch (p1) {
        df.ID_SYSMOVE => {
            _ = win.sendMessage(df.CAPTURE_MOUSE, df.TRUE, dwnd_p2);
            _ = win.sendMessage(df.CAPTURE_KEYBOARD, df.TRUE, dwnd_p2);
            _ = win.sendMessage(df.MOUSE_CURSOR, df.GetLeft(wnd), df.GetTop(wnd));
            df.WindowMoving = df.TRUE;
            df.dragborder(wnd, df.GetLeft(wnd), df.GetTop(wnd));
//            dragborder(wnd, df.GetLeft(wnd), df.GetTop(wnd));
        },
        df.ID_SYSSIZE => {
            _ = win.sendMessage(df.CAPTURE_MOUSE, df.TRUE, dwnd_p2);
            _ = win.sendMessage(df.CAPTURE_KEYBOARD, df.TRUE, dwnd_p2);
            _ = win.sendMessage(df.MOUSE_CURSOR, df.GetRight(wnd), df.GetBottom(wnd));
            df.WindowSizing = df.TRUE;
            df.dragborder(wnd, df.GetLeft(wnd), df.GetTop(wnd));
//            dragborder(wnd, df.GetLeft(wnd), df.GetTop(wnd));
        },
        df.ID_SYSCLOSE => {
            _ = win.sendMessage(df.CLOSE_WINDOW, 0, 0);
            lists.SkipApplicationControls();
        },
        df.ID_SYSRESTORE => {
            _ = win.sendMessage(df.RESTORE, 0, 0);
        },
        df.ID_SYSMINIMIZE => {
            _ = win.sendMessage(df.MINIMIZE, 0, 0);
        },
        df.ID_SYSMAXIMIZE => {
            _ = win.sendMessage(df.MAXIMIZE, 0, 0);
        },
        df.ID_HELP => {
            const name = Klass.defs[@intCast(df.GetClass(wnd))][0];
            _ = df.DisplayHelp(wnd, @constCast(name.ptr));
        },
        else => {
        }
    }
}

// --------- SETFOCUS Message ----------
fn SetFocusMsg(win:*Window, p1:df.PARAM) void {
    const wnd = win.win;
    var rc:df.RECT = .{.lf=0, .tp=0, .rt=0, .bt=0};
    if ((p1>0) and (df.inFocus != wnd)) {
        // set focus
        var this:df.WINDOW = null;
        var thispar:df.WINDOW = null;
        var that:df.WINDOW = null;
        var thatpar:df.WINDOW = null;

        var cwnd = wnd;
        var fwnd = Window.GetParent(wnd);

        // ---- post focus in ancestors ----
        while (fwnd != null) {
            fwnd.*.childfocus = cwnd;
            cwnd = fwnd;
            fwnd = Window.GetParent(fwnd);
        }
        // ---- de-post focus in self and children ----
        fwnd = wnd;
        while (fwnd != null) {
            cwnd = fwnd.*.childfocus;
            fwnd.*.childfocus = null;
            fwnd = cwnd;
        }

        this = wnd;
        that = df.inFocus;
        thatpar = df.inFocus;
        // ---- find common ancestor of prev focus and this window ---
        while (thatpar != null) {
            thispar = wnd;
            while (thispar != null) {
                if ((this == df.CaptureMouse) or (this == df.CaptureKeyboard)) {
                    // ---- don't repaint if this window has capture ----
                    that = null;
                    thatpar = null;
                    break;
                }
                if (thispar == thatpar) {
                    // ---- don't repaint if SAVESELF window had focus ----
                    if ((this != that) and (df.TestAttribute(that, df.SAVESELF)>0)) {
                        that = null;
                        thatpar = null;
                    }
                    break;
                }
                this = thispar;
                thispar = Window.GetParent(thispar);
            }
            if (thispar != null) {
                break;
            }
            that = thatpar;
            thatpar = Window.GetParent(thatpar);
        }
        if (df.inFocus != null) {
            _ = q.SendMessage(df.inFocus, df.SETFOCUS, df.FALSE, 0);
        }
        df.inFocus = wnd;
        if ((that != null) and (df.isVisible(wnd)>0)) {
            rc = df.subRectangle(df.WindowRect(that), df.WindowRect(this));
            if (df.ValidRect(rc) == false) {
                if (df.ApplicationWindow != null) {
                    var ffwnd = Window.FirstWindow(df.ApplicationWindow);
                    while (ffwnd != null) {
                        if (df.isAncestor(wnd, ffwnd) == 0) {
                            rc = df.subRectangle(df.WindowRect(wnd),df.WindowRect(ffwnd));
                            if (df.ValidRect(rc)) {
                                break;
                            }
                        }
                        ffwnd = Window.NextWindow(ffwnd);
                    }
                }
            }
        }
        if ((that != null) and (df.ValidRect(rc)==false) and (df.isVisible(wnd)>0)) {
            this = null;
        }
        df.ReFocus(wnd);
        if ((this != null) and ((df.isVisible(this) == 0) or (df.TestAttribute(this, df.SAVESELF) == 0))) {
            wnd.*.wasCleared = df.FALSE;
            _ = q.SendMessage(this, df.SHOW_WINDOW, 0, 0);
        } else if (df.isVisible(wnd) == 0) {
            _ = q.SendMessage(wnd, df.SHOW_WINDOW, 0, 0);
        } else {
            _ = q.SendMessage(wnd, df.BORDER, 0, 0);
        }
    }
    else if ((p1 == 0) and (df.inFocus == wnd)) {
        // -------- clearing focus ---------
        df.inFocus = null;
        _ = win.sendMessage(df.BORDER, 0, 0);
    }
}

// --------- DOUBLE_CLICK Message ----------
fn DoubleClickMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    const mx = p1 - win.GetLeft();
    const my = p2 - win.GetTop();
    if ((df.WindowSizing == 0) and (df.WindowMoving==0)) {
        if (df.HitControlBox(wnd, mx, my)) {
            q.PostMessage(wnd, df.CLOSE_WINDOW, 0, 0);
            lists.SkipApplicationControls();
        }
    }
}

// --------- LEFT_BUTTON Message ----------
fn LeftButtonMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    var wnd = win.win; // this may change
    const dwnd = getDummy();
    const mx = p1 - win.GetLeft();
    const my = p2 - win.GetTop();
    if ((df.WindowSizing>0) or (df.WindowMoving>0))
        return;
    if (df.HitControlBox(wnd, mx, my)) {
        df.BuildSystemMenu(wnd);
        return;
    }
    if ((my == 0) and (mx > -1) and (mx < win.WindowWidth())) {
        // ---------- hit the top border --------
        if (win.TestAttribute(df.MINMAXBOX) and
                win.TestAttribute(df.HASTITLEBAR)) {
            if (mx == win.WindowWidth()-2) {
                if (wnd.*.condition != df.ISRESTORED) {
                    // --- hit the restore box ---
                    _ = win.sendMessage(df.RESTORE, 0, 0);
                } else {
                    // --- hit the maximize box ---
                    _ = win.sendMessage(df.MAXIMIZE, 0, 0);
                }
                return;
            }
            if (mx == win.WindowWidth()-3) {
                // --- hit the minimize box ---
                if (wnd.*.condition != df.ISMINIMIZED) {
                    _ = win.sendMessage(df.MINIMIZE, 0, 0);
                }
                return;
            }
        }
        if (wnd.*.condition == df.ISMAXIMIZED) {
            return;
        }
        if (win.TestAttribute(df.MOVEABLE))    {
            df.WindowMoving = df.TRUE;
            df.px = @intCast(mx);
            df.py = @intCast(my);
            df.diff = @intCast(mx);
            _ = win.sendMessage(df.CAPTURE_MOUSE, df.TRUE, @intCast(@intFromPtr(&dwnd)));
            df.dragborder(wnd, @intCast(win.GetLeft()), @intCast(win.GetTop()));
        }
        return;
    }
    if ((mx == win.WindowWidth()-1) and
            (my == win.WindowHeight()-1)) {
        // ------- hit the resize corner -------
        if (wnd.*.condition == df.ISMINIMIZED)
            return;
        if (win.TestAttribute(df.SIZEABLE) == false)
            return;
        if (wnd.*.condition == df.ISMAXIMIZED) {
            if (Window.GetParent(wnd) == null) {
                return;
            }
            if (df.TestAttribute(Window.GetParent(wnd), df.HASBORDER)>0) {
                return;
            }
            // ----- resizing a maximized window over a borderless parent -----
            wnd = Window.GetParent(wnd);
            if (df.TestAttribute(wnd, df.SIZEABLE) == 0)
                return;
        }
        df.WindowSizing = df.TRUE;
        _ = q.SendMessage(wnd, df.CAPTURE_MOUSE, df.TRUE, @intCast(@intFromPtr(&dwnd)));
        df.dragborder(wnd, @intCast(win.GetLeft()), @intCast(win.GetTop()));
    }
}

// --------- MOUSE_MOVED Message ----------
fn MouseMovedMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    if (df.WindowMoving>0) {
        var leftmost:c_int = 0;
        var topmost:c_int = 0;
        var bottommost:c_int = df.SCREENHEIGHT-2;
        var rightmost:c_int = df.SCREENWIDTH-2;
        var x:c_int = @intCast(p1 - df.diff);
        var y:c_int = @intCast(p2);
        if ((Window.GetParent(wnd) != null) and
                (win.TestAttribute(df.NOCLIP) == false)) {
            const wnd1 = Window.GetParent(wnd);
            if (Window.get_zin(wnd1)) |win1| {
                topmost    = @intCast(win1.GetClientTop());
                leftmost   = @intCast(win1.GetClientLeft());
                bottommost = @intCast(win1.GetClientBottom());
                rightmost  = @intCast(win1.GetClientRight());
            } // else error ?
        }
        if ((x < leftmost) or (x > rightmost) or
                (y < topmost) or (y > bottommost))    {
            x = @max(x, leftmost);
            x = @min(x, rightmost);
            y = @max(y, topmost);
            y = @min(y, bottommost);
            _ = q.SendMessage(null,df.MOUSE_CURSOR,x+df.diff,y);
        }
        if ((x != df.px) or  (y != df.py))    {
            df.px = x;
            df.py = y;
            df.dragborder(wnd, x, y);
        }
        return true;
    }
    if (df.WindowSizing>0) {
        df.sizeborder(wnd, @intCast(p1), @intCast(p2));
        return true;
    }
    return false;
}

// --------- MOVE Message ----------
fn MoveMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    const wasVisible = (df.isVisible(wnd) > 0);
    const xdif = p1 - win.GetLeft();
    const ydif = p2 - win.GetTop();

    if ((xdif == 0) and (ydif == 0)) {
        return;
    }
    wnd.*.wasCleared = df.FALSE;
    if (wasVisible) {
        _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    }
    wnd.*.rc.lf = @intCast(p1);
    wnd.*.rc.tp = @intCast(p2);
    // be careful, changing the same struct.
    wnd.*.rc.rt = @intCast(win.GetLeft()+win.WindowWidth()-1);
    wnd.*.rc.bt = @intCast(win.GetTop()+win.WindowHeight()-1);
    if (wnd.*.condition == df.ISRESTORED) {
        wnd.*.RestoredRC = wnd.*.rc;
    }

    var cwnd = Window.FirstWindow(wnd);
    while (cwnd) |cw| {
        _ = q.SendMessage(cw, df.MOVE, cwnd.*.rc.lf+xdif, cwnd.*.rc.tp+ydif);
        cwnd = Window.NextWindow(cw);
    }
    if (wasVisible)
        _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
}


// --------- SIZE Message ----------
fn SizeMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    const wasVisible = (df.isVisible(wnd) > 0);
    const xdif = p1 - win.GetRight();
    const ydif = p2 - win.GetBottom();

    if ((xdif == 0) and (ydif == 0)) {
        return;
    }
    wnd.*.wasCleared = df.FALSE;
    if (wasVisible) {
        _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    }
    wnd.*.rc.rt = @intCast(p1);
    wnd.*.rc.bt = @intCast(p2);
    wnd.*.ht = @intCast(win.GetBottom()-win.GetTop()+1);
    wnd.*.wd = @intCast(win.GetRight()-win.GetLeft()+1);

    if (wnd.*.condition == df.ISRESTORED)
        wnd.*.RestoredRC = df.WindowRect(wnd);

    const rc = rect.ClientRect(win);

    var cwnd = Window.FirstWindow(wnd);
    while (cwnd != null) {
        if (cwnd.*.condition == df.ISMAXIMIZED) {
            _ = q.SendMessage(cwnd, df.SIZE, df.RectRight(rc), df.RectBottom(rc));
        }
        cwnd = Window.NextWindow(cwnd);
    }

    if (wasVisible)
        _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
}

// --------- CLOSE_WINDOW Message ----------
fn CloseWindowMsg(win:*Window) void {
    const wnd = win.win;
    wnd.*.condition = df.ISCLOSING;
    // ----------- hide this window ------------
    _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);

    // --- close the children of this window ---
    var cwnd = Window.LastWindow(wnd);
    while (cwnd != null) {
        if (df.inFocus == cwnd) {
            df.inFocus = wnd;
        }
        _ = q.SendMessage(cwnd,df.CLOSE_WINDOW,0,0);
        cwnd = Window.LastWindow(wnd);
    }

    // ----- release captured resources ------
    if (wnd.*.PrevClock != null)
        _ = win.sendMessage(df.RELEASE_CLOCK, 0, 0);
    if (wnd.*.PrevMouse != null)
        _ = win.sendMessage(df.RELEASE_MOUSE, 0, 0);
    if (wnd.*.PrevKeyboard != null)
        _ = win.sendMessage(df.RELEASE_KEYBOARD, 0, 0);
    // --- change focus if this window had it --
    if (wnd == df.inFocus)
        lists.SetPrevFocus();
    // -- free memory allocated to this window --
    if (wnd.*.title != null)
        df.free(wnd.*.title);
    if (wnd.*.videosave != null)
        df.free(wnd.*.videosave);
    // -- remove window from parent's list of children --
        lists.RemoveWindow(wnd);
    if (wnd == df.inFocus)
        df.inFocus = null;
    df.free(wnd);
    // FIXME: should also free parent win
}

// --------- MAXIMIZE Message ----------
fn MaximizeMsg(win:*Window) void {
    const wnd = win.win;
    var rc:df.RECT = .{.lf=0, .tp=0, .rt=0, .bt=0};
    const holdrc = wnd.*.RestoredRC;
    rc.rt = df.SCREENWIDTH-1;
    rc.bt = df.SCREENHEIGHT-1;
    if (Window.GetParent(wnd)) |parent| {
        if (Window.get_zin(parent)) |zin| {
            rc = rect.ClientRect(zin);
        }
    }
    wnd.*.oldcondition = wnd.*.condition;
    wnd.*.condition = df.ISMAXIMIZED;
    wnd.*.wasCleared = df.FALSE;
    _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    _ = win.sendMessage(df.MOVE, df.RectLeft(rc), df.RectTop(rc));
    _ = win.sendMessage(df.SIZE, df.RectRight(rc), df.RectBottom(rc));
    if (wnd.*.restored_attrib == 0) {
        wnd.*.restored_attrib = wnd.*.attrib;
    }
    win.ClearAttribute(df.SHADOW);
    _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
    wnd.*.RestoredRC = holdrc;
}

// --------- MINIMIZE Message ----------
fn MinimizeMsg(win:*Window) void {
    const wnd = win.win;
    const holdrc = wnd.*.RestoredRC;
    const rc = df.PositionIcon(wnd);
    wnd.*.oldcondition = wnd.*.condition;
    wnd.*.condition = df.ISMINIMIZED;
    wnd.*.wasCleared = df.FALSE;
    _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    _ = win.sendMessage(df.MOVE, df.RectLeft(rc), df.RectTop(rc));
    _ = win.sendMessage(df.SIZE, df.RectRight(rc), df.RectBottom(rc));
    if (wnd == df.inFocus) {
        lists.SetNextFocus();
    }
    if (wnd.*.restored_attrib == 0) {
        wnd.*.restored_attrib = wnd.*.attrib;
    }
    win.ClearAttribute( df.SHADOW | df.SIZEABLE | df.HASMENUBAR |
                        df.VSCROLLBAR | df.HSCROLLBAR);
    _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
    wnd.*.RestoredRC = holdrc;
}

// --------- RESTORE Message ----------
fn RestoreMsg(win:*Window) void {
    const wnd = win.win;
    const holdrc = wnd.*.RestoredRC;
    wnd.*.oldcondition = wnd.*.condition;
    wnd.*.condition = df.ISRESTORED;
    wnd.*.wasCleared = df.FALSE;
    _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    wnd.*.attrib = wnd.*.restored_attrib;
    wnd.*.restored_attrib = 0;
    _ = win.sendMessage(df.MOVE, wnd.*.RestoredRC.lf, wnd.*.RestoredRC.tp);
    wnd.*.RestoredRC = holdrc;
    _ = win.sendMessage(df.SIZE, wnd.*.RestoredRC.rt, wnd.*.RestoredRC.bt);
    if (wnd != df.inFocus) {
        _ = win.sendMessage(df.SETFOCUS, df.TRUE, 0);
    } else {
        _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
    }
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
                q.PostMessage(Window.GetParent(wnd), msg, p1, p2);
        },
        df.ADDSTATUS, df.SHIFT_CHANGED => {
            if (Window.GetParent(wnd) != null)
                q.PostMessage(Window.GetParent(wnd), msg, p1, p2);
        },
        df.PAINT => {
            if (df.isVisible(wnd)>0) {
                if (wnd.*.wasCleared > 0) {
                    df.PaintUnderLappers(wnd);
                } else {
                    wnd.*.wasCleared = df.TRUE;

                    var pp1:?*df.RECT = null;
                    if (p1>0) {
                        const p1_addr:usize = @intCast(p1);
                        pp1 = @ptrFromInt(p1_addr);
                    }

                    df.ClearWindow(wnd, pp1, ' '); // pp1 can be null
                }
            }
        },
        df.BORDER => {
            if (df.isVisible(wnd)>0) {
                var pp1:?*df.RECT = null;
                if (p1>0) {
                    const p1_addr:usize = @intCast(p1);
                    pp1 = @ptrFromInt(p1_addr);
                }

                if (win.TestAttribute(df.HASBORDER)) {
                    df.RepaintBorder(wnd, pp1);
                } else if (win.TestAttribute(df.HASTITLEBAR)) {
                    df.DisplayTitle(wnd, pp1);
                }
            }
        },
        df.COMMAND => {
            CommandMsg(win, p1);
        },
        df.SETFOCUS => {
            SetFocusMsg(win, p1);
        },
        df.DOUBLE_CLICK => {
            DoubleClickMsg(win, p1, p2);
        },
        df.LEFT_BUTTON => {
            LeftButtonMsg(win, p1, p2);
        },
        df.MOUSE_MOVED => {
            if (MouseMovedMsg(win, p1, p2)) {
                return df.TRUE;
            }
        },
        df.BUTTON_RELEASED => {
            if ((df.WindowMoving>0) or (df.WindowSizing>0)) {
                const dwnd = getDummy();
                if (df.WindowMoving > 0) {
                    q.PostMessage(wnd,df.MOVE,dwnd.*.rc.lf,dwnd.*.rc.tp);
                } else {
                    q.PostMessage(wnd,df.SIZE,dwnd.*.rc.rt,dwnd.*.rc.bt);
                }
                TerminateMoveSize();
            }
        },
        df.MOVE => {
            MoveMsg(win, p1, p2);
        },
        df.SIZE => {
            SizeMsg(win, p1, p2);
        },
        df.CLOSE_WINDOW => {
            CloseWindowMsg(win);
        },
        df.MAXIMIZE => {
            if (wnd.*.condition != df.ISMAXIMIZED)
                MaximizeMsg(win);
        },
        df.MINIMIZE => {
            if (wnd.*.condition != df.ISMINIMIZED)
                MinimizeMsg(win);
        },
        df.RESTORE => {
            if (wnd.*.condition != df.ISRESTORED) {
                if (wnd.*.oldcondition == df.ISMAXIMIZED) {
                    _ = win.sendMessage(df.MAXIMIZE, 0, 0);
                } else {
                    RestoreMsg(win);
                }
            }
        },
        df.DISPLAY_HELP => {
            const p1_addr:usize = @intCast(p1);
            const pp1:[*c]u8 = @ptrFromInt(p1_addr);
            const rtn = df.DisplayHelp(wnd, pp1);
            return @intCast(rtn);
        },
        else => {
            return df.cNormalProc(wnd, msg, p1, p2);
        }
    }
    return df.TRUE;
}

// ----- terminate the move or size operation -----
fn TerminateMoveSize() void {
    const dwnd = getDummy();
    df.px = -1;
    df.py = -1;
    df.diff = 0;
    _ = q.SendMessage(dwnd, df.RELEASE_MOUSE, df.TRUE, 0);
    _ = q.SendMessage(dwnd, df.RELEASE_KEYBOARD, df.TRUE, 0);
    df.RestoreBorder(dwnd.*.rc);
    df.WindowMoving = df.FALSE;
    df.WindowSizing = df.FALSE;
}
