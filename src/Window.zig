const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Klass = @import("Classes.zig");

wndproc: ?*const fn (wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int,
modal: bool, // True if a modeless dialog box
allocator: std.mem.Allocator,
win: df.WINDOW,

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();

// --------- create a window ------------
pub export fn CreateWindow(
    klass:df.CLASS,              // class of this window
    ttl:[*c]u8,                  // title or NULL
    left:c_int, top:c_int,       // upper left coordinates
    height:c_int, width:c_int,   // dimensions
    extension:?*anyopaque,       // pointer to additional data
    parent:df.WINDOW,            // parent of this window
    wndproc:?*const fn (wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int,
    attrib:c_int)                // window attribute
    callconv(.c) df.WINDOW
{
    const self = TopLevelFields;
    var title:?[]const u8 = null;
    if (ttl) |t| {
        title = std.mem.span(t);
    }
    const win = self.create(klass, title, left, top, height, width, extension, parent, wndproc, attrib);
    return win.*.win;
}

pub fn init(wnd: df.WINDOW, allocator: std.mem.Allocator) TopLevelFields {
    return .{
        .win = wnd,
        .wndproc = null,
        .modal = false,
        .allocator = allocator,
    };
}

pub fn create(
    klass: df.CLASS,            // class of this window
    ttl: ?[]const u8,           // title or NULL
    left:c_int, top:c_int,      // upper left coordinates
    height:c_int, width:c_int,  // dimensions
    extension:?*anyopaque,      // pointer to additional data
    parent: df.WINDOW,          // parent of this window
    wndproc: ?*const fn (wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int,
    attrib: c_int) *TopLevelFields {

    const title = if (ttl) |t| t.ptr else null;
    const wnd:df.WINDOW = @ptrCast(@alignCast(df.DFcalloc(1, @sizeOf(df.window))));

    var self:*TopLevelFields = undefined;
    if (root.global_allocator.create(TopLevelFields)) |s| {
       self = s;
    } else |_| {
        // error
    }
    self.* = init(wnd, root.global_allocator);

    df.get_videomode();

    if (wnd != null) {
        // ----- height, width = -1: fill the screen -------
        var ht = height;
        if (ht == -1)
            ht = df.SCREENHEIGHT;
        var wt = width;
        if (wt == -1)
            wt = df.SCREENWIDTH;
        // ----- coordinates -1, -1 = center the window ----
        if (left == -1) {
            wnd.*.rc.lf = @divFloor(df.SCREENWIDTH-wt, 2);
        } else {
            wnd.*.rc.lf = left;
        }
        if (top == -1) {
            wnd.*.rc.tp = @divFloor(df.SCREENHEIGHT-ht, 2);
        } else {
            wnd.*.rc.tp = top;
        }
        wnd.*.attrib = attrib;
        if (ttl) |tt| {
            if (tt.len > 0) {
                // df.AddAttribute(wnd, df.HASTITLEBAR);
                 wnd.*.attrib = wnd.*.attrib | df.HASTITLEBAR;
            }
        }
        if (wndproc == null) {
            wnd.*.wndproc = Klass.classdefs[@intCast(klass)][2]; // wndproc
            self.wndproc = Klass.classdefs[@intCast(klass)][2]; // wndproc
        } else {
            wnd.*.wndproc = wndproc;
            self.wndproc = wndproc;
        }

        // ---- derive attributes of base classes ----
        var base = klass;
        while (base != -1) {
            const cls = Klass.classdefs[@intCast(base)];
            const attr:c_int = @intCast(cls[3]); // attributes
            // df.AddAttribute(wnd, attr);
            wnd.*.attrib = wnd.*.attrib | attr;
            base = @intFromEnum(cls[1]); // base
        }
        var pt = parent;
        if (parent != null) {
            if (df.TestAttribute(wnd, df.NOCLIP) == 0) {
                const pwin:*TopLevelFields = @constCast(@fieldParentPtr("win", &parent));
                // -- keep upper left within borders of parent -
                wnd.*.rc.lf = @intCast(@max(wnd.*.rc.lf, pwin.GetClientLeft()));
                wnd.*.rc.tp = @intCast(@max(wnd.*.rc.tp, pwin.GetClientTop()));
            }
        } else {
            pt = df.ApplicationWindow;
        }
        wnd.*.Class = klass;
        wnd.*.extension = extension;
        wnd.*.rc.rt = df.GetLeft(wnd)+wt-1;
        wnd.*.rc.bt = df.GetTop(wnd)+ht-1;
        wnd.*.ht = ht;
        wnd.*.wd = wt;
        if (ttl != null) {
            df.InsertTitle(wnd, title);
        }
        wnd.*.parent = pt;
        wnd.*.oldcondition = df.ISRESTORED;
        wnd.*.condition = df.ISRESTORED;
        wnd.*.RestoredRC = wnd.*.rc;
        df.InitWindowColors(wnd);
        _ = df.SendMessage(wnd, df.CREATE_WINDOW, 0, 0);
        if (df.isVisible(wnd)>0) {
            _ = df.SendMessage(wnd, df.SHOW_WINDOW, 0, 0);
        }

        wnd.*.zin = @ptrCast(@alignCast(self));
    }

    return self;
}

// ------- window methods -----------
pub fn WindowHeight(self: *TopLevelFields) isize {
    const wnd = self.win;
    return wnd.*.ht;
}

pub fn SetWindowHeight(self: *TopLevelFields, height: isize) void {
    const wnd = self.win;
    wnd.*.ht = @intCast(height);
}

pub fn WindowWidth(self: *TopLevelFields) isize {
    const wnd = self.win;
    return wnd.*.wd;
}

pub fn BorderAdj(self: *TopLevelFields) isize {
    var border:isize = 0;
    if (df.TestAttribute(self.win, df.HASBORDER) > 0) {
        border = 1;
    }
    return border;
}

pub fn BottomBorderAdj(self: *TopLevelFields) isize {
    var border = BorderAdj(self);
    if (df.TestAttribute(self.win, df.HASSTATUSBAR) > 0) {
        border = 1;
    }
    return border;
}

pub fn TopBorderAdj(self: *TopLevelFields) isize {
    var border:isize = 0;
    if ((df.TestAttribute(self.win, df.HASTITLEBAR) > 0) and (df.TestAttribute(self.win, df.HASMENUBAR) > 0)) {
        border = 2;
    } else {
        if (df.TestAttribute(self.win, df.HASTITLEBAR | df.HASMENUBAR | df.HASBORDER) > 0) {
            border = 1;
        }
    }
    return border;
}

pub fn ClientWidth(self: *TopLevelFields) isize {
    return (self.WindowWidth()-BorderAdj(self)*2);
}

pub fn ClientHeight(self: *TopLevelFields) isize {
    return (self.WindowHeight()-TopBorderAdj(self)-BottomBorderAdj(self));
}

pub fn WindowRect(self: *TopLevelFields) df.RECT {
    const wnd = self.win;
    return wnd.*.rc;
}

pub fn GetTop(self: *TopLevelFields) isize {
    const rect = self.WindowRect();
    return rect.tp;
}

pub fn GetBottom(self: *TopLevelFields) isize {
    const rect = self.WindowRect();
    return rect.bt;
}

pub fn SetBottom(self: *TopLevelFields, bottom: isize) void {
    self.win.*.rc.bt = @intCast(bottom);
}

pub fn GetLeft(self: *TopLevelFields) isize {
    const rect = self.WindowRect();
    return rect.lf;
}

pub fn GetRight(self: *TopLevelFields) isize {
    const rect = self.WindowRect();
    return rect.rt;
}

pub fn GetClientTop(self: *TopLevelFields) isize {
    return self.GetTop() + self.TopBorderAdj();
}

pub fn GetClientBottom(self: *TopLevelFields) isize {
    return self.GetBottom() - self.BottomBorderAdj();
}

pub fn GetClientLeft(self: *TopLevelFields) isize {
    return self.GetLeft() + self.BorderAdj();
}

pub fn GetClientRight(self: *TopLevelFields) isize {
    return self.GetRight() - self.TopBorderAdj();
}

pub fn GetClass(self: *TopLevelFields) df.CLASS {
    const wnd = self.win;
    return wnd.*.Class;
}

pub fn GetAttribute(self: *TopLevelFields) c_int {
    const wnd = self.win;
    return wnd.*.attrib;
}

pub fn AddAttribute(self: *TopLevelFields, attr: c_int) void {
    const wnd = self.win;
    wnd.*.attrib = wnd.*.attrib | attr;
}

pub fn ClearAttribute(self: *TopLevelFields, attr: c_int) void {
    const wnd = self.win;
    wnd.*.attrib = wnd.*.attrib & (~attr);
}

pub fn TestAttribute(self: *TopLevelFields, attr: c_int) bool {
    const wnd = self.win;
    return (wnd.*.attrib & attr) > 0;
}

pub fn isHidden(self: *TopLevelFields) bool {
    const wnd = self.win;
    const rtn =  (wnd.*.attrib & df.VISIBLE);
    return (rtn == 0);
}

pub fn SetVisible(self: *TopLevelFields) void {
    const wnd = self.win;
    wnd.*.attrib |= df.VISIBLE;
}

pub fn ClearVisible(self: *TopLevelFields) void {
    const wnd = self.win;
    wnd.*.attrib &= ~df.VISIBLE;
}

// Accessories for c
pub fn get_zin(wnd:df.WINDOW) ?*TopLevelFields {
    if (wnd) |w| {
        if (w.*.zin) |z| {
            const win:*TopLevelFields = @ptrCast(@alignCast(z));
            return win;
        }
    }
    return null;
}

pub export fn get_modal(wnd:df.WINDOW) df.BOOL {
    var rtn:df.BOOL = df.FALSE;
    if (get_zin(wnd)) |win| {
        if (win.modal) {
            rtn = df.TRUE;
        }
    }
    return rtn;
}

pub export fn set_modal(wnd:df.WINDOW, val:df.BOOL) void {
    if (get_zin(wnd)) |win| {
        win.modal = if (val == df.TRUE) true else false;
    }
}
