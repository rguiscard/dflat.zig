const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const lists = @import("Lists.zig");
const rect = @import("Rect.zig");
const Klass = @import("Classes.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;
const CLASS = @import("Classes.zig").CLASS;
const k = CLASS; // abbreviation
const helpbox = @import("HelpBox.zig");
const sysmenu = @import("SystemMenu.zig");
const Classes = @import("Classes.zig");
const app = @import("Application.zig");

const ICONHEIGHT = 3;
const ICONWIDTH = 10;

var dummyWin:?Window = null;
var dummy:df.window = undefined; // need to be static or it will crash;
var px:c_int = -1;
var py:c_int = -1;
var diff:c_int = 0;
pub var WindowMoving = false;
pub var WindowSizing = false;

var Bsave:?[]u16 = null;
var Bht:usize = 0;
var Bwd:usize = 0;

var HiddenWindow:*Window = undefined; // seems initialized before use ?

// fn getDummy() df.WINDOW {
fn getDummy() *Window {
    if(dummyWin == null) {
        dummy = std.mem.zeroInit(df.window, .{.rc = .{.lf = -1, .tp = -1, .rt = -1, .bt = -1}});
        dummyWin = Window.init(&dummy);
        dummyWin.?.Class = k.DUMMY;
        dummyWin.?.wndproc = NormalProc; // doesn't seem necessary
        dummy.zin = @ptrCast(@alignCast(&dummyWin.?));
    }
    return if (dummyWin) |*win| win else unreachable;
}

// --------- CREATE_WINDOW Message ----------
fn CreateWindowMsg(win:*Window) void {
    lists.AppendWindow(win);
    const rtn = q.SendMessage(null, df.MOUSE_INSTALLED, 0, 0);
    if (rtn == 0) {
        win.ClearAttribute(df.VSCROLLBAR | df.HSCROLLBAR);
    }
    if (win.TestAttribute(df.SAVESELF) and isVisible(win)) {
        GetVideoBuffer(win);
    }
}

// --------- SHOW_WINDOW Message ----------
fn ShowWindowMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    if (win.parent == null or isVisible(win.getParent())) {
        if (win.TestAttribute(df.SAVESELF) and
                        (win.videosave == null)) {
            GetVideoBuffer(win);
        }
        win.SetVisible();

        _ = win.sendMessage(df.PAINT, 0, df.TRUE);
        _ = win.sendMessage(df.BORDER, 0, 0);
        // --- show the children of this window ---
        var cwin = win.firstWindow();
        while (cwin) |cw| {
            if (cw.condition != .ISCLOSING) {
                _ = cw.sendMessage(df.SHOW_WINDOW, p1, p2);
            }
            cwin = cw.nextWindow();
        }
    }
}

// --------- HIDE_WINDOW Message ----------
fn HideWindowMsg(win:*Window) void {
    if (isVisible(win)) {
        win.ClearVisible();
        // --- paint what this window covered ---
        if (win.TestAttribute(df.SAVESELF)) {
            PutVideoBuffer(win);
        } else {
            PaintOverLappers(win);
        }
        win.wasCleared = false;
    }
}

// ----- test if screen coordinates are in a window ----
fn InsideWindow(win:*Window, x:c_int, y:c_int) bool {
    var rc = win.WindowRect();
    if (win.TestAttribute(df.NOCLIP))    {
        var pwnd = win.parent;
        while (pwnd) |pw| {
            rc = df.subRectangle(rc, rect.ClientRect(pw));
            pwnd = pw.parent;
        }
    }
    if (rect.InsideRect(x, y, rc)) {
        return true;
    }
    return false;
}

// --------- KEYBOARD Message ----------
fn KeyboardMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    const dwin = getDummy();
    if (WindowMoving or WindowSizing) {
        // -- move or size a window with keyboard --
        var x:c_int = if (WindowMoving) @intCast(dwin.GetLeft()) else @intCast(dwin.GetRight());
        var y:c_int = if (WindowMoving) @intCast(dwin.GetTop()) else @intCast(dwin.GetBottom());
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
        _ = win.sendMessage(df.MOUSE_CURSOR, x, y);
        _ = win.sendMessage(df.MOUSE_MOVED, x, y);
        return true;
    }
    switch (p1) {
        df.F1 => {
            _ = win.sendCommandMessage(c.ID_HELP, 0);
            return true;
        },
        ' ' => {
            const p2_i:isize = p2;
            if ((p2_i & df.ALTKEY) > 0) {
                if (win.TestAttribute(df.HASTITLEBAR)) {
                    if (win.TestAttribute(df.CONTROLBOX)) {
                        sysmenu.BuildSystemMenu(win);
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
    const dwin = getDummy();
//    const dwnd = dwin.win;
    const dwin_p2:df.PARAM = @intCast(@intFromPtr(dwin));
//    const dwnd_p2:df.PARAM = @intCast(@intFromPtr(dwnd));
    const cmd:c = @enumFromInt(p1);
    switch (cmd) {
        .ID_SYSMOVE => {
            _ = win.sendMessage(df.CAPTURE_MOUSE, df.TRUE, dwin_p2);
            _ = win.sendMessage(df.CAPTURE_KEYBOARD, df.TRUE, dwin_p2);
            _ = win.sendMessage(df.MOUSE_CURSOR, @intCast(win.GetLeft()), @intCast(win.GetTop()));
            WindowMoving = true;
            dragborder(win, @intCast(win.GetLeft()), @intCast(win.GetTop()));
        },
        .ID_SYSSIZE => {
            _ = win.sendMessage(df.CAPTURE_MOUSE, df.TRUE, dwin_p2);
            _ = win.sendMessage(df.CAPTURE_KEYBOARD, df.TRUE, dwin_p2);
            _ = win.sendMessage(df.MOUSE_CURSOR, @intCast(win.GetRight()), @intCast(win.GetBottom()));
            WindowSizing = true;
            dragborder(win, @intCast(win.GetLeft()), @intCast(win.GetTop()));
        },
        .ID_SYSCLOSE => {
            _ = win.sendMessage(df.CLOSE_WINDOW, 0, 0);
            lists.SkipApplicationControls();
        },
        .ID_SYSRESTORE => {
            _ = win.sendMessage(df.RESTORE, 0, 0);
        },
        .ID_SYSMINIMIZE => {
            _ = win.sendMessage(df.MINIMIZE, 0, 0);
        },
        .ID_SYSMAXIMIZE => {
            _ = win.sendMessage(df.MAXIMIZE, 0, 0);
        },
        .ID_HELP => {
            const idx:usize = @intCast(@intFromEnum(win.getClass()));
            const name = Klass.defs[idx][0];
            _ = helpbox.DisplayHelp(win, name);
        },
        else => {
        }
    }
}

// --------- SETFOCUS Message ----------
fn SetFocusMsg(win:*Window, p1:df.PARAM) void {
    var rc:df.RECT = .{.lf=0, .tp=0, .rt=0, .bt=0};
    if ((p1>0) and (Window.inFocus != win)) {
        // set focus
        var this:?*Window = null;
        var thispar:?*Window = null;
        var that:?*Window = null;
        var thatpar:?*Window = null;

        var cwin:?*Window = win;
        var fwin = win.parent;
        // ---- post focus in ancestors ----
        while (fwin) |ff| {
            ff.*.childfocus = cwin;
            cwin = ff;
            fwin = ff.parent;
        }
        // ---- de-post focus in self and children ----
        fwin = win;
        while (fwin) |ff| {
            cwin = ff.*.childfocus;
            ff.*.childfocus = null;
            fwin = cwin;
        }

        this = win;
        that = Window.inFocus;
        thatpar = Window.inFocus;
        // ---- find common ancestor of prev focus and this window ---
        while (thatpar) |thatp| {
            thispar = win;
            while (thispar) |thisp| {
                if (this == q.CaptureMouse or this == q.CaptureKeyboard) {
                    // ---- don't repaint if this window has capture ----
                    that = null;
                    thatpar = null;
                    break;
                }
                if (thisp == thatp) {
                    // ---- don't repaint if SAVESELF window had focus ----
                    if ((this != that) and that.?.TestAttribute(df.SAVESELF)) {
                        that = null;
                        thatpar = null;
                    }
                    break;
                }
                this = thisp;
                thispar = thisp.parent;
            }
            if (thispar != null) {
                break;
            }
            that = thatp;
            thatpar = thatp.parent;
        }
        if (Window.inFocus) |focus| {
            _ = focus.sendMessage(df.SETFOCUS, df.FALSE, 0);
        }
        Window.inFocus = win;
        if ((that != null) and isVisible(win)) {
            rc = df.subRectangle(that.?.WindowRect(), this.?.WindowRect());
            if (df.ValidRect(rc) == false) {
                if (app.ApplicationWindow) |awin| {
                    var ffwin = awin.firstWindow();
                    while (ffwin) |ff| {
                        if (isAncestor(win, ff) == false) {
                            rc = df.subRectangle(win.WindowRect(),ff.WindowRect());
                            if (df.ValidRect(rc)) {
                                break;
                            }
                        }
                        ffwin = ff.nextWindow();
                    }
                }
            }
        }
        if ((that != null) and (df.ValidRect(rc)==false) and isVisible(win)) {
            this = null;
        }
        lists.ReFocus(win);
        if ((this != null) and ((isVisible(this.?) == false) or (this.?.TestAttribute(df.SAVESELF) == false))) {
            win.wasCleared = false;
            _ = this.?.sendMessage(df.SHOW_WINDOW, 0, 0);
        } else if (isVisible(win) == false) {
            _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
        } else {
            _ = win.sendMessage(df.BORDER, 0, 0);
        }
    }
    else if ((p1 == 0) and (Window.inFocus == win)) {
        // -------- clearing focus ---------
        Window.inFocus = null;
        _ = win.sendMessage(df.BORDER, 0, 0);
    }
}

// --------- DOUBLE_CLICK Message ----------
fn DoubleClickMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const pp1:usize = @intCast(p1);
    const pp2:usize = @intCast(p2);
    const mx:usize = pp1 - win.GetLeft();
    const my:usize = pp2 - win.GetTop();
    if ((WindowSizing == false) and (WindowMoving == false)) {
        if (win.HitControlBox(mx, my)) {
            q.PostMessage(win, df.CLOSE_WINDOW, 0, 0);
            lists.SkipApplicationControls();
        }
    }
}

// --------- LEFT_BUTTON Message ----------
fn LeftButtonMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const dwin = getDummy();
//    const dwnd = dwin.win;
    const pp1:usize = @intCast(p1);
    const pp2:usize = @intCast(p2);
    const mx:usize = pp1 - win.GetLeft();
    const my:usize = pp2 - win.GetTop();
    if (WindowSizing or WindowMoving)
        return;
    if (win.HitControlBox(mx, my)) {
        sysmenu.BuildSystemMenu(win);
        return;
    }
    if ((my == 0) and (mx > -1) and (mx < win.WindowWidth())) {
        // ---------- hit the top border --------
        if (win.TestAttribute(df.MINMAXBOX) and
                win.TestAttribute(df.HASTITLEBAR)) {
            if (mx == win.WindowWidth()-2) {
                if (win.condition != .ISRESTORED) {
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
                if (win.condition != .ISMINIMIZED) {
                    _ = win.sendMessage(df.MINIMIZE, 0, 0);
                }
                return;
            }
        }
        if (win.condition == .ISMAXIMIZED) {
            return;
        }
        if (win.TestAttribute(df.MOVEABLE)) {
            WindowMoving = true;
            px = @intCast(mx);
            py = @intCast(my);
            diff = @intCast(mx);
            _ = win.sendMessage(df.CAPTURE_MOUSE, df.TRUE, @intCast(@intFromPtr(dwin)));
            dragborder(win, @intCast(win.GetLeft()), @intCast(win.GetTop()));
        }
        return;
    }
    if ((mx == win.WindowWidth()-1) and
            (my == win.WindowHeight()-1)) {
        var ww = win; // identity of win may change
        // ------- hit the resize corner -------
        if (win.condition == .ISMINIMIZED)
            return;
        if (win.TestAttribute(df.SIZEABLE) == false)
            return;
        if (win.condition == .ISMAXIMIZED) {
            if (win.parent == null) {
                return;
            }
            if (win.getParent().TestAttribute(df.HASBORDER)) {
                return;
            }
            // ----- resizing a maximized window over a borderless parent -----

            // win is changed. it affects the identity of win below.
            // is it intended to do so?
            ww = win.getParent();
            if (ww.TestAttribute(df.SIZEABLE) == false)
                return;
        }
        WindowSizing = true;
        _ = ww.sendMessage(df.CAPTURE_MOUSE, df.TRUE, @intCast(@intFromPtr(dwin)));
        dragborder(ww, @intCast(ww.GetLeft()), @intCast(ww.GetTop()));
    }
}

// --------- MOUSE_MOVED Message ----------
fn MouseMovedMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) bool {
    if (WindowMoving) {
        var leftmost:c_int = 0;
        var topmost:c_int = 0;
        var bottommost:c_int = df.SCREENHEIGHT-2;
        var rightmost:c_int = df.SCREENWIDTH-2;
        var x:c_int = @intCast(p1 - diff);
        var y:c_int = @intCast(p2);
        if ((win.parent != null) and
                (win.TestAttribute(df.NOCLIP) == false)) {
            const win1 = win.getParent();
            topmost    = @intCast(win1.GetClientTop());
            leftmost   = @intCast(win1.GetClientLeft());
            bottommost = @intCast(win1.GetClientBottom());
            rightmost  = @intCast(win1.GetClientRight());
        }
        if ((x < leftmost) or (x > rightmost) or
                (y < topmost) or (y > bottommost))    {
            x = @max(x, leftmost);
            x = @min(x, rightmost);
            y = @max(y, topmost);
            y = @min(y, bottommost);
            _ = q.SendMessage(null,df.MOUSE_CURSOR,x+diff,y);
        }
        if ((x != px) or  (y != py))    {
            px = x;
            py = y;
            dragborder(win, x, y);
        }
        return true;
    }
    if (WindowSizing) {
        sizeborder(win, @intCast(p1), @intCast(p2));
        return true;
    }
    return false;
}

// --------- MOVE Message ----------
fn MoveMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    const wasVisible = win.isVisible();
    const xdif = p1 - @as(c_int, @intCast(win.GetLeft()));
    const ydif = p2 - @as(c_int, @intCast(win.GetTop()));

    if ((xdif == 0) and (ydif == 0)) {
        return;
    }
    win.wasCleared = false;
    if (wasVisible) {
        _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    }
    wnd.*.rc.lf = @intCast(p1);
    wnd.*.rc.tp = @intCast(p2);
    // be careful, changing the same struct.
    wnd.*.rc.rt = @intCast(win.GetLeft()+win.WindowWidth()-1);
    wnd.*.rc.bt = @intCast(win.GetTop()+win.WindowHeight()-1);
    if (win.condition == .ISRESTORED) {
        wnd.*.RestoredRC = wnd.*.rc;
    }

    var cwin = win.firstWindow();
    while (cwin) |cw| {
        const cwnd = cw.win;
        _ = cw.sendMessage(df.MOVE, cwnd.*.rc.lf+xdif, cwnd.*.rc.tp+ydif);
        cwin = cw.nextWindow();
    }
    if (wasVisible)
        _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
}


// --------- SIZE Message ----------
fn SizeMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    const wasVisible = win.isVisible();

    if ((p1 == win.GetRight()) and (p2 == win.GetBottom())) {
        return;
    }
    win.wasCleared = false;
    if (wasVisible) {
        _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    }
    wnd.*.rc.rt = @intCast(p1);
    wnd.*.rc.bt = @intCast(p2);
    win.ht = win.GetBottom()-win.GetTop()+1;
    win.wd = win.GetRight()-win.GetLeft()+1;

    if (win.condition == .ISRESTORED)
        wnd.*.RestoredRC = df.WindowRect(wnd);

    const rc = rect.ClientRect(win);

    var cwin = win.firstWindow();
    while (cwin) |cw| {
        if (cw.condition == .ISMAXIMIZED) {
            _ = cw.sendMessage(df.SIZE, df.RectRight(rc), df.RectBottom(rc));
        }
        cwin = cw.nextWindow();
    }

    if (wasVisible)
        _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
}

// --------- CLOSE_WINDOW Message ----------
fn CloseWindowMsg(win:*Window) void {
    const wnd = win.win;
    win.condition = .ISCLOSING;
    // ----------- hide this window ------------
    _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);

    // --- close the children of this window ---
    var cwin = win.lastWindow();
    while (cwin) |cw| {
        if (Window.inFocus == cw) {
            Window.inFocus = win;
        }
        _ = cw.sendMessage(df.CLOSE_WINDOW,0,0);
        cwin = win.lastWindow();
    }

    // ----- release captured resources ------
    if (win.PrevClock) |_| {
        _ = win.sendMessage(df.RELEASE_CLOCK, 0, 0);
    }
    if (win.PrevMouse) |_| {
        _ = win.sendMessage(df.RELEASE_MOUSE, 0, 0);
    }
    if (win.PrevKeyboard) |_| {
        _ = win.sendMessage(df.RELEASE_KEYBOARD, 0, 0);
    }
    // --- change focus if this window had it --
    if (win == Window.inFocus)
        lists.SetPrevFocus();
    // -- free memory allocated to this window --
    if (win.title) |t| {
        root.global_allocator.free(t);
    }
    if (win.videosave) |videosave| {
        root.global_allocator.free(videosave);
        win.videosave = null;
    }
    // -- remove window from parent's list of children --
    lists.RemoveWindow(win);
    if (win == Window.inFocus)
        Window.inFocus = null;
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
    if (win.parent) |pw| {
        rc = rect.ClientRect(pw);
    }
    win.oldcondition = win.condition;
    win.condition = .ISMAXIMIZED;
    win.wasCleared = false;
    _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    _ = win.sendMessage(df.MOVE, df.RectLeft(rc), df.RectTop(rc));
    _ = win.sendMessage(df.SIZE, df.RectRight(rc), df.RectBottom(rc));
    if (win.restored_attrib == 0) {
        win.restored_attrib = win.attrib;
    }
    win.ClearAttribute(df.SHADOW);
    _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
    wnd.*.RestoredRC = holdrc;
}

// --------- MINIMIZE Message ----------
fn MinimizeMsg(win:*Window) void {
    const wnd = win.win;
    const holdrc = wnd.*.RestoredRC;
    const rc = PositionIcon(win);
    win.oldcondition = win.condition;
    win.condition = .ISMINIMIZED;
    win.wasCleared = false;
    _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    _ = win.sendMessage(df.MOVE, df.RectLeft(rc), df.RectTop(rc));
    _ = win.sendMessage(df.SIZE, df.RectRight(rc), df.RectBottom(rc));
    if (win == Window.inFocus) {
        lists.SetNextFocus();
    }
    if (win.restored_attrib == 0) {
        win.restored_attrib = win.attrib;
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
    win.oldcondition = win.condition;
    win.condition = .ISRESTORED;
    win.wasCleared = false;
    _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
    win.attrib = win.restored_attrib;
    win.restored_attrib = 0;
    _ = win.sendMessage(df.MOVE, wnd.*.RestoredRC.lf, wnd.*.RestoredRC.tp);
    wnd.*.RestoredRC = holdrc;
    _ = win.sendMessage(df.SIZE, wnd.*.RestoredRC.rt, wnd.*.RestoredRC.bt);
    if (win != Window.inFocus) {
        _ = win.sendMessage(df.SETFOCUS, df.TRUE, 0);
    } else {
        _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
    }
}

pub fn NormalProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
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
                return true;
            // ------- fall through -------
            if (win.parent) |pw| {
                q.PostMessage(pw, msg, p1, p2);
            }
        },
        df.ADDSTATUS, df.SHIFT_CHANGED => {
            if (win.parent) |pw| {
                q.PostMessage(pw, msg, p1, p2);
            }
        },
        df.PAINT => {
            if (isVisible(win)) {
                if (win.wasCleared) {
                    PaintUnderLappers(win);
                } else {
                    win.wasCleared = true;

                    var pp1:?*df.RECT = null;
                    if (p1>0) {
                        const p1_addr:usize = @intCast(p1);
                        pp1 = @ptrFromInt(p1_addr);
                    }

                    win.ClearWindow(pp1, ' '); // pp1 can be null
                }
            }
        },
        df.BORDER => {
            if (isVisible(win)) {
                var pp1:?*df.RECT = null;
                if (p1>0) {
                    const p1_addr:usize = @intCast(p1);
                    pp1 = @ptrFromInt(p1_addr);
                }

                // pp1 (p1) could be null
                if (win.TestAttribute(df.HASBORDER)) {
                    win.RepaintBorder(pp1);
                } else if (win.TestAttribute(df.HASTITLEBAR)) {
                    win.DisplayTitle(pp1);
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
                return true;
            }
        },
        df.BUTTON_RELEASED => {
            if (WindowMoving or WindowSizing) {
                const dwin = getDummy();
                const dwnd = dwin.win;
                if (WindowMoving) {
                    q.PostMessage(win,df.MOVE,dwnd.*.rc.lf,dwnd.*.rc.tp);
                } else {
                    q.PostMessage(win,df.SIZE,dwnd.*.rc.rt,dwnd.*.rc.bt);
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
            if (win.condition != .ISMAXIMIZED)
                MaximizeMsg(win);
        },
        df.MINIMIZE => {
            if (win.condition != .ISMINIMIZED)
                MinimizeMsg(win);
        },
        df.RESTORE => {
            if (win.condition != .ISRESTORED) {
                if (win.oldcondition == .ISMAXIMIZED) {
                    _ = win.sendMessage(df.MAXIMIZE, 0, 0);
                } else {
                    RestoreMsg(win);
                }
            }
        },
        df.DISPLAY_HELP => {
            const p1_addr:usize = @intCast(p1);
            const pp1:[*c]u8 = @ptrFromInt(p1_addr);
            return helpbox.DisplayHelp(win, std.mem.span(pp1));
        },
        else => {
        }
    }
    return true;
}

// ---- compute lower right icon space in a rectangle ----
fn LowerRight(prc:df.RECT) df.RECT {
    const rc = df.RECT{
        .lf = prc.rt - ICONWIDTH,
        .tp = prc.bt - ICONHEIGHT,
        .rt = prc.rt - 1,
        .bt = prc.bt - 1,
    };
    return rc;

//    RECT rc;
//    RectLeft(rc) = RectRight(prc) - ICONWIDTH;
//    RectTop(rc) = RectBottom(prc) - ICONHEIGHT;
//    RectRight(rc) = RectLeft(rc)+ICONWIDTH-1;
//    RectBottom(rc) = RectTop(rc)+ICONHEIGHT-1;
//    return rc;
}

// ----- compute a position for a minimized window icon ----
fn PositionIcon(win:*Window) df.RECT {
    var rc = df.RECT{
        .lf = df.SCREENWIDTH-ICONWIDTH,
        .tp = df.SCREENHEIGHT-ICONHEIGHT,
        .rt = df.SCREENWIDTH-1,
        .bt = df.SCREENHEIGHT-1
    };

    if (win.parent) |pwin| {
        const prc = pwin.WindowRect();
        var cwin = pwin.firstWindow();
        rc = LowerRight(prc); // this makes previosu assignment useless ?
        // - search for icon available location -
        while (cwin) |cw| {
            if (cw.condition == .ISMINIMIZED) {
                const rc1 = cw.WindowRect();
                if (rc1.lf == rc.lf and rc1.tp == rc.tp) {
                    rc.lf -= ICONWIDTH;
                    rc.rt -= ICONWIDTH;
                    if (rc.lf < prc.lf+1) {
                        rc.lf = prc.rt-ICONWIDTH;
                        rc.rt = rc.lf+ICONWIDTH-1;
                        rc.tp -= ICONHEIGHT;
                        rc.bt -= ICONHEIGHT;
                        if (rc.tp < prc.tp+1)
                            return LowerRight(prc);
                    }
                    break;
                }
            }
            cwin = cw.nextWindow();
        }
    }
    return rc;
}

// ----- terminate the move or size operation -----
fn TerminateMoveSize() void {
    const dwin = getDummy();
    px = -1;
    py = -1;
    diff = 0;
    _ = dwin.sendMessage(df.RELEASE_MOUSE, df.TRUE, 0);
    _ = dwin.sendMessage(df.RELEASE_KEYBOARD, df.TRUE, 0);
    RestoreBorder(dwin.win.*.rc);
    WindowMoving = false;
    WindowSizing = false;
}

// ---- build a dummy window border for moving or sizing ---
fn dragborder(win:*Window, x:c_int, y:c_int) void {
    const dwin = getDummy();
    const dwnd = dwin.win;

    RestoreBorder(dwnd.*.rc);
    // ------- build the dummy window --------
    dwnd.*.rc.lf = x;
    dwnd.*.rc.tp = y;
    dwnd.*.rc.rt = @intCast(dwnd.*.rc.lf+@as(c_int, @intCast(win.WindowWidth()))-1);
    dwnd.*.rc.bt = @intCast(dwnd.*.rc.tp+@as(c_int, @intCast(win.WindowHeight()))-1);
    dwin.ht = win.WindowHeight();
    dwin.wd = win.WindowWidth();
    dwin.parent = win.parent;
    dwin.attrib = df.VISIBLE | df.HASBORDER | df.NOCLIP;
    dwin.InitWindowColors();
    SaveBorder(dwnd.*.rc);
    dwin.RepaintBorder(null);
}

// ---- write the dummy window border for sizing ----
fn sizeborder(win:*Window, rt:c_int, bt:c_int) void {
    const dwin = getDummy();
    const dwnd = dwin.win;

    const leftmost:c_int = @intCast(win.GetLeft()+10);
    const topmost:c_int = @intCast(win.GetTop()+3);
    var bottommost:c_int = @intCast(df.SCREENHEIGHT-1);
    var rightmost:c_int = @intCast(df.SCREENWIDTH-1);
    if (win.parent) |pwin| {
        bottommost = @intCast(@min(bottommost, pwin.GetClientBottom()));
        rightmost  = @intCast(@min(rightmost, pwin.GetClientRight()));
    }
    var new_rt:c_int = @min(rt, rightmost);
    var new_bt:c_int = @min(bt, bottommost);
    new_rt = @max(new_rt, leftmost);
    new_bt = @max(new_bt, topmost);
    _ = df.SendMessage(null, df.MOUSE_CURSOR, new_rt, new_bt);

    if ((new_rt != px) or (new_bt != py))
        RestoreBorder(dwnd.*.rc);

    // ------- change the dummy window --------
    dwin.ht = @intCast(bt-dwnd.*.rc.tp+1);
    dwin.wd = @intCast(rt-dwnd.*.rc.lf+1);
    dwnd.*.rc.rt = new_rt;
    dwnd.*.rc.bt = new_bt;
    if ((new_rt != px) or (new_bt != py)) {
        px = new_rt;
        py = new_bt;
        SaveBorder(dwnd.*.rc);
        dwin.RepaintBorder(null);
    }
}

// ----- adjust a rectangle to include the shadow -----
fn adjShadow(win:*Window) df.RECT {
    const wnd = win.win;
    var rc = wnd.*.rc;
    if (win.TestAttribute(df.SHADOW)) {
        if (rc.rt < df.SCREENWIDTH-1)
            rc.rt += 1;
        if (rc.bt < df.SCREENHEIGHT-1)
            rc.bt += 1;
    }
    return rc;
}

// --- repaint a rectangular subsection of a window ---
fn PaintOverLap(win:*Window, rc:df.RECT) void {
    if (isVisible(win)) {
        var isBorder = false;
        var isTitle = false;
        var isData = true;
        if (win.TestAttribute(df.HASBORDER)) {
            isBorder =  rc.lf == 0 and
                        rc.tp < win.WindowHeight();
            isBorder |= rc.lf < win.WindowWidth() and
                        rc.rt >= win.WindowWidth()-1 and
                        rc.tp < win.WindowHeight();
            isBorder |= rc.tp == 0 and
                        rc.lf < win.WindowWidth();
            isBorder |= rc.tp < win.WindowHeight() and
                        rc.bt >= win.WindowHeight()-1 and
                        rc.lf < win.WindowWidth();
        } else if (win.TestAttribute(df.HASTITLEBAR)) {
            isTitle = rc.tp == 0 and
                      rc.rt > 0 and
                      rc.lf < win.WindowWidth()-win.BorderAdj();
        }

        if (rc.lf >= win.WindowWidth()-win.BorderAdj())
            isData = false;
        if (rc.tp >= win.WindowHeight()-win.BottomBorderAdj())
            isData = false;
        if (win.TestAttribute(df.HASBORDER)) {
            if (rc.rt == 0)
                isData = false;
            if (rc.bt == 0)
                isData = false;
        }
        if (win.TestAttribute(df.SHADOW))
            isBorder |= rc.rt == win.WindowWidth() or
                        rc.bt == win.WindowHeight();
        if (isData) {
            win.wasCleared = false;
            _ = win.sendMessage(df.PAINT, @intCast(@intFromPtr(&rc)), df.TRUE);
        }
        if (isBorder) {
            _ = win.sendMessage(df.BORDER, @intCast(@intFromPtr(&rc)), 0);
        } else if (isTitle) {
            win.DisplayTitle(@constCast(&rc));
        }
    }
}

// ------ paint the part of a window that is overlapped
//            by another window that is being hidden -------
fn PaintOver(win:*Window) void {
    const wnd = win.win;
    const wrc = adjShadow(HiddenWindow);
    var rc = adjShadow(win);
    rc = df.subRectangle(rc, wrc);
    if (df.ValidRect(rc))
        PaintOverLap(win, df.RelativeWindowRect(wnd, rc));
}

// --- paint the overlapped parts of all children ---
fn PaintOverChildren(pwin:*Window) void {
    var cwin = pwin.firstWindow();
    while (cwin) |cw| {
        if (cw != HiddenWindow) {
            PaintOver(cw);
            PaintOverChildren(cw);
        }
        cwin = cw.nextWindow();
    }
}

// -- recursive overlapping paint of parents --
fn PaintOverParents(win:*Window) void {
    if (win.parent) |pwin| {
        PaintOverParents(pwin);
        PaintOver(pwin);
        PaintOverChildren(pwin);
    }
}

// - paint the parts of all windows that a window is over -
fn PaintOverLappers(win:*Window) void {
    HiddenWindow = win;
    PaintOverParents(win);
}

// --- paint those parts of a window that are overlapped ---
fn PaintUnderLappers(win:*Window) void {
    const wnd = win.win;
    var hw = win.nextWindow();
    while (hw) |hwin| {
        const hwnd = hwin.win;
        // ------- test only at document window level ------
        var pwin = hwin.parent;
        // if (pwnd == NULL || GetClass(pwnd) == APPLICATION) {
        // ---- don't bother testing self -----
        if (isVisible(hwin) and hwnd != wnd) {
            // --- see if other window is descendent ---
            while (pwin) |pw| {
                if (pw == win)
                    break;
                pwin = pw.parent;
            }
            // ----- don't test descendent overlaps -----
            if (pwin == null) {
                // -- see if other window is ancestor ---
                pwin = win.parent;
                while (pwin) |pw| {
                    if (pw == hwin)
                        break;
                    pwin = pw.parent;
                }
                // --- don't test ancestor overlaps ---
                if (pwin == null) {
                    if (GetAncestor(hwin)) |w| {
                       // Could HiddenWindow be null ?
                       //HiddenWindow = GetAncestor(hwnd);
                       HiddenWindow = w;
                       HiddenWindow.ClearVisible();
                       PaintOver(win);
                       HiddenWindow.SetVisible();
                    }
                }
            }
        }
        hw = hwin.nextWindow();
    }
    // --------- repaint all children of this window
    //    the same way -----------
    hw = win.firstWindow();
    while (hw) |hwin| {
        PaintUnderLappers(hwin);
        hw = hwin.nextWindow();
    }
}

// --- save video area to be used by dummy window border ---
fn SaveBorder(rc:df.RECT) void {
    Bht = @intCast(rc.bt - rc.tp + 1);
    Bwd = @intCast(rc.rt - rc.lf + 1);

    const size:usize = (Bht+Bwd)*4;
    if (Bsave) |buf| {
        if (root.global_allocator.realloc(buf, size)) |b| {
            Bsave = b;
        } else |_| {
        }
    } else {
        if (root.global_allocator.alloc(u16, size)) |b| {
            Bsave = b;
        } else |_| {
        }
    }
    if (Bsave) |buf| {
        var lrc = rc;
        lrc.bt = lrc.tp;
        df.getvideo(lrc, @ptrCast(buf.ptr));
        lrc.tp = rc.bt;
        lrc.bt = rc.bt;
        df.getvideo(lrc, @ptrCast(&buf[Bwd]));
        var pos:usize = Bwd*2;
        for (1..Bht-1) |idx| {
            const i:c_int = @intCast(idx);
            buf[pos] = @intCast(df.GetVideoChar(rc.lf, rc.tp+i));
            pos += 1;
            buf[pos] = @intCast(df.GetVideoChar(rc.rt, rc.tp+i));
            pos += 1;
        }
    }
}

// ---- restore video area used by dummy window border ---- 
fn RestoreBorder(rc:df.RECT) void {
    if (Bsave) |buf| {
        var lrc = rc;
        lrc.bt = lrc.tp;
        df.storevideo(lrc, @constCast(&buf[0]));
        lrc.tp = rc.bt;
        lrc.bt = rc.bt;
        df.storevideo(lrc, @constCast(&buf[Bwd]));
        var pos:usize = @intCast(Bwd*2);
        for (1..Bht-1) |idx| {
            const i:c_int = @intCast(idx);
            df.PutVideoChar(rc.lf, rc.tp+i, buf[pos]);
            pos += 1;
            df.PutVideoChar(rc.rt, rc.tp+i, buf[pos]);
            pos += 1;

        }
        root.global_allocator.free(buf);
        Bsave = null;
    }
}

pub fn isDerivedFrom(win:*Window, klass:CLASS) bool {
    var tclass = win.getClass();
    while (tclass != k.FORCEINTTYPE) {
        if (tclass == klass) {
            return true;
        }
        const idx:usize = @intCast(@intFromEnum(tclass));
        const cls = Classes.defs[idx];
        tclass = cls[1];
    }
    return false;
}

// -- find the oldest document window ancestor of a window --
fn GetAncestor(win:*Window) ?*Window {
    var ww = win;
    // don't need to check null for win ?
    while (ww.parent) |pw| {
        if (pw.getClass() == k.APPLICATION)
            break;
        ww = pw;
    }
    return ww;
}

// there is also another Window.isVisible() which utilized this one
pub fn isVisible(win:*Window) bool {
    var ww:?*Window = win;
    while (ww) |w| {
        if (w.isHidden())
            return false;
        ww = w.parent;
    }
    return true;
}

// -- adjust a window's rectangle to clip it to its parent -
fn ClipRect(win:*Window) df.RECT {
    const wnd = win.win;
    var rc = win.WindowRect();
    if (win.TestAttribute(df.SHADOW)) {
        rc.bt += 1;
        rc.rt += 1;
//        RectBottom(rc)++;
//        RectRight(rc)++;
    }
    return df.ClipRectangle(wnd, rc);
}

// -- get the video memory that is to be used by a window --
fn GetVideoBuffer(win:*Window) void {
    const rc = ClipRect(win);
    const ht = df.RectBottom(rc) - df.RectTop(rc) + 1;
    const wd = df.RectRight(rc) - df.RectLeft(rc) + 1;
//    wnd.*.videosave = @ptrCast(df.DFrealloc(wnd.*.videosave, @intCast(ht * wd * 2)));
    if (win.videosave) |videosave| {
        if (root.global_allocator.realloc(videosave, @intCast(ht * wd * 2))) |buf| {
            win.videosave = buf;
        } else |_| {
        }
    } else {
        if (root.global_allocator.alloc(u8, @intCast(ht * wd * 2))) |buf| {
            win.videosave = buf;
        } else |_| {
        }
    }
    if (win.videosave) |videosave| {
        df.get_videomode();
        df.getvideo(rc, videosave.ptr);
    }
}

// -- put the video memory that is used by a window --
fn PutVideoBuffer(win:*Window) void {
    if (win.videosave) |videosave| {
        const rc = ClipRect(win);
        df.get_videomode();
        df.storevideo(rc, videosave.ptr);
        root.global_allocator.free(videosave);
        win.videosave = null;
    }
}

// ------- return TRUE if awnd is an ancestor of wnd -------
pub fn isAncestor(w: *Window, awnd: *Window) bool {
    var win:?*Window = w;
    while (win) |ww| {
        if (ww == awnd)
            return true;
        win = ww.parent;
    }
    return false;
}

pub export fn c_isVisible(wnd:df.WINDOW) df.BOOL {
    if (Window.get_zin(wnd)) |win| {
        return if (win.isVisible()) df.TRUE else df.FALSE;
    }
    return df.FALSE;
}
