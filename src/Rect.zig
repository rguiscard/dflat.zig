const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

//#define ValidRect(r)      (RectRight(r) || RectLeft(r) || \
//                           RectTop(r) || RectBottom(r))
//#define RectWidth(r)      (RectRight(r)-RectLeft(r)+1)
//#define RectHeight(r)     (RectBottom(r)-RectTop(r)+1)
//RECT subRectangle(RECT, RECT);
//RECT ClientRect(void *);
//RECT RelativeWindowRect(void *, RECT);
//RECT ClipRectangle(void *, RECT);

pub export fn within(p:c_int, v1:c_int, v2:c_int) callconv(.c) bool {
    return ((p >= v1) and (p <= v2));
}

pub fn RectTop(r:df.RECT) callconv(.c) c_int {
    return r.tp;
}

pub fn RectBottom(r:df.RECT) callconv(.c) c_int {
    return r.bt;
}

pub fn RectLeft(r:df.RECT) callconv(.c) c_int {
    return r.lf;
}

pub fn RectRight(r:df.RECT) callconv(.c) c_int {
    return r.rt;
}

pub export fn InsideRect(x:c_int, y:c_int, r:df.RECT) callconv(.c) bool {
    return within((x), RectLeft(r), RectRight(r)) and
           within((y), RectTop(r), RectBottom(r));
}
