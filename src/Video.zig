const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const rect = @import("Rect.zig");

// #define vad(x,y) ((y)*(SCREENWIDTH*2)+(x)*2)
// video_address is 8 bits (1 bytes, char*)
fn vad8(x:c_int, y:c_int) usize {
    return @intCast(y * df.SCREENWIDTH * 2 + x * 2);
}

// assume video_address is 16 bites (2 bytes)
fn vad(x:c_int, y:c_int) usize {
    return @intCast(y * df.SCREENWIDTH + x);
}

fn movetoscreen(bf:[]u16, offset:usize, len:usize) void {
    // video_address is u8
    const bf8:[]u8 = @ptrCast(bf);
    @memcpy(df.video_address[offset*2..(offset+len)*2], bf8[0..len*2]);
}

fn movefromscreen(bf:[]u16, offset:usize, len:usize) void {
    // video_address is u8
    const bf8:[]u8 = @ptrCast(bf);
    @memcpy(bf8[0..len*2], df.video_address[offset*2..(offset+len)*2]);
}

// -- read a rectangle of video memory into a save buffer --
pub fn getvideo(rc:df.RECT, bf:[]u16) void {
    const ht:usize = @intCast(rc.bt-rc.tp+1);
    const bytes_row:usize = @intCast(rc.rt-rc.lf+1);
    var vadr = vad(rc.lf, rc.tp);
    df.hide_mousecursor();
    for (0..ht) |idx| {
        movefromscreen(bf[bytes_row*idx..], vadr, bytes_row);
        vadr += @as(usize, @intCast(df.SCREENWIDTH));
//        bf = bf + bytes_row*idx;
    }
    df.show_mousecursor();
}

// -- write a rectangle of video memory from a save buffer --
pub fn storevideo(rc:df.RECT, bf:[]u16) void {
    const ht:usize = @intCast(rc.bt-rc.tp+1);
    const bytes_row:usize = @intCast(rc.rt-rc.lf+1);
    var vadr = vad(rc.lf, rc.tp);
    df.hide_mousecursor();
    for (0..ht) |idx| {
        movetoscreen(bf[bytes_row*idx..], vadr, bytes_row);
        vadr += @intCast(df.SCREENWIDTH);
//        bf = bf + bytes_row*idx;
    }
    df.show_mousecursor();
}

// -------- read a character of video memory -------
pub fn GetVideoChar(x:c_int, y:c_int) u16 {
    df.hide_mousecursor();
    // #define peek(a,o)       (*((unsigned short *)((char *)(a)+(o))))
    // const c = peek(video_address, vad(x,y));
    const va16_ptr:[*]u16 = @ptrCast(@alignCast(df.video_address));
    const c:[*]u16 = va16_ptr+vad(x,y);
    df.show_mousecursor();
    return c[0];
}

// -------- write a character of video memory -------
pub fn PutVideoChar(x:c_int, y:c_int, chr:u16) void {
    if (x < df.SCREENWIDTH and y < df.SCREENHEIGHT) {
        df.hide_mousecursor();
        // #define poke(a,o,w)     (*((unsigned short *)((char *)(a)+(o))) = (w))
        // poke(video_address, vad(x,y), chr);
        const va16_ptr:[*]u16 = @ptrCast(@alignCast(df.video_address));
        const c:[*]u16 = va16_ptr+vad(x,y);
        c[0] = chr;
        df.show_mousecursor();
    }
}

pub export fn CharInView(wnd:df.WINDOW, x:c_int, y:c_int) callconv(.c) df.BOOL {
    if (Window.get_zin(wnd)) |win| {
        const left:c_int = @intCast(win.GetLeft());
        const top:c_int = @intCast(win.GetTop());
        const x1:c_int = left+x;
        const y1:c_int = top+y;

        if (win.TestAttribute(df.VISIBLE) == false)
            return df.FALSE;

        if (win.TestAttribute(df.NOCLIP) == false) {
            var ww = win.parent;
            while (ww) |win1| {
                // --- clip character to parent's borders --
                if (win1.TestAttribute(df.VISIBLE) == false)
                    return df.FALSE;
                if (rect.InsideRect(x1, y1, rect.ClientRect(win1)) == false)
                    return df.FALSE;
                ww = win1.parent;
            }
        }

        var nwin = win.nextWindow();
        while (nwin) |nw| {
            if (nw.isHidden() == false) { //  && !isAncestor(wnd, nwnd)
                var rc = nw.WindowRect();
                if (nw.TestAttribute(df.SHADOW)) {
                    rc.bt += 1;
                    rc.rt += 1;
                }
                if (nw.TestAttribute(df.NOCLIP) == false) {
                    var pp = nw;
                    while (pp.parent) |pwin| {
                        pp = pwin;
                        rc = df.subRectangle(rc, rect.ClientRect(pwin));
                    }
                }
                if (rect.InsideRect(x1,y1,rc))
                    return df.FALSE;
            }
             nwin = nw.nextWindow();
        }
        return if ((x1 < df.SCREENWIDTH and y1 < df.SCREENHEIGHT)) df.TRUE else df.FALSE;
    }
    return df.FALSE;
}
