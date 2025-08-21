const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");

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
    ttl: ?[]const u8,            // title or NULL
    left:c_int, top:c_int,      // upper left coordinates
    height:c_int, width:c_int,  // dimensions
    extension:?*anyopaque,       // pointer to additional data
    parent: df.WINDOW,          // parent of this window
    wndproc: ?*const fn (wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int,
    attrib: c_int) *TopLevelFields {

    const title = if (ttl) |t| t.ptr else null;
    const wnd:df.WINDOW = df.cCreateWindow(
        klass,
        title,
        left, top, height, width, 
        extension, parent, wndproc, attrib
    );

    var self:*TopLevelFields = undefined;
    if (root.global_allocator.create(TopLevelFields)) |s| {
       self = s;
    } else |_| {
        // error
    }
    self.* = init(wnd, root.global_allocator);
    wnd.*.zin = @ptrCast(@alignCast(self));
    return self;
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
