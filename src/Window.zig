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

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();

pub var inFocus:?*TopLevelFields = null;
var line = [_]u8{0}**df.MAXCOLS;

Class:CLASS,                 // window class
title:?[:0]const u8 = null,  // window title
wndproc: ?*const fn (win:*TopLevelFields, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool,

// -------------- linked list pointers ----------------
parent:?*TopLevelFields = null,       // parent window
firstchild:?*TopLevelFields  = null,  // first child this parent
lastchild:?*TopLevelFields   = null,  // last child this parent
nextsibling:?*TopLevelFields = null,  // next sibling
prevsibling:?*TopLevelFields = null,  // previous sibling
childfocus:?*TopLevelFields  = null,  // child that ha(s/d) focus

PrevMouse:?*TopLevelFields    = null, // previous mouse capture
PrevKeyboard:?*TopLevelFields = null, // previous keyboard capture
PrevClock:?*TopLevelFields    = null, // previous clock capture
MenuBar:?*TopLevelFields      = null, // menu bar
StatusBar:?*TopLevelFields    = null, // status bar
isHelping:u32 = 0,                    // > 0 when help is being displayed

// ----------------- text box fields ------------------
gapbuf:?*GapBuf = null,       // gap buffer

BlkBegLine:usize = 0,         // beginning line of marked block
BlkBegCol:usize  = 0,         // beginning column of marked block
BlkEndLine:usize = 0,         // ending line of marked block
BlkEndCol:usize  = 0,         // ending column of marked block
HScrollBox:usize = 0,         // position of horizontal scroll box
VScrollBox:usize = 0,         // position of vertical scroll box
TextPointers:[]c_uint = &.{}, // -> list of line offsets

// ----------------- list box fields ------------------
selection:isize = -1,      // current selection, -1 for none
AddMode:bool = false,      // adding extended selections mode
AnchorPoint:isize = -1,    // anchor point for extended selections
SelectCount:usize = 0,     // count of selected items

// ----------------- edit box fields ------------------
TextChanged:bool = false,    // TRUE if text has changed
protected:bool = false,      // TRUE to display
DeletedText:?[]u8 = null,    // for undo
DeletedLength:usize = 0,     // Length of deleted field
InsertMode:bool = false,     // TRUE or FALSE for text insert
WordWrapMode:bool = false,   // TRUE or FALSE for word wrap
MaxTextLength:usize = 0,     // maximum text length

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
VectorList:?[]df.VECT = null,   // list of picture box vectors

win: df.WINDOW,

// --------- create a window ------------
pub export fn CreateWindow(
    klass:c_int,                 // class of this window
    ttl:[*c]u8,                  // title or NULL
    left:c_int, top:c_int,       // upper left coordinates
    height:c_int, width:c_int,   // dimensions
    extension:?*anyopaque,       // pointer to additional data
    parent:df.WINDOW,            // parent of this window
    attrib:c_int)                // window attribute
    callconv(.c) df.WINDOW
{
    const self = TopLevelFields;
    var title:?[:0]const u8 = null;
    if (ttl) |t| {
        title = std.mem.span(t);
    }

    var pwin:?*TopLevelFields = null;
    if (self.get_zin(parent)) |pw| {
        pwin = pw;
    }

    const win = self.create(@enumFromInt(klass), title, left, top, height, width, extension, pwin, null, attrib);
    return win.*.win;
}

pub fn init(wnd: df.WINDOW) TopLevelFields {
    return .{
        .Class = CLASS.FORCEINTTYPE,
        .win = wnd,
        .wndproc = null,
    };
}

pub fn create(
    klass: CLASS,               // class of this window
    ttl: ?[:0]const u8,         // title or NULL
    left:c_int, top:c_int,      // upper left coordinates
    height:c_int, width:c_int,  // dimensions
    extension:?*anyopaque,      // pointer to additional data
    parent: ?*TopLevelFields,   // parent of this window
    wndproc: ?*const fn (win:*TopLevelFields, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool,
    attrib: c_int) *TopLevelFields {

    const title = ttl;
    const wnd:df.WINDOW = @ptrCast(@alignCast(df.DFcalloc(1, @sizeOf(df.window))));

    var self:*TopLevelFields = undefined;
    if (root.global_allocator.create(TopLevelFields)) |s| {
       self = s;
    } else |_| {
        // error
    }
    self.* = init(wnd);

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
            const idx:usize = @intCast(@intFromEnum(klass));
            self.wndproc = Klass.defs[idx][2]; // wndproc
        } else {
//            wnd.*.wndproc = wndproc;
            self.wndproc = wndproc;
        }

        // ---- derive attributes of base classes ----
        var base = klass;
        while (base != CLASS.FORCEINTTYPE) {
            const cls = Klass.defs[@intCast(@intFromEnum(base))];
            const attr:c_int = @intCast(cls[3]); // attributes
            // df.AddAttribute(wnd, attr);
            wnd.*.attrib = wnd.*.attrib | attr;
            base = cls[1]; // base
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
                pt = awin;
            } else {
                pt = null; // unreachable
            }
        }

        self.Class = klass;
        wnd.*.extension = extension;
        wnd.*.rc.rt = df.GetLeft(wnd)+wt-1;
        wnd.*.rc.bt = df.GetTop(wnd)+ht-1;
        wnd.*.ht = ht;
        wnd.*.wd = wt;
        if (ttl != null) {
            InsertTitle(self, title);
        }
        self.parent = pt;
        wnd.*.oldcondition = df.ISRESTORED;
        wnd.*.condition = df.ISRESTORED;
        wnd.*.RestoredRC = wnd.*.rc;
        InitWindowColors(self);
        _ = self.sendMessage(df.CREATE_WINDOW, 0, 0);
        if (self.isVisible()) {
            _ = self.sendMessage(df.SHOW_WINDOW, 0, 0);
        }
    }

    return self;
}

// --------- message prototypes -----------
pub fn sendTextMessage(self: *TopLevelFields, msg:df.MESSAGE, p1: []u8, p2: df.PARAM) bool {
    // Be sure to send null-terminated string to c.
    if (root.global_allocator.dupeZ(u8, p1)) |txt| {
        defer root.global_allocator.free(txt);
        return self.sendMessage(msg, @intCast(@intFromPtr(txt.ptr)), p2);
    } else |_| {
        // error
    }
    return false;
}

pub fn sendCommandMessage(self: *TopLevelFields, p1: c, p2: df.PARAM) bool {
    return self.sendMessage(df.COMMAND, @intFromEnum(p1), p2);
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
            if (self.isVisible()) {
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
            if ((self.isVisible()) or (self == q.CaptureMouse)) {
                if (self.wndproc) |wndproc| {
                    rtn = wndproc(self, msg, p1, p2);
                }
            }
        },
        df.KEYBOARD,
        df.SHIFT_CHANGED => {
            // ------- don't send these messages unless the
            //  window is visible or has captured the keyboard --
            if ((self.isVisible()) or (self == q.CaptureKeyboard)) {
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

// -------- add a title to a window ---------
pub fn AddTitle(self: *TopLevelFields, ttl:?[:0]const u8) void {
    InsertTitle(self, ttl);
    _ = self.sendMessage(df.BORDER, 0, 0);
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

pub fn AdjustRectangle(self:*TopLevelFields, rcc:df.RECT) df.RECT {
    var rc = rcc;
    // -------- adjust the rectangle -------
    if (self.TestAttribute(df.HASBORDER)) {
        if (rc.lf == 0) {
            rc.rt -= 1;
        } else if (rc.lf < rc.rt and rc.lf < self.WindowWidth()+1) {
            rc.lf -= 1;
        }
    }
    if (self.TestAttribute(df.HASBORDER | df.HASTITLEBAR)) {
        if (rc.tp == 0) {
            rc.bt -= 1;
        } else if (rc.tp < rc.bt and rc.tp < self.WindowHeight()+1) {
            rc.tp -= 1;
        }
    }
    rc.rt = @intCast(@max(rc.lf, @min(rc.rt, self.WindowWidth())));
    rc.bt = @intCast(@max(rc.tp, @min(rc.bt, self.WindowHeight())));
    return rc;
}

// -------- display a window's title ---------
pub fn DisplayTitle(self:*TopLevelFields, rcc:?*df.RECT) void {
    const wnd = self.win;
    if (self.title) |_| {
        var rc:df.RECT = undefined;
        if (rcc) |cc| {
            rc = cc.*;
        } else {
            rc = df.RelativeWindowRect(wnd, self.WindowRect());
        }
        rc = self.AdjustRectangle(rc);
        if (self.sendMessage(df.TITLE, @intCast(@intFromPtr(rcc)), 0)) {
            const title_color = cfg.config.clr[@intCast(@intFromEnum(k.TITLEBAR))];
            if (self == inFocus) {
                df.foreground = title_color [r.HILITE_COLOR] [r.FG];
                df.background = title_color [r.HILITE_COLOR] [r.BG];
            } else {
                df.foreground = title_color [r.STD_COLOR] [r.FG];
                df.background = title_color [r.STD_COLOR] [r.BG];
            }
            const ttlen = if (self.title) |tt| tt.len else 0;
            const tlen:usize = @intCast(@min(ttlen, self.WindowWidth()-2));
            const tend:usize = @intCast(self.WindowWidth()-3-self.BorderAdj());
            @memset(line[0..@intCast(self.WindowWidth())],  ' ');
            if (wnd.*.condition != df.ISMINIMIZED) {
                const ilen:isize = @intCast(tlen);
                const pos:usize = @intCast(@divFloor(self.WindowWidth()-2-ilen, 2));
                @memcpy(line[pos..pos+tlen], self.title orelse "");
//                strncpy(line + ((WindowWidth(wnd)-2 - tlen) / 2),
//                            GetTitle(wnd), tlen);
            }
            if (self.TestAttribute(df.CONTROLBOX))
                line[@intCast(2-self.BorderAdj())] = df.CONTROLBOXCHAR;
            if (self.TestAttribute(df.MINMAXBOX)) {
                switch (wnd.*.condition) {
                    df.ISRESTORED => {
                        line[tend+1] = df.MAXPOINTER;
                        line[tend]   = df.MINPOINTER;
                    },
                    df.ISMINIMIZED => {
                        line[tend+1] = df.MAXPOINTER;
                    },
                    df.ISMAXIMIZED => {
                        line[tend]   = df.MINPOINTER;
                        line[tend+1] = df.RESTOREPOINTER;
                    },
                    else => {
                    }
                }
            }
            line[tend+3] = 0;
            line[@intCast(rc.rt+1)] = 0;
            if (self != inFocus)
                df.ClipString += 1;
            df.writeline(wnd, &line[@intCast(rc.lf)],
                        @intCast(rc.lf+self.BorderAdj()),
                        0,
                        df.FALSE);
            df.ClipString = 0;
        }
    }
}

// --- display right border shadow character of a window ---
fn shadow_char(wnd:df.WINDOW, y:c_int) void {
    if (TopLevelFields.get_zin(wnd)) |win| {
        const fg = df.foreground;
        const bg = df.background;
        const x:c_int = @intCast(win.WindowWidth());
        const chr = df.GetVideoChar(@intCast(win.GetLeft()+x), @intCast(win.GetTop()+y)) & 255;

        if (win.TestAttribute(df.SHADOW) == false or
            wnd.*.condition == df.ISMINIMIZED or
            wnd.*.condition == df.ISMAXIMIZED or
            cfg.config.mono > 0) {
            // No shadow
            return;
        }
        df.foreground = r.DARKGRAY;
        df.background = r.BLACK;
        df.wputch(wnd, @intCast(chr), @intCast(x), @intCast(y));
        df.foreground = fg;
        df.background = bg;
    }
}

// --- display the bottom border shadow line for a window --
fn shadowline(wnd:df.WINDOW, rcc:df.RECT) void {
    if (TopLevelFields.get_zin(wnd)) |win| {
        var rc = rcc;
        const fg = df.foreground;
        const bg = df.background;

        if (win.TestAttribute(df.SHADOW) == false or
            wnd.*.condition == df.ISMINIMIZED or
            wnd.*.condition == df.ISMAXIMIZED or
            cfg.config.mono > 0) {
            // No shadow
            return;
        }

        const len:usize = @intCast(win.WindowWidth());
        if (root.global_allocator.allocSentinel(u8, len+1, 0)) |buf| {
            defer root.global_allocator.free(buf);
            const y = win.GetBottom()+1;
            const left:usize = @intCast(win.GetLeft());
            for (0..len+1) |idx| {
                buf[idx] = @intCast(df.GetVideoChar(@intCast(left+idx), @intCast(y)) & 255);
            }
            buf[len+1] = 0;

            df.foreground = r.DARKGRAY;
            df.background = r.BLACK;
 
            buf[@intCast(rc.rt+1)] = 0;
            if (rc.lf == 0)
                rc.lf += 1;

            df.ClipString += 1;

            df.wputs(wnd, &buf[@intCast(rc.lf)], rc.lf, @intCast(win.WindowHeight()));

            df.ClipString -= 1;

            df.foreground = fg;
            df.background = bg;
        } else |_| {
        }

//    int i;
//    int y = GetBottom(wnd)+1;
//
//    for (i = 0; i < WindowWidth(wnd)+1; i++)
//        line[i] = videochar(GetLeft(wnd)+i, y);
//    line[i] = '\0';

//        df.foreground = r.DARKGRAY;
//        df.background = r.BLACK;

//    line[RectRight(rc)+1] = '\0';
//    if (RectLeft(rc) == 0)
//        rc.lf++;
//
//        df.ClipString += 1;
//
//    wputs(wnd, line+RectLeft(rc), RectLeft(rc),
//        WindowHeight(wnd));
//
//        df.ClipString -= 1;
//
//        df.foreground = fg;
//        df.background = bg;
    }
}

fn ParamRect(self:*TopLevelFields, rcc:?*df.RECT) df.RECT {
    const wnd = self.win;
    var rc:df.RECT = undefined;
    if (rcc) |cc| {
        rc = cc.*;
    } else {
        rc = df.RelativeWindowRect(wnd, self.WindowRect());
        if (self.TestAttribute(df.SHADOW)) {
            rc.rt += 1;
            rc.bt += 1;
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
    const wnd = self.win;
    if (self.TestAttribute(df.SIZEABLE) and wnd.*.condition == df.ISRESTORED)
        return df.SIZETOKEN;
    return stdse;
}

// probably not well tested because most windows have titles
fn TopLine(self:*TopLevelFields, lin:u8, rcc:df.RECT) void {
    const wnd = self.win;
    var rc = rcc;
    if (self.TestAttribute(df.HASMENUBAR))
        return;
    if (self.TestAttribute(df.HASTITLEBAR) and self.title != null)
        return;

    if (rc.lf == 0) {
        rc.lf += @intCast(self.BorderAdj());
        rc.rt += @intCast(self.BorderAdj());
    }

    if (rc.rt < self.WindowWidth()-1)
        rc.rt += 1;

    if (rc.lf < rc.rt) {
        // ----------- top line -------------
        @memset(line[0..@intCast(self.WindowWidth()-1)], lin);
//        @memset(line,lin,WindowWidth(wnd)-1);
        if (self.TestAttribute(df.CONTROLBOX)) {
            @memcpy(line[1..4], "   ");
            line[2] = df.CONTROLBOXCHAR;
//                        strncpy(line+1, "   ", 3);
//                        *(line+2) = CONTROLBOXCHAR;
        }
        line[@intCast(rc.rt)] = 0;
        df.writeline(wnd, &line[@intCast(rc.lf)], rc.lf, 0, df.FALSE);
    }
}

// ------- display a window's border -----
pub fn RepaintBorder(self:*TopLevelFields, rcc:?*df.RECT) void {
    const wnd = self.win;

    if (self.TestAttribute(df.HASBORDER) == false)
        return;
    const rc = self.ParamRect(rcc);

    // ---------- window title ------------
    if (self.TestAttribute(df.HASTITLEBAR)) {
        if (rc.tp == 0) {
            if (rc.lf < self.WindowWidth()-self.BorderAdj()) {
                self.DisplayTitle(@constCast(&rc));
            }
        }
    }

    df.foreground = colors.FrameForeground(wnd);
    df.background = colors.FrameBackground(wnd);
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

    line[@intCast(self.WindowWidth())] = 0; // maybe @memset ? Title was draw already
    // -------- top frame corners ---------
    if (rc.tp == 0) {
        if (rc.lf == 0)
            df.wputch(wnd, nw, 0, 0);
        if (rc.lf < self.WindowWidth()) {
            if (rc.rt >= self.WindowWidth()-1) {
                df.wputch(wnd, ne, @intCast(self.WindowWidth()-1), 0);
            }
            self.TopLine(lin, clrc);
        }
    }

    // ----------- window body ------------
    for (@intCast(rc.tp)..@intCast(rc.bt+1)) |ydx| {
        var ch:u8 = 0;
        if (ydx == 0 or ydx >= self.WindowHeight()-1)
            continue;
        if (rc.lf == 0)
            df.wputch(wnd, side, 0, @intCast(ydx));
        if (rc.lf < self.WindowWidth() and
            rc.rt >= self.WindowWidth()-1) {
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
//                ch = (    y == 1 ? UPSCROLLBOX      :
//                          y == WindowHeight(wnd)-2  ?
//                                DOWNSCROLLBOX       :
//                          y-1 == wnd->VScrollBox    ?
//                                SCROLLBOXCHAR       :
//                          SCROLLBARCHAR );
            } else {
                ch = side;
            }
            df.wputch(wnd, ch, @intCast(self.WindowWidth()-1), @intCast(ydx));
        }
        if (rc.rt == self.WindowWidth())
            shadow_char(wnd, @intCast(ydx));
    }

    if (rc.tp <= self.WindowHeight()-1 and
            rc.bt >= self.WindowHeight()-1) {
        // -------- bottom frame corners ----------
        if (rc.lf == 0)
            df.wputch(wnd, sw, 0, @intCast(self.WindowHeight()-1));
        if (rc.lf < self.WindowWidth() and
                rc.rt >= self.WindowWidth()-1) {
            df.wputch(wnd, se, @intCast(self.WindowWidth()-1), @intCast(self.WindowHeight()-1));
        }

        if (self.StatusBar == null) {
            // ----------- bottom line -------------
            @memset(line[0..@intCast(self.WindowWidth()-1)], lin);
            if (self.TestAttribute(df.HSCROLLBAR)) {
                line[0] = df.LEFTSCROLLBOX;
                line[@intCast(self.WindowWidth()-3)] = df.RIGHTSCROLLBOX;
                @memset(line[1..@intCast(self.WindowWidth()-4+1)], df.SCROLLBARCHAR);
                line[self.HScrollBox] = df.SCROLLBOXCHAR;
            }
            line[@intCast(rc.rt)] = 0;
            line[@intCast(self.WindowWidth()-2)] = 0;
            if (rc.lf != rc.rt or
                (rc.lf>0 and rc.lf < self.WindowWidth()-1)) {
                if (self != inFocus) {
                    df.ClipString += 1;
                }
                df.writeline(wnd,
                             &line[@intCast(clrc.lf)],
                             clrc.lf+1,
                             @intCast(self.WindowHeight()-1),
                             df.FALSE);
                df.ClipString = 0;
            }
        }
        if (rc.rt == self.WindowWidth())
            shadow_char(wnd, @intCast(self.WindowHeight()-1));
    }

    if (rc.bt == self.WindowHeight()) {
        // ---------- bottom shadow -------------
        shadowline(wnd, rc);
    }
}

// ------ clear the data space of a window -------- 
pub fn ClearWindow(win:*TopLevelFields, rcc:?*df.RECT, clrchar:u8) void {
    const wnd = win.win;
    if (win.isVisible()) {
        var rc:df.RECT = undefined;
        if (rcc) |cc| {
            rc = cc.*;
        } else {
            rc = df.RelativeWindowRect(wnd, win.WindowRect());
        }
        const top = win.TopBorderAdj();
        const bot = win.WindowHeight()-1-win.BottomBorderAdj();

        if (rc.lf == 0)
            rc.lf = @intCast(win.BorderAdj());
        if (rc.rt > win.WindowWidth()-1)
            rc.rt = @intCast(win.WindowWidth()-1);
        colors.SetStandardColor(wnd);

        if (root.global_allocator.allocSentinel(u8, @intCast(rc.rt+1), 0)) |buf| {
            defer root.global_allocator.free(buf);
            @memset(buf, clrchar);
            buf[buf.len] = 0;
            for (@intCast(rc.tp)..@intCast(rc.bt+1)) |ydx| {
                if (ydx < top or ydx > bot)
                    continue;
                df.writeline(wnd, &buf[@intCast(rc.lf)], rc.lf, @intCast(ydx), df.FALSE);
            }
        } else |_| {
        }

//        memset(line, clrchar, sizeof line);
//        line[RectRight(rc)+1] = '\0';
//        for (y = RectTop(rc); y <= RectBottom(rc); y++)    {
//           if (y < top || y > bot)
//               continue;
//           writeline(wnd,
//               line+(RectLeft(rc)),
//               RectLeft(rc),
//               y,
//               FALSE);
//       }
    }
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
            win.win.*.WindowColors[col][fbg] = cfg.config.clr[icls][col][fbg];
        }
    }
}

pub fn PutWindowChar(self: *TopLevelFields, chr:c_int, x:c_int, y:c_int) void {
    const wnd = self.win;
    if (x < self.ClientWidth() and y < self.ClientHeight()) {
        df.wputch(wnd, chr, @intCast(x+self.BorderAdj()), @intCast(y+self.TopBorderAdj()));
    }
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

pub fn getClass(self: *TopLevelFields) CLASS {
    return self.Class;
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
    const wnd = self.win;
    const col:c_uint = @intCast(wnd.*.CurrCol);
    return self.TextPointers[@intCast(wnd.*.CurrLine)]+col;
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

pub export fn GetTitle(wnd:df.WINDOW) [*c]u8 {
    if (get_zin(wnd)) |win| {
        if (win.title) |t| {
            return @constCast(t.ptr);
        }
    }
    return null;
}

pub export fn GetClass(wnd:df.WINDOW) c_int {
    if (get_zin(wnd)) |win| {
        return @intFromEnum(win.Class);
    }
    return @intFromEnum(k.FORCEINTTYPE); // unreachable
}

pub export fn GetParent(wnd:df.WINDOW) df.WINDOW {
    if (get_zin(wnd)) |win| {
        if (win.parent) |pw| {
            return pw.win;
        }
    }
    return null; // unreachable
}

pub export fn inFocusWnd() df.WINDOW {
    if (inFocus) |focus| {
        return focus.win;
    }
    return null;
}

pub export fn getBlkBegLine(wnd:df.WINDOW) c_int {
    if (TopLevelFields.get_zin(wnd)) |win| {
        return @intCast(win.BlkBegLine);
    }
    return 0;
}

pub export fn getBlkEndLine(wnd:df.WINDOW) c_int {
    if (TopLevelFields.get_zin(wnd)) |win| {
        return @intCast(win.BlkEndLine);
    }
    return 0;
}

pub export fn getBlkBegCol(wnd:df.WINDOW) c_int {
    if (TopLevelFields.get_zin(wnd)) |win| {
        return @intCast(win.BlkBegCol);
    }
    return 0;
}

pub export fn getBlkEndCol(wnd:df.WINDOW) c_int {
    if (TopLevelFields.get_zin(wnd)) |win| {
        return @intCast(win.BlkEndCol);
    }
    return 0;
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
