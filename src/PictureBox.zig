const std = @import("std");
const df = @import("ImportC.zig").df;
const k = @import("Classes.zig").CLASS;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const video = @import("Video.zig");

// ---- types of vectors that can be in a picture box -------
pub const VectTypes = enum { VECTOR, SOLIDBAR, HEAVYBAR, CROSSBAR, LIGHTBAR };

pub const VECT = struct {
    vt: VectTypes,
    rc: df.RECT,
};

pub const CharInWnd = [_]u8{0xC4, 0xB3, 0xDA, 0xBF, 0xD9, 0xC0, 0xC5, 0xC3, 0xB4, 0xC1, 0xC2};

pub const VectCvt:[3][11][2][3]u8 = .{
    .{   // --- first character in collision vector ---
         // ( drawing 0xC4 ) ( drawing 0xB3 )
             .{.{0xC4, 0xC4, 0xC4}, .{0xDA, 0xC3, 0xC0}},
             .{.{0xDA, 0xC2, 0xBF}, .{0xB3, 0xB3, 0xB3}},
             .{.{0xDA, 0xC2, 0xC2}, .{0xDA, 0xC3, 0xC3}},
             .{.{0xBF, 0xBF, 0xBF}, .{0xBF, 0xBF, 0xBF}},
             .{.{0xD9, 0xD9, 0xD9}, .{0xD9, 0xD9, 0xD9}},
             .{.{0xC0, 0xC1, 0xC1}, .{0xC3, 0xC3, 0xC0}},
             .{.{0xC5, 0xC5, 0xC5}, .{0xC5, 0xC5, 0xC5}},
             .{.{0xC3, 0xC5, 0xC5}, .{0xC3, 0xC3, 0xC3}},
             .{.{0xB4, 0xB4, 0xB4}, .{0xB4, 0xB4, 0xB4}},
             .{.{0xC1, 0xC1, 0xC1}, .{0xC1, 0xC1, 0xC1}},
             .{.{0xC2, 0xC2, 0xC2}, .{0xC2, 0xC5, 0xC5}},    },
    .{   // --- middle character in collision vector ---
         // ( drawing 0xC4 ) ( drawing 0xB3 )
             .{.{0xC4, 0xC4, 0xC4}, .{0xC2, 0xC5, 0xC1}},
             .{.{0xC3, 0xC5, 0xB4}, .{0xB3, 0xB3, 0xB3}},
             .{.{0xDA, 0xDA, 0xDA}, .{0xDA, 0xDA, 0xDA}},
             .{.{0xBF, 0xBF, 0xBF}, .{0xBF, 0xBF, 0xBF}},
             .{.{0xD9, 0xD9, 0xD9}, .{0xD9, 0xD9, 0xD9}},
             .{.{0xC0, 0xC0, 0xC0}, .{0xC0, 0xC0, 0xC0}},
             .{.{0xC5, 0xC5, 0xC5}, .{0xC5, 0xC5, 0xC5}},
             .{.{0xC3, 0xC3, 0xC3}, .{0xC3, 0xC3, 0xC3}},
             .{.{0xC5, 0xC5, 0xB4}, .{0xB4, 0xB4, 0xB4}},
             .{.{0xC1, 0xC1, 0xC1}, .{0xC5, 0xC5, 0xC1}},
             .{.{0xC2, 0xC2, 0xC2}, .{0xC2, 0xC2, 0xC2}},    },
    .{   // --- last character in collision vector ---
         // ( drawing 0xC4 ) ( drawing 0xB3 )
             .{.{0xC4, 0xC4, 0xC4}, .{0xBF, 0xB4, 0xD9}},
             .{.{0xC0, 0xC1, 0xD9}, .{0xB3, 0xB3, 0xB3}},
             .{.{0xDA, 0xDA, 0xDA}, .{0xDA, 0xDA, 0xDA}},
             .{.{0xC2, 0xC2, 0xBF}, .{0xBF, 0xB4, 0xB4}},
             .{.{0xC1, 0xC1, 0xD9}, .{0xB4, 0xB4, 0xD9}},
             .{.{0xC0, 0xC0, 0xC0}, .{0xC0, 0xC0, 0xC0}},
             .{.{0xC5, 0xC5, 0xC5}, .{0xC5, 0xC5, 0xC5}},
             .{.{0xC3, 0xC3, 0xC3}, .{0xC3, 0xC3, 0xC3}},
             .{.{0xC5, 0xC5, 0xB4}, .{0xB4, 0xB4, 0xB4}},
             .{.{0xC1, 0xC1, 0xC1}, .{0xC5, 0xC5, 0xC1}},
             .{.{0xC2, 0xC2, 0xC2}, .{0xC2, 0xC2, 0xC2}},    },
};

// -- compute whether character is first, middle, or last --
fn FindVector(win:*Window, rc:df.RECT, x:c_int, y:c_int) ?usize {
    var coll:?usize = null;

    if (win.VectorList) |vectors| {
        for(vectors) |v| {
            const rcc:df.RECT = v.rc;
            // --- skip the colliding vector ---
            if ((rcc.lf == rc.lf) and (rcc.rt == rc.rt) and
                    (rcc.tp == rc.tp) and (rc.bt == rcc.bt)) {
                continue;
            }
            if (rcc.tp == rcc.bt) {
                // ---- horizontal vector,
                //    see if character is in it ---
                if (((rc.lf+x) >= rcc.lf) and ((rc.lf+x) <= rcc.rt) and
                        ((rc.tp+y) == rcc.tp)) {
                    // --- it is ---
                    if (rc.lf+x == rcc.lf) {
                        coll = 0;
                    } else if (rc.lf+x == rcc.rt) {
                        coll = 2;
                    } else {
                        coll = 1;
                    }
                }
            } else {
                // ---- vertical vector,
                //    see if character is in it ---
                if (((rc.tp+y) >= rcc.tp) and ((rc.tp+y) <= rcc.bt) and
                        ((rc.lf+x) == rcc.lf)) {
                    // --- it is ---
                    if (rc.tp+y == rcc.tp) {
                        coll = 0;
                    } else if (rc.tp+y == rcc.bt) {
                        coll = 2;
                    } else {
                        coll = 1;
                    }
                }
            }
        }
    }
    return coll;
}

fn PaintVector(win:*Window, rc:df.RECT) void {
    var len: usize = 0;
    var nc: u16 = 0;
    var vertvect: usize = 0;
    var fml: usize = 0;

    if (rc.rt == rc.lf)    {
        // ------ vertical vector -------
        nc = 0xB3;
        vertvect = 1;
        len = @intCast(rc.bt-rc.tp+1);
    } else {
        // ------ horizontal vector -------
        nc = 0xC4;
        vertvect = 0;
        len = @intCast(rc.rt-rc.lf+1);
    }

    for (0..len) |i| {
        var newch: u16 = nc;
        var xi: usize = 0;
        var yi: usize = 0;

        if (vertvect > 0) {
            yi = i;
        } else {
            xi = i;
        }

        const left:usize = win.GetClientLeft();
        const top:usize = win.GetClientTop();
        const ch_x:usize = left+xi+@as(usize, @intCast(rc.lf));
        const ch_y:usize = top+yi+@as(usize, @intCast(rc.tp));
        const ch:u16 = video.GetVideoChar(ch_x, ch_y) & 255;
    
        for (0..CharInWnd.len) |cw| {
            if (ch == CharInWnd[cw]) {
                // ---- hit another vector character ----
                if (FindVector(win, rc, @intCast(xi), @intCast(yi))) |coll| {
                    // compute first/middle/last subscript
                    if (i == len-1) {
                        fml = 2;
                    } else if (i == 0) {
                        fml = 0;
                    } else {
                        fml = 1;
                    }
                    newch = VectCvt[coll][cw][vertvect][fml];
                }
            }
        }
        win.PutWindowChar(newch, @as(usize, @intCast(rc.lf))+xi, @as(usize, @intCast(rc.tp))+yi);
    }
}

fn PaintBar(win:*Window, rc:df.RECT, vt:VectTypes) void {
    var len:usize = 0;
    var vertbar:usize = 0;
    const tys = [_]u16{219, 178, 177, 176};
    const nc:u16 = tys[@intFromEnum(vt)-1];

    if (rc.rt == rc.lf) {
        // ------ vertical bar -------
        vertbar = 1;
        len = @intCast(rc.bt-rc.tp+1);
    } else {
        // ------ horizontal bar -------
        vertbar = 0;
        len = @intCast(rc.rt-rc.lf+1);
    }

    for(0..len) |i| {
        var xi:usize = 0;
        var yi:usize = 0;
        if (vertbar != 0) {
            yi = i;
        } else {
            xi = i;
        }
        win.PutWindowChar(nc, @as(usize, @intCast(rc.lf))+xi, @as(usize, @intCast(rc.tp))+yi);
    }
}

fn PaintMsg(win:*Window) void {
    if (win.VectorList) |vectors| {
        for(vectors) |v| {
            if (v.vt == VectTypes.VECTOR) {
                PaintVector(win, v.rc);
            } else {
                PaintBar(win, v.rc, v.vt);
            }
        }
    }
}

fn DrawVectorMsg(win:*Window, p1:?df.RECT, vt:VectTypes) void {
    if (p1) |area| {
        var vectors:std.ArrayList(VECT) = undefined;
        if (win.VectorList) |list| {
            vectors = std.ArrayList(VECT).fromOwnedSlice(list);
        } else {
            if (std.ArrayList(VECT).initCapacity(root.global_allocator, 0)) |list| {
                vectors = list;
            } else |_| {
                // error
            }
       
        }
        if (vectors.addOne(root.global_allocator)) |vc| {
            vc.*.vt = vt;
            vc.*.rc = area;
        } else |_| {
            // error
        }

        if (vectors.toOwnedSlice(root.global_allocator)) |list| {
            win.VectorList = list;
            vectors.deinit(root.global_allocator);
        } else |_| {
            // error
        }
    }
}

fn DrawBoxMsg(win:*Window, p1:?df.RECT) void {
    if (p1) |area| {
        var rc:df.RECT = area;
        rc.bt = rc.tp;
        _ = win.sendMessage(df.DRAWVECTOR, .{.draw = .{rc, .VECTOR}});
        rc = area;
        rc.lf = rc.rt;
        _ = win.sendMessage(df.DRAWVECTOR, .{.draw = .{rc, .VECTOR}});
        rc = area;
        rc.tp = rc.bt;
        _ = win.sendMessage(df.DRAWVECTOR, .{.draw = .{rc, .VECTOR}});
        rc = area;
        rc.rt = rc.lf;
        _ = win.sendMessage(df.DRAWVECTOR, .{.draw = .{rc, .VECTOR}});
    }
}

pub fn PictureProc(win:*Window, message: df.MESSAGE, params:q.Params) bool {
    switch (message) {
        df.PAINT => {
            _ = root.BaseWndProc(k.PICTUREBOX, win, message, params);
            PaintMsg(win);
            return true;
        },
        df.DRAWVECTOR => {
            DrawVectorMsg(win, params.draw[0], VectTypes.VECTOR);
            return true;
        },
        df.DRAWBOX => {
            DrawBoxMsg(win, params.draw[0]);
            return true;
        },
        df.DRAWBAR => {
            DrawVectorMsg(win, params.draw[0], params.draw[1]);
            return true;
        },
        df.CLOSE_WINDOW => {
            if (win.VectorList) |list| {
                root.global_allocator.free(list);
            }
        },
        else => {
        }
    }
    return root.BaseWndProc(k.PICTUREBOX, win, message, params);
}

fn PictureRect(x:c_int, y:c_int, len:c_int, hv:c_int) df.RECT {
    var rc:df.RECT = .{
        .lf = x,
        .rt = x,
        .tp = y,
        .bt = y,
    };
    if (hv != 0) {
        // ---- horizontal vector ---- 
        rc.rt += len-1;
    } else {
        // ---- vertical vector ----
        rc.bt += len-1;
    }
    return rc;
}

pub fn DrawVector(win:*Window, x:c_int, y:c_int, len:c_int, hv:c_int) void {
    const rc:df.RECT = PictureRect(x,y,len,hv);
    _ = win.sendMessage(df.DRAWVECTOR, .{.draw = .{rc, .VECTOR}});
}

pub fn DrawBox(win:*Window, x:c_int, y:c_int, ht:c_int, wd:c_int) void {
    const rc:df.RECT = .{
        .lf = x,
        .tp = y,
        .rt = x+wd-1,
        .bt = y+ht-1
    };
    _ = win.sendMessage(df.DRAWBOX, .{.draw = .{rc, .VECTOR}});
}

pub fn DrawBar(win:*Window, vt:VectTypes, x:c_int, y:c_int, len:c_int, hv:c_int) void {
    const rc:df.RECT = PictureRect(x,y,len,hv);
    _ = win.sendMessage(df.DRAWBAR,  .{.draw = .{rc, vt}});
}
