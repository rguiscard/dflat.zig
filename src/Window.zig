const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Klass = @import("Classes.zig");
const WndProc = @import("WndProc.zig");
const normal = @import("Normal.zig");
const q = @import("Message.zig");
const Dialogs = @import("Dialogs.zig");
const app = @import("Application.zig");

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();
pub var inFocus:?*TopLevelFields = null;

wndproc: ?*const fn (win:*TopLevelFields, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool,

// -------------- linked list pointers ----------------
parent:?*TopLevelFields = null,       // parent window
firstchild:?*TopLevelFields = null,   // first child this parent
lastchild:?*TopLevelFields = null,    // last child this parent
nextsibling:?*TopLevelFields = null,  // next sibling
prevsibling:?*TopLevelFields = null,  // previous sibling
childfocus:?*TopLevelFields = null,   // child that ha(s/d) focus

// ----------------- text box fields ------------------
text:?[]u8 = null,   // window text
textlen:usize = 0,   // text length

// ----------------- edit box fields ------------------
DeletedText:?[]u8 = null,    // for undo
DeletedLength:usize = 0,     // Length of deleted field

// ---------------- dialog box fields ----------------- 
modal: bool = false,            // True if a modeless dialog box
ct:?*Dialogs.CTLWINDOW = null,  // control structure
dfocus:?*TopLevelFields = null, // control window that has focus

// -------------- popdownmenu fields ------------------
oldFocus:?*TopLevelFields = null,

// ------------- picture box fields -------------------
VectorList:?[]df.VECT = null, // list of picture box vectors

allocator: std.mem.Allocator,
win: df.WINDOW,

// --------- create a window ------------
pub export fn CreateWindow(
    klass:df.CLASS,              // class of this window
    ttl:[*c]u8,                  // title or NULL
    left:c_int, top:c_int,       // upper left coordinates
    height:c_int, width:c_int,   // dimensions
    extension:?*anyopaque,       // pointer to additional data
    parent:df.WINDOW,            // parent of this window
    attrib:c_int)                // window attribute
    callconv(.c) df.WINDOW
{
    const self = TopLevelFields;
    var title:?[]const u8 = null;
    if (ttl) |t| {
        title = std.mem.span(t);
    }

    var pwin:?*TopLevelFields = null;
    if (self.get_zin(parent)) |pw| {
        pwin = pw;
    }

    const win = self.create(klass, title, left, top, height, width, extension, pwin, null, attrib);
    return win.*.win;
}

pub fn init(wnd: df.WINDOW, allocator: std.mem.Allocator) TopLevelFields {
    return .{
        .win = wnd,
        .wndproc = null,
        .allocator = allocator,
    };
}

pub fn create(
    klass: df.CLASS,            // class of this window
    ttl: ?[]const u8,           // title or NULL
    left:c_int, top:c_int,      // upper left coordinates
    height:c_int, width:c_int,  // dimensions
    extension:?*anyopaque,      // pointer to additional data
    parent: ?*TopLevelFields,   // parent of this window
    wndproc: ?*const fn (win:*TopLevelFields, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool,
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
        // This need to go first. Otherwise, SendMessage() will not have this class available
        wnd.*.zin = @ptrCast(@alignCast(self));

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
//            wnd.*.wndproc = Klass.defs[@intCast(klass)][2]; // wndproc
            self.wndproc = Klass.defs[@intCast(klass)][2]; // wndproc
        } else {
//            wnd.*.wndproc = wndproc;
            self.wndproc = wndproc;
        }

        // ---- derive attributes of base classes ----
        var base = klass;
        while (base != -1) {
            const cls = Klass.defs[@intCast(base)];
            const attr:c_int = @intCast(cls[3]); // attributes
            // df.AddAttribute(wnd, attr);
            wnd.*.attrib = wnd.*.attrib | attr;
            base = @intFromEnum(cls[1]); // base
        }

        // ---- adjust position with parent ----
        var pt = parent;
//        if (parent != null) {
        if (parent) |pw| {
            if (df.TestAttribute(wnd, df.NOCLIP) == 0) {
//                const pwin:*TopLevelFields = @constCast(@fieldParentPtr("win", &parent));
                // -- keep upper left within borders of parent -
                wnd.*.rc.lf = @intCast(@max(wnd.*.rc.lf, pw.GetClientLeft()));
                wnd.*.rc.tp = @intCast(@max(wnd.*.rc.tp, pw.GetClientTop()));
            }
        } else {
            if (app.ApplicationWindow) |awin| {
//                pt = awin.win;
                pt = awin;
            } else {
                pt = null; // unreachable
            }
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
        self.parent = pt;
        wnd.*.oldcondition = df.ISRESTORED;
        wnd.*.condition = df.ISRESTORED;
        wnd.*.RestoredRC = wnd.*.rc;
        df.InitWindowColors(wnd);
        _ = df.SendMessage(wnd, df.CREATE_WINDOW, 0, 0);
        if (df.isVisible(wnd)>0) {
            _ = df.SendMessage(wnd, df.SHOW_WINDOW, 0, 0);
        }
    }

    return self;
}

// --------- message prototypes -----------
pub fn sendTextMessage(self: *TopLevelFields, msg:df.MESSAGE, p1: []u8, p2: df.PARAM) bool {
    // Be sure to send null-terminated string to c.
    if (self.allocator.dupeZ(u8, p1)) |txt| {
        defer self.allocator.free(txt);
        return self.sendMessage(msg, @intCast(@intFromPtr(txt.ptr)), p2);
    } else |_| {
        // error
    }
    return false;
}

// --------- send a message to a window -----------
pub fn sendMessage(self: *TopLevelFields, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = self.win;
    var rtn = true;

    switch (msg) {
        df.PAINT,
        df.BORDER => {
            // ------- don't send these messages unless the
            //    window is visible --------
            if (df.isVisible(wnd)>0) {
                if (self.wndproc) |wndproc| {
                    rtn = wndproc(self, msg, p1, p2);
                }
            }
        },
        df.RIGHT_BUTTON,
        df.LEFT_BUTTON,
        df.DOUBLE_CLICK,
        df.BUTTON_RELEASED => {
            // --- don't send these messages unless the
            //  window is visible or has captured the mouse --
            if ((df.isVisible(wnd)>0) or (wnd == df.CaptureMouse)) {
                if (self.wndproc) |wndproc| {
                    rtn = wndproc(self, msg, p1, p2);
                }
            }
        },
        df.KEYBOARD,
        df.SHIFT_CHANGED => {
            // ------- don't send these messages unless the
            //  window is visible or has captured the keyboard --
            if ((df.isVisible(wnd)>0) or (wnd == df.CaptureKeyboard)) {
                if (self.wndproc) |wndproc| {
                    rtn = wndproc(self, msg, p1, p2);
                }
            }
        },
        else => {
            if (self.wndproc) |wndproc| {
                rtn = wndproc(self, msg, p1, p2);
            }
        }
    }

    // ----- window processor returned true or the message was sent
    //  to no window at all (NULL) -----
    return q.ProcessMessage(wnd, msg, p1, p2, rtn);
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
    if (self.TestAttribute(df.HASBORDER)) {
        border = 1;
    }
    return border;
}

pub fn BottomBorderAdj(self: *TopLevelFields) isize {
    var border = BorderAdj(self);
    if (self.TestAttribute(df.HASSTATUSBAR)) {
        border = 1;
    }
    return border;
}

pub fn TopBorderAdj(self: *TopLevelFields) isize {
    var border:isize = 0;
    if ((self.TestAttribute(df.HASTITLEBAR)) and (self.TestAttribute(df.HASMENUBAR))) {
        border = 2;
    } else {
        if (self.TestAttribute(df.HASTITLEBAR | df.HASMENUBAR | df.HASBORDER)) {
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

// parent cannot be null theoretically
// dummy for drag do have parent (see dragborder()).
// application window do not have parent.
pub fn getParent(self: *TopLevelFields) *TopLevelFields {
    return self.parent orelse unreachable;
}

pub fn firstWindow(self: *TopLevelFields) ?*TopLevelFields {
    return self.firstchild;
}

pub fn lastWindow(self: *TopLevelFields) ?*TopLevelFields {
    return self.lastchild;
}

pub fn nextWindow(self: *TopLevelFields) ?*TopLevelFields {
    return self.nextsibling;
}

pub fn prevWindow(self: *TopLevelFields) ?*TopLevelFields {
    return self.prevsibling;
}

// Accessories for c
pub fn get_zin(wnd:df.WINDOW) ?*TopLevelFields {
    // @fieldParentPtr is not yet reliable at this stage. Therefore, use zin inserted into WINDOW in c.
    if (wnd) |w| {
        if (w.*.zin) |z| {
            const win:*TopLevelFields = @ptrCast(@alignCast(z));
            return win;
        }
    }
    return null;
}

pub export fn GetParent(wnd:df.WINDOW) df.WINDOW {
    if (get_zin(wnd)) |win| {
        if (win.parent) |pw| {
            return pw.win;
        }
    }
    return null; // unreachable
}

pub export fn set_NormalProc(wnd:df.WINDOW) void {
    if (get_zin(wnd)) |win| {
        win.wndproc = normal.NormalProc;
    }
}

pub export fn inFocusWnd() df.WINDOW {
    if (inFocus) |focus| {
        return focus.win;
    }
    return null;
}

// Accessories
pub fn GetControl(self:*TopLevelFields) ?*Dialogs.CTLWINDOW {
    return self.ct;
}
