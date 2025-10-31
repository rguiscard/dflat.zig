const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const lists = @import("Lists.zig");
const Rect = @import("Rect.zig");
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
//        dummy = std.mem.zeroInit(df.window, .{.rc = .{.lf = -1, .tp = -1, .rt = -1, .bt = -1}});
//        dummy = std.mem.zeroInit(df.window, .{});
//        dummyWin = Window.init(&dummy);
//        dummyWin.?.Class = k.DUMMY;
//        dummyWin.?.wndproc = NormalProc; // doesn't seem necessary
//        dummy.zin = @ptrCast(@alignCast(&dummyWin.?));
        dummyWin = Window{
            .Class = k.DUMMY,
            .win = null,
            .wndproc = NormalProc,
        };
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
            rc = Rect.subRectangle(rc, pw.ClientRect());
            pwnd = pw.parent;
        }
    }
    if (Rect.InsideRect(x, y, rc)) {
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
        var rc:Rect = .{.left=0, .top=0, .right=0, .bottom=0};
        if ((that != null) and isVisible(win)) {
            rc = Rect.subRectangle(that.?.WindowRect(), this.?.WindowRect());
            if (Rect.ValidRect(rc) == false) {
                if (app.ApplicationWindow) |awin| {
                    var ffwin = awin.firstWindow();
                    while (ffwin) |ff| {
                        if (isAncestor(win, ff) == false) {
                            rc = Rect.subRectangle(win.WindowRect(),ff.WindowRect());
                            if (Rect.ValidRect(rc)) {
                                break;
                            }
                        }
                        ffwin = ff.nextWindow();
                    }
                }
            }
        }
        if ((that != null) and (Rect.ValidRect(rc)==false) and isVisible(win)) {
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
    win.SetLeft(x);
    win.SetTop(y);
    // be careful, changing the same struct.
    win.SetRight(win.GetLeft()+win.WindowWidth()-1);
    win.SetBottom(win.GetTop()+win.WindowHeight()-1);
    if (win.condition == .ISRESTORED) {
        win.RestoredRC = win.rc;
    }

    var cwin = win.firstWindow();
    while (cwin) |cw| {
        var x_new:usize = cw.GetLeft() + x;
        var y_new:usize = cw.GetTop() + y;
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
    const wasVisible = win.isVisible();

    if ((x == win.GetRight()) and (y == win.GetBottom())) {
        return;
    }
    win.wasCleared = false;
    if (wasVisible) {
        _ = win.sendMessage(df.HIDE_WINDOW, q.none);
    }
    win.SetRight(x);
    win.SetBottom(y);
    win.ht = win.GetBottom()-win.GetTop()+1;
    win.wd = win.GetRight()-win.GetLeft()+1;

    if (win.condition == .ISRESTORED)
        win.RestoredRC = win.WindowRect();

    const rc = win.ClientRect();

    var cwin = win.firstWindow();
    while (cwin) |cw| {
        if (cw.condition == .ISMAXIMIZED) {
            _ = cw.sendMessage(df.SIZE, .{.position=.{rc.right, rc.bottom}});
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
    var rc:Rect = .{.left=0, .top=0, .right=0, .bottom=0};
    const holdrc = win.RestoredRC;
    rc.right = @intCast(df.SCREENWIDTH-1);
    rc.bottom = @intCast(df.SCREENHEIGHT-1);
    if (win.parent) |pw| {
        rc = pw.ClientRect();
    }
    win.oldcondition = win.condition;
    win.condition = .ISMAXIMIZED;
    win.wasCleared = false;
    _ = win.sendMessage(df.HIDE_WINDOW, q.none);
    _ = win.sendMessage(df.MOVE, .{.position=.{rc.left, rc.top}});
    _ = win.sendMessage(df.SIZE, .{.position=.{rc.right, rc.bottom}});
    if (win.restored_attrib == 0) {
        win.restored_attrib = win.attrib;
    }
    win.ClearAttribute(df.SHADOW);
    _ = win.sendMessage(df.SHOW_WINDOW, q.none);
    win.RestoredRC = holdrc;
}

// --------- MINIMIZE Message ----------
fn MinimizeMsg(win:*Window) void {
    const holdrc = win.RestoredRC;
    const rc = PositionIcon(win);
    win.oldcondition = win.condition;
    win.condition = .ISMINIMIZED;
    win.wasCleared = false;
    _ = win.sendMessage(df.HIDE_WINDOW, q.none);
    _ = win.sendMessage(df.MOVE, .{.position=.{rc.left, rc.top}});
    _ = win.sendMessage(df.SIZE, .{.position=.{rc.right, rc.bottom}});
    if (win == Window.inFocus) {
        lists.SetNextFocus();
    }
    if (win.restored_attrib == 0) {
        win.restored_attrib = win.attrib;
    }
    win.ClearAttribute( df.SHADOW | df.SIZEABLE | df.HASMENUBAR |
                        df.VSCROLLBAR | df.HSCROLLBAR);
    _ = win.sendMessage(df.SHOW_WINDOW, q.none);
    win.RestoredRC = holdrc;
}

// --------- RESTORE Message ----------
fn RestoreMsg(win:*Window) void {
    const holdrc = win.RestoredRC;
    win.oldcondition = win.condition;
    win.condition = .ISRESTORED;
    win.wasCleared = false;
    _ = win.sendMessage(df.HIDE_WINDOW, q.none);
    win.attrib = win.restored_attrib;
    win.restored_attrib = 0;
    _ = win.sendMessage(df.MOVE, .{.position=.{win.RestoredRC.left, win.RestoredRC.top}});
    win.RestoredRC = holdrc;
    _ = win.sendMessage(df.SIZE, .{.position=.{win.RestoredRC.right, win.RestoredRC.bottom}});
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
                const p1:?Rect = params.paint[0];
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
                if (WindowMoving) {
                    q.PostMessage(win,df.MOVE,.{.position=.{dwin.GetLeft(),dwin.GetTop()}});
                } else {
                    q.PostMessage(win,df.SIZE,.{.position=.{dwin.GetRight(),dwin.GetBottom()}});
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
fn LowerRight(prc:Rect) Rect {
    const rc = Rect{
        .left = prc.right - @as(usize, @intCast(ICONWIDTH)),
        .top = prc.bottom - @as(usize, @intCast(ICONHEIGHT)),
        .right = prc.right - 1,
        .bottom = prc.bottom - 1,
    };
    return rc;
}

// ----- compute a position for a minimized window icon ----
fn PositionIcon(win:*Window) Rect {
    var rc = Rect{
        .left = @as(usize, @intCast(df.SCREENWIDTH-ICONWIDTH)),
        .top = @as(usize, @intCast(df.SCREENHEIGHT-ICONHEIGHT)),
        .right = @as(usize, @intCast(df.SCREENWIDTH-1)),
        .bottom = @as(usize, @intCast(df.SCREENHEIGHT-1)),
    };

    if (win.parent) |pwin| {
        const prc = pwin.WindowRect();
        var cwin = pwin.firstWindow();
        rc = LowerRight(prc); // this makes previosu assignment useless ?
        // - search for icon available location -
        while (cwin) |cw| {
            if (cw.condition == .ISMINIMIZED) {
                const rc1 = cw.WindowRect();
                if (rc1.left == rc.left and rc1.top == rc.top) {
                    rc.left -|= @as(usize, @intCast(ICONWIDTH));
                    rc.right -|= @as(usize, @intCast(ICONWIDTH));
                    if (rc.left < prc.left+1) {
                        rc.left = prc.right-@as(usize, @intCast(ICONWIDTH));
                        rc.right = rc.left+@as(usize, @intCast(ICONWIDTH-1));
                        rc.top -|= @as(usize, @intCast(ICONHEIGHT));
                        rc.bottom -|= @as(usize, @intCast(ICONHEIGHT));
                        if (rc.top < prc.top+1)
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
    RestoreBorder(dwin.WindowRect());
    WindowMoving = false;
    WindowSizing = false;
}

// ---- build a dummy window border for moving or sizing ---
fn dragborder(win:*Window, x:usize, y:usize) void {
    const dwin = getDummy();

    RestoreBorder(dwin.WindowRect());
    // ------- build the dummy window --------
    dwin.SetLeft(x);
    dwin.SetTop(y);
    dwin.SetRight(dwin.GetLeft()+win.WindowWidth()-1);
    dwin.SetBottom(dwin.GetTop()+win.WindowHeight()-1);
    dwin.ht = win.WindowHeight();
    dwin.wd = win.WindowWidth();
    dwin.parent = win.parent;
    dwin.attrib = df.VISIBLE | df.HASBORDER | df.NOCLIP;
    dwin.InitWindowColors();
    SaveBorder(dwin.WindowRect());
    dwin.RepaintBorder(null);
}

// ---- write the dummy window border for sizing ----
fn sizeborder(win:*Window, rt:usize, bt:usize) void {
    const dwin = getDummy();

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
        RestoreBorder(dwin.WindowRect());

    // ------- change the dummy window --------
    dwin.ht = bt-dwin.GetTop()+1;
    dwin.wd = rt-dwin.GetLeft()+1;
    dwin.SetRight(new_rt);
    dwin.SetBottom(new_bt);
    if ((new_rt != px) or (new_bt != py)) {
        px = @intCast(new_rt);
        py = @intCast(new_bt);
        SaveBorder(dwin.WindowRect());
        dwin.RepaintBorder(null);
    }
}

// ----- adjust a rectangle to include the shadow -----
fn adjShadow(win:*Window) Rect {
    var rc = win.WindowRect();
    if (win.TestAttribute(df.SHADOW)) {
        if (rc.right < df.SCREENWIDTH-1)
            rc.right += 1;
        if (rc.bottom < df.SCREENHEIGHT-1)
            rc.bottom += 1;
    }
    return rc;
}

// --- repaint a rectangular subsection of a window ---
fn PaintOverLap(win:*Window, rc:Rect) void {
    if (isVisible(win)) {
        var isBorder = false;
        var isTitle = false;
        var isData = true;
        if (win.TestAttribute(df.HASBORDER)) {
            isBorder =  rc.left == 0 and
                        rc.top < win.WindowHeight();
            isBorder |= rc.left < win.WindowWidth() and
                        rc.right >= win.WindowWidth()-1 and
                        rc.top < win.WindowHeight();
            isBorder |= rc.top == 0 and
                        rc.left < win.WindowWidth();
            isBorder |= rc.top < win.WindowHeight() and
                        rc.bottom >= win.WindowHeight()-1 and
                        rc.left < win.WindowWidth();
        } else if (win.TestAttribute(df.HASTITLEBAR)) {
            isTitle = rc.top == 0 and
                      rc.right > 0 and
                      rc.left < win.WindowWidth()-win.BorderAdj();
        }

        if (rc.left >= win.WindowWidth()-win.BorderAdj())
            isData = false;
        if (rc.top >= win.WindowHeight()-win.BottomBorderAdj())
            isData = false;
        if (win.TestAttribute(df.HASBORDER)) {
            if (rc.right == 0)
                isData = false;
            if (rc.bottom == 0)
                isData = false;
        }
        if (win.TestAttribute(df.SHADOW))
            isBorder |= rc.right == win.WindowWidth() or
                        rc.bottom == win.WindowHeight();
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
    const wrc = adjShadow(HiddenWindow);
    var rc = adjShadow(win);
    rc = Rect.subRectangle(rc, wrc);
    if (Rect.ValidRect(rc))
        PaintOverLap(win, Rect.RelativeWindowRect(win, rc));
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
fn SaveBorder(rect:Rect) void {
    Bht = rect.bottom - rect.top + 1;
    Bwd = rect.right - rect.left + 1;

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
        var lrc = rect;
        lrc.bottom = lrc.top;
        video.getvideo(lrc, buf[0..]);
        lrc.top = rect.bottom;
        lrc.bottom = rect.bottom;
        video.getvideo(lrc, buf[Bwd..]);
        var pos:usize = Bwd*2;
        for (1..Bht-1) |idx| {
            buf[pos] = video.GetVideoChar(rect.left, rect.top+idx);
            pos += 1;
            buf[pos] = video.GetVideoChar(rect.right, rect.top+idx);
            pos += 1;
        }
    }
}

// ---- restore video area used by dummy window border ---- 
fn RestoreBorder(rect:Rect) void {
    if (Bsave) |buf| {
        var lrc = rect;
        lrc.bottom = lrc.top;
        video.storevideo(lrc, buf[0..]);
        lrc.top = rect.bottom;
        lrc.bottom = rect.bottom;
        video.storevideo(lrc, buf[Bwd..]);
        var pos:usize = Bwd*2;
        for (1..Bht-1) |idx| {
            video.PutVideoChar(rect.left, rect.top+idx, buf[pos]);
            pos += 1;
            video.PutVideoChar(rect.right, rect.top+idx, buf[pos]);
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
fn ClipRect(win:*Window) Rect {
    var rc = win.WindowRect();
    if (win.TestAttribute(df.SHADOW)) {
        rc.bottom += 1;
        rc.right += 1;
    }
    return Rect.ClipRectangle(win, rc);
}

// -- get the video memory that is to be used by a window --
fn GetVideoBuffer(win:*Window) void {
    const rc:Rect = ClipRect(win);
    const ht:usize = rc.bottom - rc.top + 1;
    const wd:usize = rc.right - rc.left + 1;
    if (win.videosave) |videosave| {
        if (root.global_allocator.realloc(videosave, ht * wd)) |buf| {
            win.videosave = buf;
        } else |_| {
        }
    } else {
        if (root.global_allocator.alloc(u16, ht * wd)) |buf| {
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
