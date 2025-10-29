const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

left:usize = 0,
top:usize = 0,
right:usize = 0,
bottom:usize = 0,

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();

pub fn c_Rect(self:TopLevelFields) df.RECT {
    return df.RECT{
        .lf = @intCast(self.left),
        .tp = @intCast(self.top),
        .rt = @intCast(self.right),
        .bt = @intCast(self.bottom),
    };
}

// ------- df.Rect related -------

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

// ------- return the client rectangle of a window ------
pub fn ClientRect(win:*Window) df.RECT {
    const rc:df.RECT = .{
        .lf = @intCast(win.GetClientLeft()),
        .tp = @intCast(win.GetClientTop()),
        .rt = @intCast(win.GetClientRight()),
        .bt = @intCast(win.GetClientBottom()),
    };
    return rc;
}
