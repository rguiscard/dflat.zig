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
const video = @import("Video.zig");

const ICONHEIGHT = 3;
const ICONWIDTH = 10;

var dummyWin:?Window = null;
var dummy:df.window = undefined; // need to be static or it will crash;
var px:c_int = -1;
var py:c_int = -1;
var diff:usize = 0;
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
    const rtn = q.SendMessage(null, df.MOUSE_INSTALLED, q.none);
    if (rtn == false) {
        win.ClearAttribute(df.VSCROLLBAR | df.HSCROLLBAR);
    }
    if (win.TestAttribute(df.SAVESELF) and isVisible(win)) {
        GetVideoBuffer(win);
    }
}

// --------- SHOW_WINDOW Message ----------
fn ShowWindowMsg(win:*Window) void {
    if (win.parent == null or isVisible(win.getParent())) {
        if (win.TestAttribute(df.SAVESELF) and
                        (win.videosave == null)) {
            GetVideoBuffer(win);
        }
        win.SetVisible();

        _ = win.sendMessage(df.PAINT, .{.paint=.{null, true}});
        _ = win.sendMessage(df.BORDER, .{.paint=.{null, false}});
        // --- show the children of this window ---
        var cwin = win.firstWindow();
        while (cwin) |cw| {
            if (cw.condition != .ISCLOSING) {
                _ = cw.sendMessage(df.SHOW_WINDOW, q.none);
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
fn InsideWindow(win:*Window, x:usize, y:usize) bool {
    var rc = win.WindowRect();
    if (win.TestAttribute(df.NOCLIP))    {
        var pwnd = win.parent;
        while (pwnd) |pw| {
            rc = df.subRectangle(rc, rect.ClientRect(pw));
            pwnd = pw.parent;
        }
    }
    if (rect.InsideRect(@intCast(x), @intCast(y), rc)) {
        return true;
    }
    return false;
}

// --------- KEYBOARD Message ----------
fn KeyboardMsg(win:*Window, p1:u16, p2:u8) bool {
    const dwin = getDummy();
    if (WindowMoving or WindowSizing) {
        // -- move or size a window with keyboard --
        var x:usize= if (WindowMoving) dwin.GetLeft() else dwin.GetRight();
        var y:usize= if (WindowMoving) dwin.GetTop() else dwin.GetBottom();
        switch (p1)    {
            df.ESC => {
                TerminateMoveSize();
                return true;
            },
            df.UP => {
                y -|= 1;
            },
            df.DN => {
                if (y < df.SCREENHEIGHT-1)
                    y +|= 1;
            },
            df.FWD => {
                if (x < df.SCREENWIDTH-1)
                    x +|= 1;
            },
            df.BS => {
                x -|= 1;
            },
            '\r' => {
                _ = win.sendMessage(df.BUTTON_RELEASED,.{.position=.{x, y}});
            },
            else => {
                return true;
            }
        }
        _ = win.sendMessage(df.MOUSE_CURSOR, .{.position=.{x, y}});
        _ = win.sendMessage(df.MOUSE_MOVED, .{.position=.{x, y}});
        return true;
    }
    switch (p1) {
        df.F1 => {
            _ = win.sendCommandMessage(c.ID_HELP, 0);
            return true;
        },
        ' ' => {
            if ((p2 & df.ALTKEY) > 0) {
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
                _ = win.sendMessage(df.CLOSE_WINDOW, .{.yes=false});
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
fn CommandMsg(win:*Window, p1:c) void {
    const dwin = getDummy();
    const cmd:c = p1;
    switch (cmd) {
        .ID_SYSMOVE => {
            _ = win.sendMessage(df.CAPTURE_MOUSE, .{.capture=.{true, dwin}});
            _ = win.sendMessage(df.CAPTURE_KEYBOARD, .{.capture=.{true, dwin}});
            _ = win.sendMessage(df.MOUSE_CURSOR, .{.position=.{win.GetLeft(), win.GetTop()}});
            WindowMoving = true;
            dragborder(win, win.GetLeft(), win.GetTop());
        },
        .ID_SYSSIZE => {
            _ = win.sendMessage(df.CAPTURE_MOUSE, .{.capture=.{true, dwin}});
            _ = win.sendMessage(df.CAPTURE_KEYBOARD, .{.capture=.{true, dwin}});
            _ = win.sendMessage(df.MOUSE_CURSOR, .{.position=.{win.GetRight(), win.GetBottom()}});
            WindowSizing = true;
            dragborder(win, win.GetLeft(), win.GetTop());
        },
        .ID_SYSCLOSE => {
            _ = win.sendMessage(df.CLOSE_WINDOW, .{.yes=false});
            lists.SkipApplicationControls();
        },
        .ID_SYSRESTORE => {
            _ = win.sendMessage(df.RESTORE, q.none);
        },
        .ID_SYSMINIMIZE => {
            _ = win.sendMessage(df.MINIMIZE, q.none);
        },
        .ID_SYSMAXIMIZE => {
            _ = win.sendMessage(df.MAXIMIZE, q.none);
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
fn SetFocusMsg(win:*Window, yes:bool) void {
    var rc:df.RECT = .{.lf=0, .tp=0, .rt=0, .bt=0};
    if (yes and (Window.inFocus != win)) {
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
            _ = focus.sendMessage(df.SETFOCUS, .{.yes=false});
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
            _ = this.?.sendMessage(df.SHOW_WINDOW, q.none);
        } else if (isVisible(win) == false) {
            _ = win.sendMessage(df.SHOW_WINDOW, q.none);
        } else {
            _ = win.sendMessage(df.BORDER, .{.paint=.{null, false}});
        }
    }
    else if (yes == false and Window.inFocus == win) {
        // -------- clearing focus ---------
        Window.inFocus = null;
        _ = win.sendMessage(df.BORDER, .{.paint=.{null, false}});
    }
}

// --------- DOUBLE_CLICK Message ----------
fn DoubleClickMsg(win:*Window, x:usize, y:usize) void {
    const mx:usize = if (x > win.GetLeft()) x - win.GetLeft() else 0;
    const my:usize = if (y > win.GetTop()) y - win.GetTop() else 0;
    if ((WindowSizing == false) and (WindowMoving == false)) {
        if (win.HitControlBox(mx, my)) {
            q.PostMessage(win, df.CLOSE_WINDOW, .{.yes=false});
            lists.SkipApplicationControls();
        }
    }
}

// --------- LEFT_BUTTON Message ----------
fn LeftButtonMsg(win:*Window, x:usize, y:usize) void {
    const dwin = getDummy();
    const mx:usize = if (x > win.GetLeft()) x - win.GetLeft() else 0;
    const my:usize = if (y > win.GetTop()) y - win.GetTop() else 0;
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
                    _ = win.sendMessage(df.RESTORE, q.none);
                } else {
                    // --- hit the maximize box ---
                    _ = win.sendMessage(df.MAXIMIZE, q.none);
                }
                return;
            }
            if (mx == win.WindowWidth()-3) {
                // --- hit the minimize box ---
                if (win.condition != .ISMINIMIZED) {
                    _ = win.sendMessage(df.MINIMIZE, q.none);
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
            diff = mx;
            _ = win.sendMessage(df.CAPTURE_MOUSE, .{.capture=.{true, dwin}});
            dragborder(win, win.GetLeft(), win.GetTop());
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
        _ = ww.sendMessage(df.CAPTURE_MOUSE, .{.capture=.{true, dwin}});
        dragborder(ww, ww.GetLeft(), ww.GetTop());
    }
}

// --------- MOUSE_MOVED Message ----------
fn MouseMovedMsg(win:*Window, p1:usize, p2:usize) bool {
    if (WindowMoving) {
        var leftmost:usize = 0;
        var topmost:usize = 0;
        var bottommost:usize = @intCast(df.SCREENHEIGHT-2);
        var rightmost:usize = @intCast(df.SCREENWIDTH-2);
        var x:usize = if (p1 > diff) p1 - diff else 0;
        var y:usize = p2;
        if ((win.parent != null) and
                (win.TestAttribute(df.NOCLIP) == false)) {
            const win1 = win.getParent();
            topmost    = win1.GetClientTop();
            leftmost   = win1.GetClientLeft();
            bottommost = win1.GetClientBottom();
            rightmost  = win1.GetClientRight();
        }
        if ((x < leftmost) or (x > rightmost) or
                (y < topmost) or (y > bottommost))    {
            x = @max(x, leftmost);
            x = @min(x, rightmost);
            y = @max(y, topmost);
            y = @min(y, bottommost);
            _ = q.SendMessage(null,df.MOUSE_CURSOR,.{.position=.{x+diff, y}});
        }
        if ((x != px) or  (y != py))    {
            px = @intCast(x);
            py = @intCast(y);
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
fn MoveMsg(win:*Window, x:usize, y:usize) void {
    const wnd = win.win;
    const wasVisible = win.isVisible();

    const win_x:usize = win.GetLeft();
    const win_y:usize = win.GetTop();

    if ((x == win_x) and (y == win_y)) {
        return;
    }
    win.wasCleared = false;
    if (wasVisible) {
        _ = win.sendMessage(df.HIDE_WINDOW, q.none);
    }
    wnd.*.rc.lf = @intCast(x);
    wnd.*.rc.tp = @intCast(y);
    // be careful, changing the same struct.
    wnd.*.rc.rt = @intCast(win.GetLeft()+win.WindowWidth()-1);
    wnd.*.rc.bt = @intCast(win.GetTop()+win.WindowHeight()-1);
    if (win.condition == .ISRESTORED) {
        wnd.*.RestoredRC = wnd.*.rc;
    }

    var cwin = win.firstWindow();
    while (cwin) |cw| {
        const cwnd = cw.win;

        var x_new:usize = @as(usize, @intCast(cwnd.*.rc.lf)) + x;
        var y_new:usize = @as(usize, @intCast(cwnd.*.rc.tp)) + y;
        x_new -|= win_x;
        y_new -|= win_y;
        _ = cw.sendMessage(df.MOVE, .{.position=.{x_new, y_new}});

        cwin = cw.nextWindow();
    }
    if (wasVisible)
        _ = win.sendMessage(df.SHOW_WINDOW, q.none);
}


// --------- SIZE Message ----------
fn SizeMsg(win:*Window, x:usize, y:usize) void {
    const wnd = win.win;
    const wasVisible = win.isVisible();

    if ((x == win.GetRight()) and (y == win.GetBottom())) {
        return;
    }
    win.wasCleared = false;
    if (wasVisible) {
        _ = win.sendMessage(df.HIDE_WINDOW, q.none);
    }
    wnd.*.rc.rt = @intCast(x);
    wnd.*.rc.bt = @intCast(y);
    win.ht = win.GetBottom()-win.GetTop()+1;
    win.wd = win.GetRight()-win.GetLeft()+1;

    if (win.condition == .ISRESTORED)
        wnd.*.RestoredRC = df.WindowRect(wnd);

    const rc = rect.ClientRect(win);

    var cwin = win.firstWindow();
    while (cwin) |cw| {
        if (cw.condition == .ISMAXIMIZED) {
            _ = cw.sendMessage(df.SIZE, .{.position=.{@intCast(rc.rt), @intCast(rc.bt)}});
        }
        cwin = cw.nextWindow();
    }

    if (wasVisible)
        _ = win.sendMessage(df.SHOW_WINDOW, q.none);
}

// --------- CLOSE_WINDOW Message ----------
fn CloseWindowMsg(win:*Window) void {
    const wnd = win.win;
    win.condition = .ISCLOSING;
    // ----------- hide this window ------------
    _ = win.sendMessage(df.HIDE_WINDOW, q.none);

    // --- close the children of this window ---
    var cwin = win.lastWindow();
    while (cwin) |cw| {
        if (Window.inFocus == cw) {
            Window.inFocus = win;
        }
        _ = cw.sendMessage(df.CLOSE_WINDOW, .{.yes=false});
        cwin = win.lastWindow();
    }

    // ----- release captured resources ------
    if (win.PrevClock) |_| {
        _ = win.sendMessage(df.RELEASE_CLOCK, q.none);
    }
    if (win.PrevMouse) |_| {
        _ = win.sendMessage(df.RELEASE_MOUSE, .{.capture=.{false, null}});
    }
    if (win.PrevKeyboard) |_| {
        _ = win.sendMessage(df.RELEASE_KEYBOARD, .{.capture=.{false, null}});
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
    _ = win.sendMessage(df.HIDE_WINDOW, q.none);
    _ = win.sendMessage(df.MOVE, .{.position=.{@intCast(rc.lf), @intCast(rc.tp)}});
    _ = win.sendMessage(df.SIZE, .{.position=.{@intCast(rc.rt), @intCast(rc.bt)}});
    if (win.restored_attrib == 0) {
        win.restored_attrib = win.attrib;
    }
    win.ClearAttribute(df.SHADOW);
    _ = win.sendMessage(df.SHOW_WINDOW, q.none);
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
    _ = win.sendMessage(df.HIDE_WINDOW, q.none);
    _ = win.sendMessage(df.MOVE, .{.position=.{@intCast(rc.lf), @intCast(rc.tp)}});
    _ = win.sendMessage(df.SIZE, .{.position=.{@intCast(rc.rt), @intCast(rc.bt)}});
    if (win == Window.inFocus) {
        lists.SetNextFocus();
    }
    if (win.restored_attrib == 0) {
        win.restored_attrib = win.attrib;
    }
    win.ClearAttribute( df.SHADOW | df.SIZEABLE | df.HASMENUBAR |
                        df.VSCROLLBAR | df.HSCROLLBAR);
    _ = win.sendMessage(df.SHOW_WINDOW, q.none);
    wnd.*.RestoredRC = holdrc;
}

// --------- RESTORE Message ----------
fn RestoreMsg(win:*Window) void {
    const wnd = win.win;
    const holdrc = wnd.*.RestoredRC;
    win.oldcondition = win.condition;
    win.condition = .ISRESTORED;
    win.wasCleared = false;
    _ = win.sendMessage(df.HIDE_WINDOW, q.none);
    win.attrib = win.restored_attrib;
    win.restored_attrib = 0;
    _ = win.sendMessage(df.MOVE, .{.position=.{@intCast(wnd.*.RestoredRC.lf), @intCast(wnd.*.RestoredRC.tp)}});
    wnd.*.RestoredRC = holdrc;
    _ = win.sendMessage(df.SIZE, .{.position=.{@intCast(wnd.*.RestoredRC.rt), @intCast(wnd.*.RestoredRC.bt)}});
    if (win != Window.inFocus) {
        _ = win.sendMessage(df.SETFOCUS, .{.yes=true});
    } else {
        _ = win.sendMessage(df.SHOW_WINDOW, q.none);
    }
}

pub fn NormalProc(win:*Window, msg: df.MESSAGE, params:q.Params) bool {
    switch (msg) {
        df.CREATE_WINDOW => {
            CreateWindowMsg(win);
        },
        df.SHOW_WINDOW => {
            ShowWindowMsg(win);
        },
        df.HIDE_WINDOW => {
            HideWindowMsg(win);
        },
        df.INSIDE_WINDOW => {
            const p1:usize = params.position[0];
            const p2:usize = params.position[1];
            return InsideWindow(win, p1, p2);
        },
        df.KEYBOARD => {
            const p1:u16 = params.char[0];
            const p2:u8 = params.char[1];
            if (KeyboardMsg(win, p1, p2))
                return true;
            // ------- fall through -------
            if (win.parent) |pw| {
                q.PostMessage(pw, msg, params);
            }
        },
        df.ADDSTATUS, df.SHIFT_CHANGED => {
            if (win.parent) |pw| {
                q.PostMessage(pw, msg, params);
            }
        },
        df.PAINT => {
            if (isVisible(win)) {
                if (win.wasCleared) {
                    PaintUnderLappers(win);
                } else {
                    win.wasCleared = true;
                    win.ClearWindow(params.paint[0], ' '); // pp1 can be null
                }
            }
        },
        df.BORDER => {
            if (isVisible(win)) {
                const p1:?df.RECT = params.paint[0];
                if (win.TestAttribute(df.HASBORDER)) {
                    win.RepaintBorder(p1);
                } else if (win.TestAttribute(df.HASTITLEBAR)) {
                    win.DisplayTitle(p1);
                }
            }
        },
        df.COMMAND => {
            const p1:c = params.command[0];
            CommandMsg(win, p1);
        },
        df.SETFOCUS => {
            SetFocusMsg(win, params.yes);
        },
        df.DOUBLE_CLICK => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            DoubleClickMsg(win, p1, p2);
        },
        df.LEFT_BUTTON => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            LeftButtonMsg(win, p1, p2);
        },
        df.MOUSE_MOVED => {
            const x = params.position[0];
            const y = params.position[1];
            if (MouseMovedMsg(win, x, y)) {
                return true;
            }
        },
        df.BUTTON_RELEASED => {
            if (WindowMoving or WindowSizing) {
                const dwin = getDummy();
                const dwnd = dwin.win;
                if (WindowMoving) {
                    q.PostMessage(win,df.MOVE,.{.position=.{@intCast(dwnd.*.rc.lf),@intCast(dwnd.*.rc.tp)}});
                } else {
                    q.PostMessage(win,df.SIZE,.{.position=.{@intCast(dwnd.*.rc.rt),@intCast(dwnd.*.rc.bt)}});
                }
                TerminateMoveSize();
            }
        },
        df.MOVE => {
            const x = params.position[0];
            const y = params.position[1];
            MoveMsg(win, x, y);
        },
        df.SIZE => {
            const x = params.position[0];
            const y = params.position[1];
            SizeMsg(win, x, y);
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
                    _ = win.sendMessage(df.MAXIMIZE, q.none);
                } else {
                    RestoreMsg(win);
                }
            }
        },
        df.DISPLAY_HELP => {
            const p1:[]const u8 = params.slice;
            return helpbox.DisplayHelp(win, p1);
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
    _ = dwin.sendMessage(df.RELEASE_MOUSE, .{.capture=.{true, null}});
    _ = dwin.sendMessage(df.RELEASE_KEYBOARD, .{.capture=.{true, null}});
    RestoreBorder(dwin.win.*.rc);
    WindowMoving = false;
    WindowSizing = false;
}

// ---- build a dummy window border for moving or sizing ---
fn dragborder(win:*Window, x:usize, y:usize) void {
    const dwin = getDummy();
    const dwnd = dwin.win;

    RestoreBorder(dwnd.*.rc);
    // ------- build the dummy window --------
    dwnd.*.rc.lf = @intCast(x);
    dwnd.*.rc.tp = @intCast(y);
    dwnd.*.rc.rt = dwnd.*.rc.lf+@as(c_int, @intCast(win.WindowWidth()))-1;
    dwnd.*.rc.bt = dwnd.*.rc.tp+@as(c_int, @intCast(win.WindowHeight()))-1;
    dwin.ht = win.WindowHeight();
    dwin.wd = win.WindowWidth();
    dwin.parent = win.parent;
    dwin.attrib = df.VISIBLE | df.HASBORDER | df.NOCLIP;
    dwin.InitWindowColors();
    SaveBorder(dwnd.*.rc);
    dwin.RepaintBorder(null);
}

// ---- write the dummy window border for sizing ----
fn sizeborder(win:*Window, rt:usize, bt:usize) void {
    const dwin = getDummy();
    const dwnd = dwin.win;

    const leftmost:usize = win.GetLeft()+10;
    const topmost:usize = win.GetTop()+3;
    var bottommost:usize = @intCast(df.SCREENHEIGHT-1);
    var rightmost:usize = @intCast(df.SCREENWIDTH-1);
    if (win.parent) |pwin| {
        bottommost = @min(bottommost, pwin.GetClientBottom());
        rightmost  = @min(rightmost, pwin.GetClientRight());
    }
    var new_rt:usize = @min(rt, rightmost);
    var new_bt:usize = @min(bt, bottommost);
    new_rt = @max(new_rt, leftmost);
    new_bt = @max(new_bt, topmost);
    _ = q.SendMessage(null, df.MOUSE_CURSOR, .{.position=.{new_rt, new_bt}});

    if ((new_rt != px) or (new_bt != py))
        RestoreBorder(dwnd.*.rc);

    // ------- change the dummy window --------
    dwin.ht = bt-@as(usize, @intCast(dwnd.*.rc.tp))+1;
    dwin.wd = rt-@as(usize, @intCast(dwnd.*.rc.lf))+1;
    dwnd.*.rc.rt = @intCast(new_rt);
    dwnd.*.rc.bt = @intCast(new_bt);
    if ((new_rt != px) or (new_bt != py)) {
        px = @intCast(new_rt);
        py = @intCast(new_bt);
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
            _ = win.sendMessage(df.PAINT, .{.paint=.{rc, true}});
        }
        if (isBorder) {
            _ = win.sendMessage(df.BORDER, .{.paint=.{rc, false}});
        } else if (isTitle) {
            win.DisplayTitle(rc);
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
        video.getvideo(lrc, buf[0..]);
        lrc.tp = rc.bt;
        lrc.bt = rc.bt;
        video.getvideo(lrc, buf[Bwd..]);
        var pos:usize = Bwd*2;
        for (1..Bht-1) |idx| {
            const i:c_int = @intCast(idx);
            buf[pos] = video.GetVideoChar(@intCast(rc.lf), @intCast(rc.tp+i));
            pos += 1;
            buf[pos] = video.GetVideoChar(@intCast(rc.rt), @intCast(rc.tp+i));
            pos += 1;
        }
    }
}

// ---- restore video area used by dummy window border ---- 
fn RestoreBorder(rc:df.RECT) void {
    if (Bsave) |buf| {
        var lrc = rc;
        lrc.bt = lrc.tp;
        video.storevideo(lrc, buf[0..]);
        lrc.tp = rc.bt;
        lrc.bt = rc.bt;
        video.storevideo(lrc, buf[Bwd..]);
        var pos:usize = @intCast(Bwd*2);
        for (1..Bht-1) |idx| {
            const i:c_int = @intCast(idx);
            video.PutVideoChar(@intCast(rc.lf), @intCast(rc.tp+i), buf[pos]);
            pos += 1;
            video.PutVideoChar(@intCast(rc.rt), @intCast(rc.tp+i), buf[pos]);
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
        if (root.global_allocator.realloc(videosave, @intCast(ht * wd))) |buf| {
            win.videosave = buf;
        } else |_| {
        }
    } else {
        if (root.global_allocator.alloc(u16, @intCast(ht * wd))) |buf| {
            win.videosave = buf;
        } else |_| {
        }
    }
    if (win.videosave) |videosave| {
        video.get_videomode();
        video.getvideo(rc, videosave);
    }
}

// -- put the video memory that is used by a window --
fn PutVideoBuffer(win:*Window) void {
    if (win.videosave) |videosave| {
        const rc = ClipRect(win);
        video.get_videomode();
        video.storevideo(rc, videosave);
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

//pub export fn c_isVisible(wnd:df.WINDOW) df.BOOL {
//    if (Window.get_zin(wnd)) |win| {
//        return if (win.isVisible()) df.TRUE else df.FALSE;
//    }
//    return df.FALSE;
//}
