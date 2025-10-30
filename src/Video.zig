const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Rect = @import("Rect.zig");

const sTab:u16 = 0x0C + 0x80;

// assume video_address is 16 bites (2 bytes)
fn vad(x:usize, y:usize) usize {
    return y * @as(usize, @intCast(df.SCREENWIDTH)) + x;
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
    var vadr = vad(@intCast(rc.lf), @intCast(rc.tp));
    df.hide_mousecursor();
    for (0..ht) |idx| {
        movefromscreen(bf[bytes_row*idx..], vadr, bytes_row);
        vadr += @as(usize, @intCast(df.SCREENWIDTH));
    }
    df.show_mousecursor();
}

// -- write a rectangle of video memory from a save buffer --
pub fn storevideo(rc:df.RECT, bf:[]u16) void {
    const ht:usize = @intCast(rc.bt-rc.tp+1);
    const bytes_row:usize = @intCast(rc.rt-rc.lf+1);
    var vadr = vad(@intCast(rc.lf), @intCast(rc.tp));
    df.hide_mousecursor();
    for (0..ht) |idx| {
        movetoscreen(bf[bytes_row*idx..], vadr, bytes_row);
        vadr += @intCast(df.SCREENWIDTH);
    }
    df.show_mousecursor();
}

// -------- read a character of video memory -------
pub fn GetVideoChar(x:usize, y:usize) u16 {
    df.hide_mousecursor();
    // #define peek(a,o)       (*((unsigned short *)((char *)(a)+(o))))
    // const c = peek(video_address, vad(x,y));
    const va16_ptr:[*]u16 = @ptrCast(@alignCast(df.video_address));
    const c:[*]u16 = va16_ptr+vad(x,y);
    df.show_mousecursor();
    return c[0];
}

// -------- write a character of video memory -------
pub fn PutVideoChar(x:usize, y:usize, chr:u16) void {
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

pub fn CharInView(win:*Window, x:usize, y:usize) bool {
    const left:usize = win.GetLeft();
    const top:usize = win.GetTop();
    const x1:usize = left+x;
    const y1:usize = top+y;

    if (win.TestAttribute(df.VISIBLE) == false)
        return false;

    if (win.TestAttribute(df.NOCLIP) == false) {
        var ww = win.parent;
        while (ww) |win1| {
            // --- clip character to parent's borders --
            if (win1.TestAttribute(df.VISIBLE) == false)
                return false;
            if (Rect.InsideRect(x1, y1, win1.ClientRect()) == false)
                return false;
            ww = win1.parent;
        }
    }

    var nwin = win.nextWindow();
    while (nwin) |nw| {
        if (nw.isHidden() == false) { //  && !isAncestor(wnd, nwnd)
            var rc = nw.WindowRect();
            if (nw.TestAttribute(df.SHADOW)) {
                rc.bottom += 1;
                rc.right += 1;
            }
            if (nw.TestAttribute(df.NOCLIP) == false) {
                var pp = nw;
                while (pp.parent) |pwin| {
                    pp = pwin;
                    rc = Rect.subRectangle(rc, pwin.ClientRect());
                }
            }
            if (Rect.InsideRect(x1,y1,rc))
                return false;
        }
         nwin = nw.nextWindow();
    }
    return (x1 < df.SCREENWIDTH and y1 < df.SCREENHEIGHT);
}

// -------- write a character to a window -------
pub fn wputch(win:*Window, chr:u16, x:usize, y:usize) void {
    if (CharInView(win, x, y)) {
        // #define clr(fg,bg) ((fg)|((bg)<<4))
        const ch:u16 = @intCast((chr & 255) | ((df.foreground | (df.background << 4)) << 8));
        const xc:usize = win.GetLeft()+x;
        const yc:usize = win.GetTop()+y;
        df.hide_mousecursor();
        // #define poke(a,o,w)     (*((unsigned short *)((char *)(a)+(o))) = (w))
        // poke(video_address, vad(xc, yc), ch);
        const va16_ptr:[*]u16 = @ptrCast(@alignCast(df.video_address));
        const c:[*]u16 = va16_ptr+vad(xc,yc);
        c[0] = ch;
        df.show_mousecursor();
    }
}

// ------- write a string to a window ----------
pub fn wputs(win:*Window, s:[:0]const u8, x:usize, y:usize) void {
    const x1 = win.GetLeft()+x;
    const y1 = win.GetTop()+y;
    var xx = x;
    var x2 = x1;
    var idx:usize = 0;
    var ln = [_]u16{0}**df.MAXCOLS;
    var ldx:usize = 0;
    const fg = df.foreground;
    const bg = df.background;
    if (x1 < df.SCREENWIDTH and y1 < df.SCREENHEIGHT and win.isVisible()) {
        while ((idx < s.len) and (s[idx] != 0)){
            if (s[idx] == df.CHANGECOLOR) {
                df.foreground = s[idx+1] & 0x7f;
                df.background = s[idx+2] & 0x7f;
                idx += 3;
                continue;
            }
            if (s[idx] == df.RESETCOLOR) {
                df.foreground = fg & 0x7f;
                df.background = bg & 0x7f;
                idx += 1;
                continue;
            }
            if (s[idx] == ('\t' | 0x80) or s[idx] == (sTab | 0x80)) {
                ln[ldx] =  @intCast(' ' | ((df.foreground | (df.background << 4)) << 8));
            } else {
                ln[ldx] = @intCast((s[idx] & 255) | ((df.foreground | (df.background << 4)) << 8));
                if (df.ClipString>0) {
                    if (CharInView(win, xx, y)  == false) {
                        const va16_ptr:[*]u16 = @ptrCast(@alignCast(df.video_address));
                        const c:[*]u16 = va16_ptr+vad(x2,y1);
                        ln[ldx] = c[0];
                    }
                }
            }
            idx += 1;
            ldx += 1;
            xx += 1;
            x2 += 1;
        }
        df.foreground = fg;
        df.background = bg;
        var len = ldx;
        if (x1+len > df.SCREENWIDTH)
            len = @as(usize, @intCast(df.SCREENWIDTH))-x1;

        var off:usize = 0;
        if (df.ClipString == 0 and win.TestAttribute(df.NOCLIP) == false) {
            // -- clip the line to within ancestor windows --
            var rc = win.WindowRect();
            var nwnd = win.parent;
            while (len > 0 and nwnd != null) {
                const nwin = nwnd.?;
                if (nwin.isVisible() == false) {
                    len = 0;
                    break;
                }
                rc = Rect.subRectangle(rc, nwin.ClientRect());
                nwnd = nwin.parent;
            }
            while (len > 0 and Rect.InsideRect(x1+off,y1,rc) == false) {
                off += 1;
                len -|= 1;
            }
            if (len > 0) {
                x2 = x1+len-1;
                while (len>0 and Rect.InsideRect(x2,y1,rc) == false) {
                    x2 -|= 1;
                    len -|= 1;
                }
            }
        }
        if (len > 0) {
            df.hide_mousecursor();
            movetoscreen(ln[off..], vad(x1+off,y1), len);
            df.show_mousecursor();
        }

    }
}

// --------- get the current video mode --------
pub fn get_videomode() void {
    if (df.video_address == null)
        df.video_address = df.tty_allocate_screen(df.SCREENWIDTH, df.SCREENHEIGHT);
}
