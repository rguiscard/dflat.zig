const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const video = @import("Video.zig");

left:usize = 0,
top:usize = 0,
right:usize = 0,
bottom:usize = 0,

// Width need +1
//#define RectWidth(r)      (RectRight(r)-RectLeft(r)+1)

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();

//pub fn c_Rect(self:TopLevelFields) df.RECT {
//    return df.RECT{
//        .lf = @intCast(self.left),
//        .tp = @intCast(self.top),
//        .rt = @intCast(self.right),
//        .bt = @intCast(self.bottom),
//    };
//}

fn withIn(p:usize, v1:usize, v2:usize) bool {
    return ((p >= v1) and (p <= v2));
}

// --- Produce the vector end points produced by the overlap
//        of two other vectors --- 
fn subVector(v1:*usize, v2:*usize, t1:usize, t2:usize, o1:usize, o2:usize) bool {
    var x1:?usize = null;
    var x2:?usize = null;

    if (withIn(o1, t1, t2)) {
        x1 = o1;
        x2 = if (withIn(o2, t1, t2)) o2 else t2;
    } else if (withIn(o2, t1, t2)) {
        x2 = o2;
        x1 = if (withIn(o1, t1, t2)) o1 else t1;
    } else if (withIn(t1, o1, o2)) {
        x1 = t1;
        x2 = if (withIn(t2, o1, o2)) t2 else o2;
    } else if (withIn(t2, o1, o2)) {
        x2 = t2;
        x1 = if (withIn(t1, o1, o2)) t1 else o1;
    }
    v1.* = x1 orelse 0;
    v2.* = x2 orelse 0;
    return (x1 != null and x2 != null);
}

// --- Return the rectangle produced by the overlap
//      of two other rectangles ----
pub fn subRectangle(r1:TopLevelFields, r2:TopLevelFields) TopLevelFields {
    var r:TopLevelFields = .{.left = 0, .top = 0, .right = 0, .bottom = 0};
    const b1 = subVector(&r.left, &r.right,
                         r1.left, r1.right,
                         r2.left, r2.right);
    const b2 = subVector(&r.top, &r.bottom,
                         r1.top, r1.bottom,
                         r2.top, r2.bottom);
    if (b1 == false or b2 == false) {
        r = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
    }
    return r;
}

pub fn ValidRect(r:TopLevelFields) bool {
    return (r.right > 0) or (r.left > 0) or (r.top > 0) or (r.bottom > 0);
}

pub fn InsideRect(x:usize, y:usize, r:TopLevelFields) bool {
    return withIn(x, r.left, r.right) and withIn(y, r.top, r.bottom);
}

// ----- clip a rectangle to the parents of the window ----- 
pub fn ClipRectangle(win:*Window, rc:TopLevelFields) TopLevelFields {
    const sr:TopLevelFields = .{ .left = 0, .top = 0, .right = video.SCREENWIDTH-1,
                                                      .bottom = video.SCREENHEIGHT-1};
    var rcc = rc;
    if (win.TestAttribute(df.NOCLIP) == false) {
        var pw = win.parent;
        while (pw) |pwin| {
            rcc = subRectangle(rcc, pwin.ClientRect());
            pw = pwin.parent;
        }
    }
    return subRectangle(rcc, sr);
}

// ----- return the rectangle relative to
//            its window's screen position --------
pub fn RelativeWindowRect(win:*Window, rc:TopLevelFields) TopLevelFields {
    var rcc = rc;
    rcc.left -|= win.GetLeft();
    rcc.right -|= win.GetLeft();
    rcc.top -|= win.GetTop();
    rcc.bottom -|= win.GetTop();
    return rcc;
}
