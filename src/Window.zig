const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Klass = @import("Classes.zig");
const WndProc = @import("WndProc.zig");
const normal = @import("Normal.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;
const CLASS = @import("Classes.zig").CLASS;
const k = CLASS; // abbreviation
const colors = @import("Colors.zig");
const r = colors;
const Dialogs = @import("Dialogs.zig");
const app = @import("Application.zig");
const menus = @import("Menus.zig");
const GapBuf = @import("GapBuffer.zig");
const cfg = @import("Config.zig");
const picture = @import("PictureBox.zig");
const video = @import("Video.zig");
const Rect = @import("Rect.zig");

pub const Center = packed struct {
    LEFT: bool = false,
    TOP: bool = false,
    WIDTH: bool = false,
    HEIGHT: bool = false,
};

pub const CENTER_POSITION:Center = .{
    .LEFT = true,
    .TOP = true,
};

pub const CENTER_SIZE:Center = .{
    .WIDTH = true,
    .HEIGHT = true,
};

pub const Condition = enum {
    ISRESTORED,
    ISMINIMIZED,
    ISMAXIMIZED,
    ISCLOSING,
};

pub const PayloadType = enum {
    filename,
    dbox,
    control,
    menubar,
};

pub const Payload = union(PayloadType) {
    filename: []const u8,
    dbox: *Dialogs.DBOX,
    control: *Dialogs.CTLWINDOW,
    menubar: *menus.MBAR,
};

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();

pub var inFocus:?*TopLevelFields = null;
var line = [_]u8{0}**df.MAXCOLS;

Class:CLASS,                 // window class
title:?[:0]const u8 = null,  // window title
wndproc: ?*const fn (win:*TopLevelFields, msg: df.MESSAGE, params:q.Params) bool,

// ---------------- window dimensions -----------------
rc:Rect = .{ .left = 0, .top = 0,         // window coordinates
             .right = 0, .bottom = 0},    // (0/0 to 79/24)
ht:usize = 0,                             // window height and width.
wd:usize = 0,
RestoredRC:Rect = .{ .left = 0, .top = 0, // restored condition rect
                    .right = 0, .bottom = 0},

// ----------------- window colors --------------------
WindowColors:[4][2]u8 = @splat(@splat(0)),

// -------------- linked list pointers ----------------
parent:?*TopLevelFields = null,       // parent window
firstchild:?*TopLevelFields  = null,  // first child this parent
lastchild:?*TopLevelFields   = null,  // last child this parent
nextsibling:?*TopLevelFields = null,  // next sibling
prevsibling:?*TopLevelFields = null,  // previous sibling
childfocus:?*TopLevelFields  = null,  // child that ha(s/d) focus

attrib:c_int = 0,                     // Window attributes
restored_attrib:c_int = 0,            // attributes when restored
videosave:?[]u16 = null,              // video save buffer
condition: Condition = .ISRESTORED,   // Restored, Maximized, Minimized, Closing
oldcondition: Condition = .ISRESTORED,// previous condition
wasCleared:bool = false,

extension:?Payload = null,            // menus, dialogs, documents, etc
PrevMouse:?*TopLevelFields    = null, // previous mouse capture
PrevKeyboard:?*TopLevelFields = null, // previous keyboard capture
PrevClock:?*TopLevelFields    = null, // previous clock capture
MenuBar:?*TopLevelFields      = null, // menu bar
StatusBar:?*TopLevelFields    = null, // status bar
isHelping:u32 = 0,                    // > 0 when help is being displayed

// ----------------- text box fields ------------------
wlines:usize = 0,             // number of lines of text
wtop:usize = 0,               // text line that is on the top display
wleft:usize = 0,              // left position in window viewport
textwidth:usize = 0,          // width of longest line in textbox

gapbuf:?*GapBuf = null,       // gap buffer

BlkBegLine:usize = 0,         // beginning line of marked block
BlkBegCol:usize  = 0,         // beginning column of marked block
BlkEndLine:usize = 0,         // ending line of marked block
BlkEndCol:usize  = 0,         // ending column of marked block
HScrollBox:usize = 0,         // position of horizontal scroll box
VScrollBox:usize = 0,         // position of vertical scroll box
TextPointers:[]c_uint = &.{}, // -> list of line offsets

// ----------------- list box fields ------------------
selection:?usize = null,   // current selection, -1 for none
AddMode:bool = false,      // adding extended selections mode
AnchorPoint:isize = -1,    // anchor point for extended selections
SelectCount:usize = 0,     // count of selected items

// ----------------- edit box fields ------------------
CurrCol:usize = 0,         // Current column
CurrLine:usize = 0,        // Current line
WndRow:usize = 0,          // Current window row
TextChanged:bool = false,  // TRUE if text has changed
protected:bool = false,    // TRUE to display
DeletedText:?[]u8 = null,  // for undo
DeletedLength:usize = 0,   // Length of deleted field
InsertMode:bool = false,   // TRUE or FALSE for text insert
WordWrapMode:bool = false, // TRUE or FALSE for word wrap
MaxTextLength:usize = 0,   // maximum text length

// ---------------- dialog box fields ----------------- 
ReturnCode:c = c.ID_NULL,       // return code from a dialog box
modal: bool = false,            // True if a modeless dialog box
ct:?*Dialogs.CTLWINDOW = null,  // control structure
dfocus:?*TopLevelFields = null, // control window that has focus

// -------------- popdownmenu fields ------------------
mnu:?*menus.MENU = null,        // points to menu structure
holdmenu:?*menus.MBAR = null,   // previous active menu
oldFocus:?*TopLevelFields = null,

// -------------- status bar fields -------------------
TimePosted:bool = false,        // True if time has been posted

// ------------- picture box fields -------------------
VectorList:?[]picture.VECT = null,   // list of picture box vectors

win: df.WINDOW,

pub fn init(wnd: df.WINDOW) TopLevelFields {
    return .{
        .Class = CLASS.FORCEINTTYPE,
        .win = wnd,
        .wndproc = null,
    };
}

pub fn create(
    klass: CLASS,                // class of this window
    ttl: ?[:0]const u8,          // title or NULL
    left: usize, top: usize,     // upper left coordinates
    height: usize, width: usize, // dimensions
    payload: ?Payload,           // pointer to additional data
    parent: ?*TopLevelFields,    // parent of this window
    wndproc: ?*const fn (win:*TopLevelFields, msg: df.MESSAGE, params:q.Params) bool,
    attrib: c_int,
    position: Center) *TopLevelFields {

    const title = ttl;
    const wnd:df.WINDOW = @ptrCast(@alignCast(df.DFcalloc(1, @sizeOf(df.window))));

    var self:*TopLevelFields = undefined;
    if (root.global_allocator.create(TopLevelFields)) |s| {
       self = s;
    } else |_| {
        // error
    }
    self.* = init(wnd);

    video.get_videomode();

    if (wnd != null) {
        // This need to go first. Otherwise, SendMessage() will not have this class available
        wnd.*.zin = @ptrCast(@alignCast(self));

        // ----- height, width = -1: fill the screen -------
        var ht = height;
        if (position.HEIGHT)
            ht = @intCast(df.SCREENHEIGHT);
        var wt = width;
        if (position.WIDTH)
            wt = @intCast(df.SCREENWIDTH);

        // ----- coordinates -1, -1 = center the window ----
//        const hht:c_int = @intCast(ht);
//        const wwt:c_int = @intCast(wt);
        if (position.LEFT) {
            self.rc.left = @divFloor(@as(usize, @intCast(df.SCREENWIDTH))-wt, 2);
        } else {
            self.rc.left = left;
        }
        if (position.TOP) {
            self.rc.top = @divFloor(@as(usize, @intCast(df.SCREENHEIGHT))-ht, 2);
        } else {
            self.rc.top = top;
        }
        self.attrib = attrib;
        if (ttl) |tt| {
            if (tt.len > 0) {
                // df.AddAttribute(wnd, df.HASTITLEBAR);
                 self.attrib |= df.HASTITLEBAR;
            }
        }
        if (wndproc == null) {
            const idx:usize = @intCast(@intFromEnum(klass));
            self.wndproc = Klass.defs[idx][2]; // wndproc
        } else {
            self.wndproc = wndproc;
        }

        // ---- derive attributes of base classes ----
        var base = klass;
        while (base != CLASS.FORCEINTTYPE) {
            const cls = Klass.defs[@intCast(@intFromEnum(base))];
            const attr:c_int = @intCast(cls[3]); // attributes
            // df.AddAttribute(wnd, attr);
            self.attrib |= attr;
            base = cls[1]; // base
        }

        // ---- adjust position with parent ----
        var pt = parent;
        if (parent) |pw| {
            if (self.TestAttribute(df.NOCLIP) == false) {
                // -- keep upper left within borders of parent -
                self.rc.left = @max(self.rc.left, pw.GetClientLeft());
                self.rc.top = @max(self.rc.top, pw.GetClientTop());
            }
        } else {
            if (app.ApplicationWindow) |awin| {
                pt = awin;
            } else {
                pt = null; // unreachable
            }
        }

        self.Class = klass;
        if (payload) |py| {
            switch(py) {
                .filename => {
                    self.extension = .{.filename = py.filename};
                },
                .dbox => {
                    self.extension = .{.dbox = py.dbox};
                },
                .control => {
                    self.extension = .{.control = py.control};
                },
                .menubar => {
                    self.extension = .{.menubar = py.menubar};
                },
            }
        }


        self.rc.right = self.rc.left+wt-1;
        self.rc.bottom = self.rc.top+ht-1;
        self.ht = ht;
        self.wd = wt;
        if (ttl != null) {
            InsertTitle(self, title);
        }
        self.parent = pt;
        self.oldcondition = .ISRESTORED;
        self.condition = .ISRESTORED;
        self.RestoredRC = self.rc;
        InitWindowColors(self);
        _ = self.sendMessage(df.CREATE_WINDOW, q.none);
        if (self.isVisible()) {
            _ = self.sendMessage(df.SHOW_WINDOW, q.none);
        }
    }

    return self;
}

// --------- message prototypes -----------
pub fn sendTextMessage(self: *TopLevelFields, msg:df.MESSAGE, p1: []const u8) bool {
    // Be sure to send null-terminated string to c.
    if (root.global_allocator.dupeZ(u8, p1)) |txt| {
        defer root.global_allocator.free(txt); // does TextBox also make a copy ?
        return self.sendMessage(msg, .{.slice=txt});
    } else |_| {
        // error
    }
    return false;
}

pub fn sendCommandMessage(self: *TopLevelFields, p1: c, p2: df.PARAM) bool {
    return self.sendMessage(df.COMMAND, .{.command=.{p1, @intCast(p2)}});
}

// --------- send a message to a window -----------
pub fn sendMessage(self: *TopLevelFields, msg:df.MESSAGE, params:q.Params) bool {
    var rtn = true;

    switch (msg) {
        df.PAINT,
        df.BORDER => {
            // ------- don't send these messages unless the
            //    window is visible --------
            if (self.isVisible()) {
                if (self.wndproc) |wndproc| {
                    rtn = wndproc(self, msg, params);
                }
            }
        },
        df.RIGHT_BUTTON,
        df.LEFT_BUTTON,
        df.DOUBLE_CLICK,
        df.BUTTON_RELEASED => {
            // --- don't send these messages unless the
            //  window is visible or has captured the mouse --
            if ((self.isVisible()) or (self == q.CaptureMouse)) {
                if (self.wndproc) |wndproc| {
                    rtn = wndproc(self, msg, params);
                }
            }
        },
        df.KEYBOARD,
        df.SHIFT_CHANGED => {
            // ------- don't send these messages unless the
            //  window is visible or has captured the keyboard --
            if ((self.isVisible()) or (self == q.CaptureKeyboard)) {
                if (self.wndproc) |wndproc| {
                    rtn = wndproc(self, msg, params);
                }
            }
        },
        else => {
            if (self.wndproc) |wndproc| {
                rtn = wndproc(self, msg, params);
            }
        }
    }

    // ----- window processor returned true or the message was sent
    //  to no window at all (NULL) -----
    return q.ProcessMessage(self, msg, params, rtn);
}

// -------- add a title to a window ---------
pub fn AddTitle(self: *TopLevelFields, ttl:?[:0]const u8) void {
    InsertTitle(self, ttl);
    _ = self.sendMessage(df.BORDER, .{.paint=.{null, false}});
}

// ----- insert a title into a window ----------
pub fn InsertTitle(self: *TopLevelFields, ttl:?[:0]const u8) void {
    if (self.title) |t| {
        root.global_allocator.free(t);
        self.title = null;
    }
    if (ttl) |title| {
        if (root.global_allocator.dupeZ(u8, title)) |t| {
            self.title = t;
        } else |_| {
        }
    }
//    wnd->title=DFrealloc(wnd->title,strlen(ttl)+1);
//    strcpy(wnd->title, ttl);
}

// ------ write a line to video window client area ------
pub fn writeline(self:*TopLevelFields, str:[:0]const u8, x:usize, y:usize, pad:bool) void {
    var wline = [_]u8{0}**df.MAXCOLS;
    const len:usize = @intCast(LineLength(@constCast(str.ptr)));
    const dif = str.len - len;
    var limit = str.len;
    if (limit > self.ClientWidth() + dif) {
        limit = self.ClientWidth() + dif;
    }
    @memcpy(wline[0..limit], str[0..limit]);
    if (pad) {
        for (limit..self.ClientWidth()-x) |idx|{
            wline[idx] = ' ';
        }
    }
    video.wputs(self, @ptrCast(&wline), x, y);
}

pub fn AdjustRectangle(self:*TopLevelFields, rcc:Rect) Rect {
    var rc = rcc;
    // -------- adjust the rectangle -------
    if (self.TestAttribute(df.HASBORDER)) {
        if (rc.left == 0) {
            rc.right -|= 1;
        } else if (rc.left < rc.right and rc.left < self.WindowWidth()+1) {
            rc.left -|= 1;
        }
    }
    if (self.TestAttribute(df.HASBORDER | df.HASTITLEBAR)) {
        if (rc.top == 0) {
            rc.bottom -|= 1;
        } else if (rc.top < rc.bottom and rc.top < self.WindowHeight()+1) {
            rc.top -|= 1;
        }
    }
    rc.right = @max(rc.left, @min(rc.right, self.WindowWidth()));
    rc.bottom = @max(rc.top, @min(rc.bottom, self.WindowHeight()));
    return rc;
}

// -------- display a window's title ---------
pub fn DisplayTitle(self:*TopLevelFields, rcc:?Rect) void {
    if (self.title) |_| {
        var rc:Rect = rcc orelse Rect.RelativeWindowRect(self, self.WindowRect());
        rc = self.AdjustRectangle(rc);
        if (self.sendMessage(df.TITLE, .{.paint=.{rcc, false}})) {
            const title_color = cfg.config.clr[@intCast(@intFromEnum(k.TITLEBAR))];
            if (self == inFocus) {
                df.foreground = title_color [r.HILITE_COLOR] [r.FG];
                df.background = title_color [r.HILITE_COLOR] [r.BG];
            } else {
                df.foreground = title_color [r.STD_COLOR] [r.FG];
                df.background = title_color [r.STD_COLOR] [r.BG];
            }
            const ttlen = if (self.title) |tt| tt.len else 0;
            const tlen:usize = @min(ttlen, self.WindowWidth()-2);
            const tend:usize = self.WindowWidth()-3-self.BorderAdj();
            @memset(line[0..self.WindowWidth()],  ' ');
            if (self.condition != .ISMINIMIZED) {
                const pos:usize = @divFloor(self.WindowWidth()-2-tlen, 2);
                @memcpy(line[pos..pos+tlen], self.title orelse "");
//                strncpy(line + ((WindowWidth(wnd)-2 - tlen) / 2),
//                            GetTitle(wnd), tlen);
            }
            if (self.TestAttribute(df.CONTROLBOX))
                line[2-self.BorderAdj()] = df.CONTROLBOXCHAR;
            if (self.TestAttribute(df.MINMAXBOX)) {
                switch (self.condition) {
                    .ISRESTORED => {
                        line[tend+1] = df.MAXPOINTER;
                        line[tend]   = df.MINPOINTER;
                    },
                    .ISMINIMIZED => {
                        line[tend+1] = df.MAXPOINTER;
                    },
                    .ISMAXIMIZED => {
                        line[tend]   = df.MINPOINTER;
                        line[tend+1] = df.RESTOREPOINTER;
                    },
                    else => {
                    }
                }
            }
            line[tend+3] = 0;
            line[rc.right+1] = 0;
            if (self != inFocus)
                df.ClipString += 1;
            self.writeline(@ptrCast(line[rc.left..]),
                        rc.left+self.BorderAdj(),
                        0, false);
            df.ClipString = 0;
        }
    }
}

// --- display right border shadow character of a window ---
fn shadow_char(self:*TopLevelFields, y:usize) void {
    const fg = df.foreground;
    const bg = df.background;
    const xx:usize = self.WindowWidth();
    const yy:usize = y;
    const chr = video.GetVideoChar(@intCast(self.GetLeft()+xx), @intCast(self.GetTop()+yy)) & 255;

    if (self.TestAttribute(df.SHADOW) == false or
        self.condition == .ISMINIMIZED or
        self.condition == .ISMAXIMIZED or
        cfg.config.mono > 0) {
        // No shadow
        return;
    }
    df.foreground = r.DARKGRAY;
    df.background = r.BLACK;
    video.wputch(self, chr, xx, yy);
    df.foreground = fg;
    df.background = bg;
}

// --- display the bottom border shadow line for a window --
fn shadowline(self:*TopLevelFields, rcc:Rect) void {
    var rc = rcc;
    const fg = df.foreground;
    const bg = df.background;

    if (self.TestAttribute(df.SHADOW) == false or
        self.condition == .ISMINIMIZED or
        self.condition == .ISMAXIMIZED or
        cfg.config.mono > 0) {
        // No shadow
        return;
    }

    const len:usize = self.WindowWidth();
    if (root.global_allocator.allocSentinel(u8, len+1, 0)) |buf| {
        defer root.global_allocator.free(buf);
        const y = self.GetBottom()+1;
        const left:usize = self.GetLeft();
        for (0..len+1) |idx| {
            buf[idx] = @intCast(video.GetVideoChar(@intCast(left+idx), @intCast(y)) & 255);
        }
        buf[len+1] = 0;

        df.foreground = r.DARKGRAY;
        df.background = r.BLACK;

        buf[rc.right+1] = 0;
        if (rc.left == 0)
            rc.left += 1;

        df.ClipString += 1;

        video.wputs(self, buf[rc.left..], rc.left, self.WindowHeight());

        df.ClipString -= 1;

        df.foreground = fg;
        df.background = bg;
    } else |_| {
    }
}

fn ParamRect(self:*TopLevelFields, rcc:?Rect) Rect {
    var rc:Rect = undefined;
    if (rcc) |cc| {
        rc = cc;
    } else {
        rc = Rect.RelativeWindowRect(self, self.WindowRect());
        if (self.TestAttribute(df.SHADOW)) {
            rc.right += 1;
            rc.bottom += 1;
        }
    }
    return rc;
}

// Not in use
//void PaintShadow(WINDOW wnd)
//{
//        int y;
//        RECT rc = ParamRect(wnd, NULL);
//        for (y = 1; y < WindowHeight(wnd); y++)
//                shadow_char(wnd, y);
//    shadowline(wnd, rc);
//}

fn SeCorner(self:*TopLevelFields, stdse:u8) u8 {
    if (self.TestAttribute(df.SIZEABLE) and self.condition == .ISRESTORED)
        return df.SIZETOKEN;
    return stdse;
}

// probably not well tested because most windows have titles
fn TopLine(self:*TopLevelFields, lin:u8, rcc:Rect) void {
    var rc = rcc;
    if (self.TestAttribute(df.HASMENUBAR))
        return;
    if (self.TestAttribute(df.HASTITLEBAR) and self.title != null)
        return;

    if (rc.left == 0) {
        rc.left += self.BorderAdj();
        rc.right += self.BorderAdj();
    }

    if (rc.right < self.WindowWidth()-1)
        rc.right += 1;

    if (rc.left < rc.right) {
        // ----------- top line -------------
        @memset(line[0..self.WindowWidth()-1], lin);
//        @memset(line,lin,WindowWidth(wnd)-1);
        if (self.TestAttribute(df.CONTROLBOX)) {
            @memcpy(line[1..4], "   ");
            line[2] = df.CONTROLBOXCHAR;
//                        strncpy(line+1, "   ", 3);
//                        *(line+2) = CONTROLBOXCHAR;
        }
        line[rc.right] = 0;
        self.writeline(@ptrCast(line[rc.left..rc.right]), rc.left, 0, false);
    }
}

// ------- display a window's border -----
pub fn RepaintBorder(self:*TopLevelFields, rcc:?Rect) void {
    if (self.TestAttribute(df.HASBORDER) == false)
        return;
    const rc = self.ParamRect(rcc);

    // ---------- window title ------------
    if (self.TestAttribute(df.HASTITLEBAR)) {
        if (rc.top == 0) {
            if (rc.left < self.WindowWidth()-self.BorderAdj()) {
                self.DisplayTitle(rc);
            }
        }
    }

    df.foreground = colors.FrameForeground(self);
    df.background = colors.FrameBackground(self);
    const clrc = self.AdjustRectangle(rc);

    var lin:u8 = 0;
    var side:u8 = 0;
    var ne:u8 = 0;
    var nw:u8 = 0;
    var se:u8 = 0;
    var sw:u8 = 0;

    if (self == inFocus) {
        lin  = df.FOCUS_LINE;
        side = df.FOCUS_SIDE;
        ne   = df.FOCUS_NE;
        nw   = df.FOCUS_NW;
        se   = SeCorner(self, df.FOCUS_SE);
        sw   = df.FOCUS_SW;
    } else {
        lin  = df.LINE;
        side = df.SIDE;
        ne   = df.NE;
        nw   = df.NW;
        se   = SeCorner(self, df.SE);
        sw   = df.SW;
    }

    line[self.WindowWidth()] = 0; // maybe @memset ? Title was draw already
    // -------- top frame corners ---------
    if (rc.top == 0) {
        if (rc.left == 0)
            video.wputch(self, nw, 0, 0);
        if (rc.left < self.WindowWidth()) {
            if (rc.right >= self.WindowWidth()-1) {
                video.wputch(self, ne, self.WindowWidth()-1, 0);
            }
            self.TopLine(lin, clrc);
        }
    }

    // ----------- window body ------------
    for (rc.top..rc.bottom+1) |ydx| {
        var ch:u8 = 0;
        if (ydx == 0 or ydx >= self.WindowHeight()-1)
            continue;
        if (rc.left == 0)
            video.wputch(self, side, 0, ydx);
        if (rc.left < self.WindowWidth() and
            rc.right >= self.WindowWidth()-1) {
            if (self.TestAttribute(df.VSCROLLBAR)) {
                if (ydx == 1) {
                    ch = df.UPSCROLLBOX;
                } else if (ydx == self.WindowHeight()-2) {
                    ch = df.DOWNSCROLLBOX;
                } else if (ydx-1 == self.VScrollBox) {
                    ch = df.SCROLLBOXCHAR;
                } else {
                    ch = df.SCROLLBARCHAR;
                }
            } else {
                ch = side;
            }
            video.wputch(self, ch, self.WindowWidth()-1, ydx);
        }
        if (rc.right == self.WindowWidth())
            shadow_char(self, ydx);
    }

    if (rc.top <= self.WindowHeight()-1 and
            rc.bottom >= self.WindowHeight()-1) {
        // -------- bottom frame corners ----------
        if (rc.left == 0)
            video.wputch(self, sw, 0, self.WindowHeight()-1);
        if (rc.left < self.WindowWidth() and
                rc.right >= self.WindowWidth()-1) {
            video.wputch(self, se, self.WindowWidth()-1, self.WindowHeight()-1);
        }

        if (self.StatusBar == null) {
            // ----------- bottom line -------------
            @memset(line[0..self.WindowWidth()-1], lin);
            if (self.TestAttribute(df.HSCROLLBAR)) {
                line[0] = df.LEFTSCROLLBOX;
                line[self.WindowWidth()-3] = df.RIGHTSCROLLBOX;
                @memset(line[1..self.WindowWidth()-4+1], df.SCROLLBARCHAR);
                line[self.HScrollBox] = df.SCROLLBOXCHAR;
            }
            line[rc.right] = 0;
            line[self.WindowWidth()-2] = 0;
            if (rc.left != rc.right or
                (rc.left>0 and rc.left < self.WindowWidth()-1)) {
                if (self != inFocus) {
                    df.ClipString += 1;
                }
                self.writeline(@ptrCast(line[clrc.left..]),
                             clrc.left+1,
                             self.WindowHeight()-1,
                             false);
                df.ClipString = 0;
            }
        }
        if (rc.right == self.WindowWidth())
            shadow_char(self, self.WindowHeight()-1);
    }

    if (rc.bottom == self.WindowHeight()) {
        // ---------- bottom shadow -------------
        shadowline(self, rc);
    }
}

// ------ clear the data space of a window -------- 
pub fn ClearWindow(self:*TopLevelFields, rcc:?Rect, clrchar:u8) void {
    const wnd = self.win;
    if (self.isVisible()) {
        var rc:Rect = rcc orelse Rect.RelativeWindowRect(self, self.WindowRect());
        const top = self.TopBorderAdj();
        const bot = self.WindowHeight()-1-self.BottomBorderAdj();

        if (rc.left == 0)
            rc.left = self.BorderAdj();
        if (rc.right > self.WindowWidth()-1)
            rc.right = self.WindowWidth()-1;
        colors.SetStandardColor(wnd);

        if (root.global_allocator.allocSentinel(u8, rc.right+1, 0)) |buf| {
            defer root.global_allocator.free(buf);
            @memset(buf, clrchar);
            buf[buf.len] = 0;
            for (rc.top..rc.bottom+1) |ydx| {
                if (ydx < top or ydx > bot)
                    continue;
                self.writeline(@ptrCast(buf[rc.left..]), rc.left, ydx, false);
            }
        } else |_| {
        }
    }
}

// ------ compute the logical line length of a window ------
pub export fn LineLength(ln:[*c]u8) c_int {
    const str = std.mem.span(ln);
    var len = str.len;

    var count = std.mem.count(u8, str, &[_]u8{df.CHANGECOLOR});
    len -= count * 3;
    count = std.mem.count(u8, str, &[_]u8{df.RESETCOLOR});
    len -= count;

    return @intCast(len);
}


pub fn InitWindowColors(win:*TopLevelFields) void {
    var cls = win.Class;
    var icls:usize = @intCast(@intFromEnum(cls));
    // window classes without assigned colors inherit parent's colors
    if (cfg.config.clr[icls][0][0] == 0xff) {
        if (win.parent) |pw| {
            cls = pw.Class;
        }
    }
    icls = @intCast(@intFromEnum(cls));
    // ---------- set the colors ----------
    for (0..2) |fbg| {
        for (0..4) |col| {
            win.WindowColors[col][fbg] = cfg.config.clr[icls][col][fbg];
        }
    }
}

pub fn PutWindowChar(self: *TopLevelFields, chr:u16, x:usize, y:usize) void {
    if (x < self.ClientWidth() and y < self.ClientHeight()) {
        video.wputch(self, chr, x+self.BorderAdj(), y+self.TopBorderAdj());
    }
}

pub fn PutWindowLine(self: *TopLevelFields, s:[:0]const u8, x:usize, y:usize) void {
    const str:[:0]u8 = @constCast(s);
    var saved = false;
    var sv:u8 = 0;

    if (x < self.ClientWidth() and y < self.ClientHeight()) {
        var len:usize = s.len;
        if (std.mem.indexOfScalar(u8, s, 0)) |pos| {
            len = pos;
        }

        const limit:usize = self.ClientWidth() - x; // right limit
        if (len + x > self.ClientWidth()) {
            sv = str[limit];
            str[limit] = 0;
            saved = true;
        }

        df.ClipString += 1;
        video.wputs(self, str, self.BorderAdj()+x, self.TopBorderAdj()+y);
        df.ClipString -= 1;

        if (saved) {
            str[limit] = sv;
        }
    }
}

// ------- window methods -----------
pub fn WindowHeight(self: *TopLevelFields) usize {
    return self.ht;
}

pub fn SetWindowHeight(self: *TopLevelFields, height: isize) void {
    self.ht = @intCast(height);
}

pub fn WindowWidth(self: *TopLevelFields) usize {
    return self.wd;
}

pub fn BorderAdj(self: *TopLevelFields) usize {
    return if (self.TestAttribute(df.HASBORDER)) 1 else 0;
}

pub fn BottomBorderAdj(self: *TopLevelFields) usize {
    var border = BorderAdj(self);
    if (self.TestAttribute(df.HASSTATUSBAR)) {
        border = 1;
    }
    return border;
}

pub fn TopBorderAdj(self: *TopLevelFields) usize {
    var border:usize = 0;
    if ((self.TestAttribute(df.HASTITLEBAR)) and (self.TestAttribute(df.HASMENUBAR))) {
        border = 2;
    } else {
        if (self.TestAttribute(df.HASTITLEBAR | df.HASMENUBAR | df.HASBORDER)) {
            border = 1;
        }
    }
    return border;
}

pub fn ClientWidth(self: *TopLevelFields) usize {
    if (self.WindowWidth()>self.BorderAdj()*2) {
        return self.WindowWidth()-self.BorderAdj()*2;
    }
    return 0;
}

pub fn ClientHeight(self: *TopLevelFields) usize {
    const adj = self.TopBorderAdj()+self.BottomBorderAdj();
    if (self.WindowHeight() > adj) {
        return self.WindowHeight() - adj;
    }
    return 0;
}

pub fn WindowRect(self: *TopLevelFields) Rect {
    return self.rc;
}

pub fn GetTop(self: *TopLevelFields) usize {
    const rect = self.WindowRect();
    return rect.top;
}
pub fn SetTop(self: *TopLevelFields, top: usize) void {
    self.rc.top = top;
}

pub fn GetBottom(self: *TopLevelFields) usize {
    const rect = self.WindowRect();
    return rect.bottom;
}

pub fn SetBottom(self: *TopLevelFields, bottom: usize) void {
    self.rc.bottom = bottom;
}

pub fn GetLeft(self: *TopLevelFields) usize {
    const rect = self.WindowRect();
    return rect.left;
}

pub fn SetLeft(self: *TopLevelFields, left: usize) void {
    self.rc.left = left;
}

pub fn GetRight(self: *TopLevelFields) usize {
    const rect = self.WindowRect();
    return rect.right;
}

pub fn SetRight(self: *TopLevelFields, right: usize) void {
    self.rc.right = right;
}

pub fn GetClientTop(self: *TopLevelFields) usize {
    return self.GetTop() + self.TopBorderAdj();
}

pub fn GetClientBottom(self: *TopLevelFields) usize {
    return self.GetBottom() - self.BottomBorderAdj();
}

pub fn GetClientLeft(self: *TopLevelFields) usize {
    return self.GetLeft() + self.BorderAdj();
}

pub fn GetClientRight(self: *TopLevelFields) usize {
    return self.GetRight() - self.TopBorderAdj();
}

// ------- return the client rectangle of a window ------
pub fn ClientRect(self: *TopLevelFields) Rect {
    const rc:Rect = .{
        .left = self.GetClientLeft(),
        .top = self.GetClientTop(),
        .right = self.GetClientRight(),
        .bottom = self.GetClientBottom(),
    };
    return rc;
}

pub fn getClass(self: *TopLevelFields) CLASS {
    return self.Class;
}

pub fn GetAttribute(self: *TopLevelFields) c_int {
    return self.attrib;
}

pub fn AddAttribute(self: *TopLevelFields, attr: c_int) void {
    self.attrib |= attr;
}

pub fn ClearAttribute(self: *TopLevelFields, attr: c_int) void {
    self.attrib &= ~attr;
}

pub fn TestAttribute(self: *TopLevelFields, attr: c_int) bool {
    return (self.attrib & attr) > 0;
}

pub fn isHidden(self: *TopLevelFields) bool {
    const rtn = (self.attrib & df.VISIBLE);
    return (rtn == 0);
}

pub fn SetVisible(self: *TopLevelFields) void {
    self.attrib |= df.VISIBLE;
}

pub fn ClearVisible(self: *TopLevelFields) void {
    self.attrib &= ~df.VISIBLE;
}

pub fn isVisible(self: *TopLevelFields) bool {
    return normal.isVisible(self);
}

//#define isMultiLine(wnd) TestAttribute(wnd, MULTILINE)
pub fn isMultiLine(self: *TopLevelFields) bool {
    return self.TestAttribute(df.MULTILINE);
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

pub fn currPos(self: *TopLevelFields) usize {
    const col:c_uint = @intCast(self.CurrCol);
    return self.TextPointers[self.CurrLine]+col;
}

// return position of beginning of line specified by sel
pub fn textLine(self: *TopLevelFields, sel:usize) usize {
    return self.TextPointers[sel];
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

// Accessories
pub fn GetControl(self:*TopLevelFields) ?*Dialogs.CTLWINDOW {
    return self.ct;
}

pub fn getGapBuffer(self:*TopLevelFields, size:usize) ?*GapBuf {
    if (self.gapbuf == null) {
        if (GapBuf.init(root.global_allocator, size)) |buf| {
            self.gapbuf = @constCast(buf);
        } else |_| {
            return null;
        }
    }
    return self.gapbuf orelse null;
}

pub export fn c_ClientWidth(wnd:df.WINDOW) c_int {
    if (TopLevelFields.get_zin(wnd)) |win| {
        return @intCast(win.ClientWidth());
    }
    return 0;
}

pub fn HitControlBox(self:*TopLevelFields, x:usize, y:usize) bool {
    return (self.TestAttribute(df.CONTROLBOX) and x == 2 and y == 0);
}
