const std = @import("std");
const df = @import("ImportC.zig").df;
const k = @import("Classes.zig").CLASS;
const root = @import("root.zig");
const Window = @import("Window.zig");
const log = @import("Log.zig");
const clipboard = @import("Clipboard.zig");
const DialogBox = @import("DialogBox.zig");
const rect = @import("Rect.zig");
const normal = @import("Normal.zig");
const app = @import("Application.zig");

const MAXMESSAGES = 100;

var Cwnd:?*Window = null;
var clocktimer:c_int = -1;
var lagdelay:c_int = df.FIRSTDELAY; // not in use
var handshaking = false; // not in use

pub var CaptureMouse:?*Window = null;
pub var CaptureKeyboard:?*Window = null;
var NoChildCaptureMouse = false;
var NoChildCaptureKeyboard = false;

export var AltDown:df.BOOL = df.FALSE;

// ---------- event queue ----------
const Evt = struct {
    event:df.MESSAGE,
    mx:c_int,
    my:c_int,
};

var EventQueue = [_]Evt{.{.event=0, .mx=0, .my=0}}**MAXMESSAGES;

var EventQueueOnCtr:usize = 0;
var EventQueueOffCtr:usize = 0;
var EventQueueCtr:usize = 0;

// ---------- message queue ---------
const Msg = struct {
    win:?*Window,
    msg:df.MESSAGE,
    p1:df.PARAM,
    p2:df.PARAM,
};

var MsgQueue = [_]Msg{.{.win=null, .msg=0, .p1=0, .p2=0}}**MAXMESSAGES;

var MsgQueueOnCtr:usize = 0;
var MsgQueueOffCtr:usize = 0;
var MsgQueueCtr:usize = 0;

// ------------ initialize the message system ---------
pub fn init_messages() bool {
    var cols:c_int = 0;
    var rows:c_int = 0;

    df.AllocTesting = df.TRUE;
    if (df.setjmp(&df.AllocError) != 0) {
        StopMsg();
        return false;
    }

    _ = df.tty_init(df.MouseTracking|df.CatchISig|df.ExitLastLine|df.FullBuffer);
    if (df.tty_getsize(&cols, &rows) > 0) {
        df.SCREENWIDTH = @min(cols, df.MAXCOLS-1);
        df.SCREENHEIGHT = rows - 1;
    }

    df.resetmouse();
    df.set_mousetravel(0, df.SCREENWIDTH-1, 0, df.SCREENHEIGHT-1);
    df.savecursor();
    df.hidecursor();

    CaptureMouse = null;
    CaptureKeyboard = null;

    NoChildCaptureMouse = false;
    NoChildCaptureKeyboard = false;
    PostMessage(null,df.START,0,0);
//    lagdelay = FIRSTDELAY; // not in use
    return true;
}

fn StopMsg() void {
    clipboard.ClearClipboard();
    DialogBox.ClearDialogBoxes();
    df.restorecursor();
    df.unhidecursor();
    df.hide_mousecursor();
}

// ----- post an event and parameters to event queue ----
pub export fn PostEvent(event:df.MESSAGE, p1:c_int, p2:c_int) callconv(.c) void {
    if (EventQueueCtr != MAXMESSAGES) {
        EventQueue[EventQueueOnCtr].event = event;
        EventQueue[EventQueueOnCtr].mx = p1;
        EventQueue[EventQueueOnCtr].my = p2;
        EventQueueOnCtr += 1;
        if (EventQueueOnCtr == MAXMESSAGES) {
            EventQueueOnCtr = 0;
        }
        EventQueueCtr += 1;
    }
}

// ----- post a message and parameters to msg queue ----
pub fn PostMessage(win:?*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) void {
    if (MsgQueueCtr != MAXMESSAGES) {
        MsgQueue[MsgQueueOnCtr].win = win;
        MsgQueue[MsgQueueOnCtr].msg = msg;
        MsgQueue[MsgQueueOnCtr].p1 = p1;
        MsgQueue[MsgQueueOnCtr].p2 = p2;
        MsgQueueOnCtr += 1;
        if (MsgQueueOnCtr == MAXMESSAGES) {
            MsgQueueOnCtr = 0;
        }
        MsgQueueCtr += 1;
    }
}

// --------- send a message to a window -----------
pub export fn SendMessage(wnd: df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) df.BOOL {
    const rtn = true;

    if (wnd != null) {
        if (Window.get_zin(wnd)) |win| {
            return if (win.sendMessage(msg, p1, p2)) df.TRUE else df.FALSE;
        } else {
            // This shouldn't happen, except dummy window at normal.c for now.
            // Or we can create a Window instance for it here.
            if (root.global_allocator.create(Window)) |win| {
                win.* = Window.init(wnd);
                wnd.*.zin = @constCast(win);
                // Should call sendMessage() for it ?
                // Segment fault if call sendMessage(), seems ok to call ProcessMessage().
                return if (ProcessMessage(win, msg, p1, p2, rtn)) df.TRUE else df.FALSE;
            } else |_| {
                // error
            }

            // Should rtn be TRUE or FALSE or call sendMessage() ?
//            if (Window.GetClass(wnd) != @intFromEnum(k.DUMMY)) {
//                // Try to catch any window which is not dummy nor created by Window.create()
//                _ = df.printf("Not dummy !! \n");
//                while(true) {}
//                return df.FALSE;
//            }
        }
    }

    // ----- window processor returned true or the message was sent
    //  to no window at all (NULL) -----
    return if (ProcessMessage(null, msg, p1, p2, rtn)) df.TRUE else df.FALSE;
}

pub fn ProcessMessage(win:?*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM, rtn:bool) bool {
    log.LogMessages(win, msg, p1, p2);

    var rrtn = rtn;

    // ----- window processor returned true or the message was sent
    //  to no window at all (NULL) -----
    if (rrtn) {
        // --------- process messages that a window sends to the
        //  system itself ----------
        switch (msg) {
            df.STOP => {
                StopMsg();
            },
            // ------- clock messages ---------
            df.CAPTURE_CLOCK => {
                if (Cwnd == null) {
                     const secs:c_int = 0;
                     clocktimer=(secs)*182/10+1;
//                    df.set_timer(clocktimer, 0);
                }
                if (win) |w| {
                    w.PrevClock = Cwnd;
                    Cwnd = w;
                }
            },
            df.RELEASE_CLOCK => {
                if (win) |w| {
                    Cwnd = w.PrevClock;
                }
                if (Cwnd == null)
                    clocktimer = -1;
//                    df.disable_timer(df.clocktimer);
            },
            // -------- keyboard messages -------
            df.KEYBOARD_CURSOR => {
                if (win) |w| {
                    if (w == Window.inFocus) {
                        df.cursor(@intCast(w.GetClientLeft()+p1),
                                  @intCast(w.GetClientTop()+p2));
                    }
                } else {
                    df.cursor(@intCast(p1), @intCast(p2));
                }
            },
            df.CAPTURE_KEYBOARD => {
                if (win) |w| { // wnd is not null
                    if (p2 > 0) {
                        const pp2:usize = @intCast(p2);
                        const p2win:*Window = @ptrFromInt(pp2);
                        p2win.PrevKeyboard = CaptureKeyboard;
                    } else {
                        w.PrevKeyboard = CaptureKeyboard;
                    }
                    CaptureKeyboard = w;
                    NoChildCaptureKeyboard = (p1>0);
                } else { // is this necessary
                    CaptureKeyboard = null;
                    NoChildCaptureKeyboard = false;
                }
            },
            df.RELEASE_KEYBOARD => {
                if (win) |w| { // wnd is not null
                    if (CaptureKeyboard == w or (p1>0)) {
                        CaptureKeyboard = w.PrevKeyboard;
                    } else {
                        var twnd = CaptureKeyboard;
                        while (twnd) |tw| {
                            if (tw.PrevKeyboard == w)  {
                                tw.PrevKeyboard = w.PrevKeyboard;
                                break;
                            }
                            twnd = tw.PrevKeyboard;
                        }
                        if (twnd == null) {
                            CaptureKeyboard = null;
                        }
                    }
                    w.PrevKeyboard = null;
                } else {
                    CaptureKeyboard = null;
                }
                NoChildCaptureKeyboard = false;
            },
            df.CURRENT_KEYBOARD_CURSOR => {
                var x:c_int = 0;
                var y:c_int = 0;
                df.curr_cursor(&x, &y);
                const pp1:usize = @intCast(p1);
                const pp1_ptr:*c_int = @ptrFromInt(pp1);
                const pp2:usize = @intCast(p2);
                const pp2_ptr:*c_int = @ptrFromInt(pp2);
                pp1_ptr.* = x;
                pp2_ptr.* = y;
//                *(int*)p1 = x;
//                *(int*)p2 = y;
            },
            df.SAVE_CURSOR => {
                df.savecursor();
            },
            df.RESTORE_CURSOR => {
                df.restorecursor();
            },
            df.HIDE_CURSOR => {
                df.normalcursor();
                df.hidecursor();
            },
            df.SHOW_CURSOR => {
                if (p1>0) {
                    df.set_cursor_type(0x0106);
                } else {
                    df.set_cursor_type(0x0607);
                }
                df.unhidecursor();
            },
            df.WAITKEYBOARD => {
                // This one does nothing and is marked as FIXME originally.
                // df.waitforkeyboard();
            },
            // -------- mouse messages --------
            df.RESET_MOUSE => {
                df.resetmouse();
                df.set_mousetravel(0, df.SCREENWIDTH-1, 0, df.SCREENHEIGHT-1);
            },
            df.MOUSE_INSTALLED => {
                rrtn = if (df.mouse_installed()>0) true else false;
            },
            df.MOUSE_TRAVEL => {
                var rc:df.RECT = .{.lf = 0, .tp = 0, .rt = 0, .bt = 0};
                if (p1 == 0) {
                    rc.lf = 0;
                    rc.tp = 0;
                    rc.rt = df.SCREENWIDTH-1;
                    rc.bt = df.SCREENHEIGHT-1;
                } else {
                    const pp1:usize = @intCast(p1);
                    const rc_ptr:*df.RECT = @ptrFromInt(pp1);
                    rc = rc_ptr.*;
                }
                df.set_mousetravel(rc.lf, rc.rt, rc.tp, rc.bt);
            },
            df.SHOW_MOUSE => {
                df.show_mousecursor();
            },
            df.HIDE_MOUSE => {
                df.hide_mousecursor();
            },
            df.MOUSE_CURSOR => {
                df.set_mouseposition(@intCast(p1), @intCast(p2));
            },
            df.CURRENT_MOUSE_CURSOR => {
                // df.get_mouseposition((int*)p1,(int*)p2); // do nothing in original code
            },
            df.WAITMOUSE => {
                df.waitformouse();
            },
            df.TESTMOUSE => {
                rrtn = if (df.mousebuttons()>0) true else false;
            },
            df.CAPTURE_MOUSE => {
                if (win) |w| { // wnd is not null
                    if (p2>0) {
                        const pp2:usize = @intCast(p2);
                        const p2win:*Window = @ptrFromInt(pp2);
                        p2win.PrevMouse = CaptureMouse;
                    } else {
                        w.PrevMouse = CaptureMouse;
                    }
                    CaptureMouse = w;
                    NoChildCaptureMouse = (p1>0);
                } else { // is this necessary ?
                    CaptureMouse = null;
                    NoChildCaptureMouse = false;
                }
            },
            df.RELEASE_MOUSE => {
                if (win) |w| {
                    if (CaptureMouse == w or (p1>0)) {
                        CaptureMouse = w.PrevMouse;
                    } else {
                        var twnd = CaptureMouse;
                        while (twnd) |tw| {
                            if (tw.PrevMouse == w) {
                                tw.PrevMouse = w.PrevMouse;
                                break;
                            }
                            twnd = tw.PrevMouse;
                        }
                        if (twnd == null) {
                            CaptureMouse = null;
                        }
                    }
                    w.PrevMouse = null;
                } else {
                    CaptureMouse = null;
                }
                NoChildCaptureMouse = false;
            },
            else => {
            }
        }

    }
    return rrtn;
}

fn VisibleRect(win:*Window) df.RECT {
    var rc = win.WindowRect();
    if (!win.TestAttribute(df.NOCLIP)) {
        if (win.parent) |pw| {
            var prc = rect.ClientRect(pw);
            var pp:?*Window = pw;
            while (pp) |pwin| {
                if (pwin.TestAttribute(df.NOCLIP))
                    break;
                rc = df.subRectangle(rc, prc);
                if (df.ValidRect(rc) == false)
                    break;
                pp = pwin.parent;
                if (pp) |ppw| {
                    prc = rect.ClientRect(ppw);
                }
            }
        } else {
            return rc;
        }
    }
    return rc;
}


// ----- find window that mouse coordinates are in ---
fn inWindow(w:?*Window, x:c_int, y:c_int) ?*Window {
    var ww = w;
    var Hit:?*Window = null;
    while (ww) |win| {
        if (win.isVisible()) {
            const rc = VisibleRect(win);
            if (rect.InsideRect(x, y, rc))
                Hit = win;
            const win1 = inWindow(win.lastWindow(), x, y);
            if (win1 != null)
                Hit = win1;
            if (Hit != null)
                break;
        }
        ww = win.prevWindow();
    }
    return Hit;
}

fn MouseWindow(x:c_int, y:c_int) ?*Window {
    // ------ get the window in which a
    //              mouse event occurred ------
    if (app.ApplicationWindow) |awin| {
        var Mwnd = inWindow(awin, x, y);
        // ---- process mouse captures -----
        if (CaptureMouse) |capture| {
            if (NoChildCaptureMouse or
                                    Mwnd == null  or
                                    normal.isAncestor(Mwnd.?, capture) == false)
                Mwnd = capture;
        }
        return Mwnd;
    }
    return null; // unreachable
}

//void handshake(void)
//{
//#if MSDOS
//        handshaking++;
//        dispatch_message();
//        --handshaking;
//#endif
//}

// ---- dispatch messages to the message proc function ----
pub fn dispatch_message() bool {
    // -------- collect mouse and keyboard events -------
    df.collect_events();

    // --------- dequeue and process events --------
    while (EventQueueCtr > 0)  {
        const ev = EventQueue[EventQueueOffCtr];
        EventQueueOffCtr += 1;
        if (EventQueueOffCtr == MAXMESSAGES)
            EventQueueOffCtr = 0;
        EventQueueCtr -= 1;

        // ------ get the window in which a
        //              keyboard event occurred ------
        var Kwnd = Window.inFocus;

        // ---- process keyboard captures -----
        if (CaptureKeyboard) |capture| {
            if (Kwnd == null or
                    NoChildCaptureKeyboard or
                    normal.isAncestor(Kwnd.?, capture) == false) {
                Kwnd = capture;
            }
        }

        // -------- send mouse and keyboard messages to the
        //    window that should get them -------- 
        switch (ev.event) {
            df.SHIFT_CHANGED,
            df.KEYBOARD => {
                if (!handshaking) {
                    if (Kwnd) |kw| {
                        _ = kw.sendMessage(ev.event, ev.mx, ev.my);
                    } else {
                        // could this happen ?
                        _ = SendMessage(null, ev.event, ev.mx, ev.my);
                    }
                }
            },
            df.LEFT_BUTTON => {
                if (!handshaking) {
                    // cannot be sure Mwnd is not null
                    const Mwnd = MouseWindow(ev.mx, ev.my);
                    if (CaptureMouse == null or
                                (NoChildCaptureMouse == false and
                                  normal.isAncestor(Mwnd.?, CaptureMouse.?) == true)) {
                        if (Mwnd != Window.inFocus) {
                            if (Mwnd) |mw| {
                                _ = mw.sendMessage(df.SETFOCUS, df.TRUE, 0);
                            } else {
                                // could this happen ?
                                _ = SendMessage(null, df.SETFOCUS, df.TRUE, 0);
                            }
                        }
                    }
                    if (Mwnd) |mw| {
                        _ = mw.sendMessage(df.LEFT_BUTTON, ev.mx, ev.my);
                    } else {
                        // could this happen ?
                        _ = SendMessage(null, df.LEFT_BUTTON, ev.mx, ev.my);
                    }
                }
            },
            df.BUTTON_RELEASED,
            df.DOUBLE_CLICK,
            df.RIGHT_BUTTON => {
                if (!handshaking) {
                    // Fall through
                    const Mwnd = MouseWindow(ev.mx, ev.my);
                    if (Mwnd) |mw| {
                        _ = mw.sendMessage(ev.event, ev.mx, ev.my);
                    } else {
                        // could this happen ?
                        _ = SendMessage(null, ev.event, ev.mx, ev.my);
                    }
                }
            },
            df.MOUSE_MOVED => {
                const Mwnd = MouseWindow(ev.mx, ev.my);
                if (Mwnd) |mw| {
                    _ = mw.sendMessage(ev.event, ev.mx, ev.my);
                } else {
                    // could this happen ?
                    _ = SendMessage(null, ev.event, ev.mx, ev.my);
                }
            },
//#if MSDOS       // FIXME add MK_FP
//            case CLOCKTICK:
//                SendMessage(Cwnd, ev_event,
//                    (PARAM) MK_FP(ev_mx, ev_my), 0);
//                                break;
//#endif
            else => {
            }
        }
    }

    // ------ dequeue and process messages -----
    while (MsgQueueCtr > 0) {
        const mq = MsgQueue[MsgQueueOffCtr];
        MsgQueueOffCtr += 1;
        if (MsgQueueOffCtr == MAXMESSAGES) {
            MsgQueueOffCtr = 0;
        }
        MsgQueueCtr -= 1;

        if (mq.win) |w| {
            _ = w.sendMessage(mq.msg, mq.p1, mq.p2);
        } else {
            _ = SendMessage(null, mq.msg, mq.p1, mq.p2);
        }

        if (mq.msg == df.ENDDIALOG) {
            return false;
        }
        if (mq.msg == df.STOP) {
            PostMessage(null, df.STOP, 0, 0);
            return false;
        }
    }

    // #define VIDEO_FB 1
    df.convert_screen_to_ansi();

    return true;
}
