const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

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
fn FindVector(wnd:df.WINDOW, rc:df.RECT, x:c_int, y:c_int) c_int {
    var coll:c_int = -1;

    const vc:[*c]df.VECT = @alignCast(@ptrCast(wnd.*.VectorList));
    if (vc) |vectors| {
        const vcs:[]df.VECT = vectors[0..@intCast(wnd.*.VectorCount)];
        for(vcs) |v| {
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

fn PaintVector(wnd:df.WINDOW, rc:df.RECT) void {
    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));

    var len: c_int = 0;
    var nc: c_uint = 0;
    var vertvect: c_int = 0;
    var fml: c_int = 0;

    if (rc.rt == rc.lf)    {
        // ------ vertical vector -------
        nc = 0xB3;
        vertvect = 1;
        len = rc.bt-rc.tp+1;
    } else {
        // ------ horizontal vector -------
        nc = 0xC4;
        vertvect = 0;
        len = rc.rt-rc.lf+1;
    }

    for (0..@intCast(len)) |i| {
        var newch:c_uint = nc;
        var xi: c_int = 0;
        var yi: c_int = 0;
        var coll: c_int = 0;

        if (vertvect > 0) {
            yi = @intCast(i);
        } else {
            xi = @intCast(i);
        }

        const ch_x:c_int = @intCast(win.GetClientLeft()+rc.lf+xi);
        const ch_y:c_int = @intCast(win.GetClientTop()+rc.tp+yi);
        const ch:c_uint = df.videochar(ch_x, ch_y);
    
        for (0..CharInWnd.len) |cw| {
            if (ch == CharInWnd[cw]) {
                // ---- hit another vector character ----
                coll = FindVector(wnd, rc, xi, yi);
                if (coll != -1) {
                    // compute first/middle/last subscript
                    if (i == len-1) {
                        fml = 2;
                    } else if (i == 0) {
                        fml = 0;
                    } else {
                        fml = 1;
                    }
                    newch = VectCvt[@intCast(coll)][cw][@intCast(vertvect)][@intCast(fml)];
                }
            }
        }
        df.PutWindowChar(wnd, @intCast(newch), rc.lf+xi, rc.tp+yi);
    }
}

fn PaintBar(wnd:df.WINDOW, rc:df.RECT, vt:df.VectTypes) void {
    var len:c_int = 0;
    var vertbar:c_int = 0;
    const tys = [_]c_int{219, 178, 177, 176};
    const nc:c_int = tys[vt-1];

    if (rc.rt == rc.lf) {
        // ------ vertical bar -------
        vertbar = 1;
        len = @intCast(rc.bt-rc.tp+1);
    } else {
        // ------ horizontal bar -------
        vertbar = 0;
        len = @intCast(rc.rt-rc.lf+1);
    }

    for(0..@intCast(len)) |i| {
        var xi:c_int = 0;
        var yi:c_int = 0;
        if (vertbar != 0) {
            yi = @intCast(i);
        } else {
            xi = @intCast(i);
        }
        df.PutWindowChar(wnd, nc, rc.lf+xi, rc.tp+yi);
    }
}

fn PaintMsg(wnd:df.WINDOW) void {
    const vc:[*c]df.VECT = @alignCast(@ptrCast(wnd.*.VectorList));
    if (vc) |vectors| {
        const vcs:[]df.VECT = vectors[0..@intCast(wnd.*.VectorCount)];
        for(vcs) |v| {
            if (v.vt == df.VECTOR) {
                PaintVector(wnd, v.rc);
            } else {
                PaintBar(wnd, v.rc, v.vt);
            }
        }
    }
}

fn DrawVectorMsg(wnd:df.WINDOW, p1:df.PARAM, vt:df.VectTypes) void {
    // This is essentially append the vt into wnd.*.VectorList
    // Probably can be rewritten better
    if (p1 != 0) {
        var vc:df.VECT = undefined;
        const size:usize = @intCast(@sizeOf(df.VECT) * (wnd.*.VectorCount + 1));
        wnd.*.VectorList = df.DFrealloc(wnd.*.VectorList, size);
        vc.vt = vt;
        const p1_addr:usize = @intCast(p1);
        const p1_ptr:*df.RECT = @ptrFromInt(p1_addr);
        vc.rc = p1_ptr.*;
        
        const vlist:[*c]df.VECT = @alignCast(@ptrCast(wnd.*.VectorList));
        if (vlist) |vectors| {
            const addr:usize = @intCast(wnd.*.VectorCount);
            const v = vectors+addr;
            v.* = vc;
        }
        wnd.*.VectorCount += 1;
    }
}

fn DrawBoxMsg(wnd:df.WINDOW, p1:df.PARAM) void {
    if (p1 != 0)    {
        const p1_addr:usize = @intCast(p1);
        const p1_ptr:*df.RECT = @ptrFromInt(p1_addr); 
        var rc:df.RECT = p1_ptr.*;
        rc.bt = rc.tp;
        _ = df.SendMessage(wnd, df.DRAWVECTOR, @intCast(@intFromPtr(&rc)), df.TRUE);
        rc = p1_ptr.*;
        rc.lf = rc.rt;
        _ = df.SendMessage(wnd, df.DRAWVECTOR, @intCast(@intFromPtr(&rc)), df.FALSE);
        rc = p1_ptr.*;
        rc.tp = rc.bt;
        _ = df.SendMessage(wnd, df.DRAWVECTOR, @intCast(@intFromPtr(&rc)), df.TRUE);
        rc = p1_ptr.*;
        rc.rt = rc.lf;
        _ = df.SendMessage(wnd, df.DRAWVECTOR, @intCast(@intFromPtr(&rc)), df.FALSE);
    }
}

pub export fn PictureProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message) {
        df.PAINT => {
            _ = df.BaseWndProc(df.PICTUREBOX, wnd, message, p1, p2);
            PaintMsg(wnd);
            return df.TRUE;
        },
        df.DRAWVECTOR => {
            DrawVectorMsg(wnd, p1, df.VECTOR);
            return df.TRUE;
        },
        df.DRAWBOX => {
            DrawBoxMsg(wnd, p1);
            return df.TRUE;
        },
        df.DRAWBAR => {
            DrawVectorMsg(wnd, p1, @intCast(p2));
            return df.TRUE;
        },
        df.CLOSE_WINDOW => {
            if (wnd.*.VectorList) |list| {
                df.free(list);
            }
        },
        else => {
        }
    }
    return df.BaseWndProc(df.PICTUREBOX, wnd, message, p1, p2);
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

pub export fn DrawVector(wnd:df.WINDOW, x:c_int, y:c_int, len:c_int, hv:c_int) void {
    const rc:df.RECT = PictureRect(x,y,len,hv);
    _ = df.SendMessage(wnd, df.DRAWVECTOR, @intCast(@intFromPtr(&rc)), 0);
}

pub export fn DrawBox(wnd:df.WINDOW, x:c_int, y:c_int, ht:c_int, wd:c_int) void {
    const rc:df.RECT = .{
        .lf = x,
        .tp = y,
        .rt = x+wd-1,
        .bt = y+ht-1
    };
    _ = df.SendMessage(wnd, df.DRAWBOX, @intCast(@intFromPtr(&rc)), 0);
}

pub export fn DrawBar(wnd:df.WINDOW, vt:df.VectTypes, x:c_int, y:c_int, len:c_int, hv:c_int) void {
    const rc:df.RECT = PictureRect(x,y,len,hv);
    _ = df.SendMessage(wnd, df.DRAWBAR, @intCast(@intFromPtr(&rc)), @intCast(vt));
}
