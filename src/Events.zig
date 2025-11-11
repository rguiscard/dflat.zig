const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");

// ------ collect mouse, clock, and keyboard events -----
pub fn collect() void {
//    var stdin_buffer: [512]u8 = undefined;
//    var stdin_reader_wrapper = std.fs.File.stdin().reader(&stdin_buffer);
//    const reader: *std.Io.Reader = &stdin_reader_wrapper.interface;

    df.collect_events(); 

//    fd_set fdset;
//    struct timeval tv;
//    int e, n;
//    int mx, my, modkeys;
//    char buf[32];
//
//    FD_ZERO(&fdset);
//    FD_SET(0, &fdset);
//    tv.tv_sec = 0;
//    tv.tv_usec = 30000;
//    e = select(1, &fdset, NULL, NULL, &tv);
//    if (e < 0) return;
//    if (e == 0) return; //FIXME implement timeouts
//    if (FD_ISSET(0, &fdset)) {
//        if ((n = readansi(0, buf, sizeof(buf))) < 0)
//            return;
//        if ((e = ansi_to_unikey(buf, n)) != -1) {   // FIXME UTF-8 unicode != -1
//            PostEvent(KEYBOARD, e, 0);    // no sk
//            return;
//        }
//        if ((n = ansi_to_unimouse(buf, n, &mx, &my, &modkeys, &e)) != -1) {
//            if (mx >= SCREENWIDTH || my >= SCREENHEIGHT-1) return;
//            switch (n) {
//            case kMouseLeftDown:
//                PostEvent(LEFT_BUTTON, mx, my);
//                break;
//            case kMouseLeftDoubleClick:
//                PostEvent(DOUBLE_CLICK, mx, my);
//                break;
//            case kMouseRightDown:
//                PostEvent(RIGHT_BUTTON, mx, my);
//                break;
//            case kMouseLeftUp:
//            case kMouseRightUp:
//                PostEvent(BUTTON_RELEASED, mx, my);
//                break;
//            case kMouseMotion:          /* only returned on ANSI 1003 */
//                break;
//            case kMouseLeftDrag:
//            case kMouseRightDrag:
//                PostEvent(MOUSE_MOVED, mx, my);
//                break;
//            case kMouseWheelUp:
//                PostEvent(KEYBOARD, (modkeys & kCtrl)? PGUP: UP, 0);
//                break;
//            case kMouseWheelDown:
//                PostEvent(KEYBOARD, (modkeys & kCtrl)? PGDN: DN, 0);
//                break;
//            }
//            mouse_x = mx;
//            mouse_y = my;
//            mouse_button = n;
//            return;
//        }
//        printf("unknown ANSI key %s\r\n", unikeyname(n));
//    }
}
