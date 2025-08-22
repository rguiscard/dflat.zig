const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

const MAXMESSAGES = 100;

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
pub export fn PostMessage(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) void {
    var win:?*Window = null;
    if (Window.get_zin(wnd)) |w| {
        win = w;
    }
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
pub export fn SendMessage(wnd: df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) df.BOOL {
    const rtn:df.BOOL = df.TRUE;

    if (wnd != null) {
        if (Window.get_zin(wnd)) |zin| {
            return zin.sendMessage(msg, p1, p2);
        } else {
            // This shouldn't happen, except dummy window at normal.c for now.
            // Or we can create a Window instance for it here.
            if (root.global_allocator.create(Window)) |win| {
                win.* = Window.init(wnd, root.global_allocator);
                wnd.*.zin = @constCast(win);
                // Should call sendMessage() for it ?
            } else |_| {
                // error
            }

            // Should rtn be TRUE or FALSE or call sendMessage() ?
            if (wnd.*.Class != df.DUMMY) {
                // Try to catch any window which is not dummy nor created by Window.create()
                _ = df.printf("Not dummy !! \n");
                while(true) {}
            }
        }
    }

    // ----- window processor returned true or the message was sent
    //  to no window at all (NULL) -----
    return df.ProcessMessage(wnd, msg, p1, p2, rtn);
}

// ---- dispatch messages to the message proc function ----
pub export fn dispatch_message() callconv(.c) df.BOOL {
    // -------- collect mouse and keyboard events -------
    df.collect_events();

    // --------- dequeue and process events --------
    while (EventQueueCtr > 0)  {
        const ev = EventQueue[EventQueueOffCtr];
        EventQueueOffCtr += 1;
        if (EventQueueOffCtr == MAXMESSAGES)
            EventQueueOffCtr = 0;
        EventQueueCtr -= 1;

        df.c_dispatch_message(ev.event, ev.mx, ev.my);
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
            _ = df.SendMessage(null, mq.msg, mq.p1, mq.p2);
        }

        if (mq.msg == df.ENDDIALOG) {
            return df.FALSE;
        }
        if (mq.msg == df.STOP) {
            _ = df.PostMessage(null, df.STOP, 0, 0);
            return df.FALSE;
        }
    }

    // #define VIDEO_FB 1
    df.convert_screen_to_ansi();

    return df.TRUE;
}
