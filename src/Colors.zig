const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Classes = @import("Classes.zig");
const CLASSCOUNT:usize = @intFromEnum(Classes.CLASS.CLASSCOUNT);

// ============= Color Type =============
pub const STD_COLOR    = 0;
pub const SELECT_COLOR = 1;
pub const FRAME_COLOR  = 2;
pub const HILITE_COLOR = 3;

// ============= Color Grounds =============
pub const FG    = 0;
pub const BG    = 1;

// ============= Color Macros ============
pub const BLACK        =  0;
pub const BLUE         =  1;
pub const GREEN        =  2;
pub const CYAN         =  3;
pub const RED          =  4;
pub const MAGENTA      =  5;
pub const BROWN        =  6;
pub const LIGHTGRAY    =  7;
pub const DARKGRAY     =  8;
pub const LIGHTBLUE    =  9;
pub const LIGHTGREEN   = 10;
pub const LIGHTCYAN    = 11;
pub const LIGHTRED     = 12;
pub const LIGHTMAGENTA = 13;
pub const YELLOW       = 14;
pub const WHITE        = 15;

// ----- default colors for color video system -----
pub const color = [CLASSCOUNT][4][2]u8{
    // ------------ NORMAL ------------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{LIGHTGRAY, BLACK}},// HILITE_COLOR

    // ---------- APPLICATION ---------
   .{.{LIGHTGRAY, BLUE},  // STD_COLOR
     .{LIGHTGRAY, BLUE},  // SELECT_COLOR
     .{LIGHTGRAY, BLUE},  // FRAME_COLOR
     .{LIGHTGRAY, BLUE}}, // HILITE_COLOR

    // ------------ TEXTBOX -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ------------ LISTBOX -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ----------- EDITBOX ------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{LIGHTGRAY, BLUE},  // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ---------- MENUBAR -------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{BLACK, CYAN},      // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{DARKGRAY, GREEN}}, // HILITE_COLOR
                          // Inactive, Shortcut (both FG)

    // ---------- POPDOWNMENU ---------
   .{.{BLACK, CYAN},      // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{BLACK, CYAN},      // FRAME_COLOR
     .{DARKGRAY, BROWN}}, // HILITE_COLOR
                          // Inactive ,Shortcut (both FG)
    // ------------ PICTUREBOX -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ------------- DIALOG -----------
   .{.{LIGHTGRAY, BLUE},  // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{LIGHTGRAY, BLUE},  // FRAME_COLOR
     .{LIGHTGRAY, BLUE}}, // HILITE_COLOR
    // ------------ BOX ---------------
   .{.{LIGHTGRAY, BLUE},  // STD_COLOR
     .{LIGHTGRAY, BLUE},  // SELECT_COLOR
     .{LIGHTGRAY, BLUE},  // FRAME_COLOR
     .{LIGHTGRAY, BLUE}}, // HILITE_COLOR

    // ------------ BUTTON ------------
   .{.{BLACK, CYAN},      // STD_COLOR
     .{WHITE, CYAN},      // SELECT_COLOR
     .{BLACK, CYAN},      // FRAME_COLOR
     .{DARKGRAY, RED}},   // HILITE_COLOR
                          // Inactive ,Shortcut (both FG)
    // ------------ COMBOBOX -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ------------- TEXT -----------
   .{.{0xff, 0xff},  // STD_COLOR
     .{0xff, 0xff},  // SELECT_COLOR
     .{0xff, 0xff},  // FRAME_COLOR
     .{0xff, 0xff}}, // HILITE_COLOR

    // ------------- RADIOBUTTON -----------
   .{.{LIGHTGRAY, BLUE},  // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{LIGHTGRAY, BLUE},  // FRAME_COLOR
     .{LIGHTGRAY, BLUE}}, // HILITE_COLOR

    // ------------- CHECKBOX -----------
   .{.{LIGHTGRAY, BLUE},  // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{LIGHTGRAY, BLUE},  // FRAME_COLOR
     .{LIGHTGRAY, BLUE}}, // HILITE_COLOR

    // ------------ SPINBUTTON -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ----------- ERRORBOX -----------
   .{.{YELLOW, RED},      // STD_COLOR
     .{YELLOW, RED},      // SELECT_COLOR
     .{YELLOW, RED},      // FRAME_COLOR
     .{YELLOW, RED}},     // HILITE_COLOR

    // ----------- MESSAGEBOX ---------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ----------- HELPBOX ------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLUE},  // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{WHITE, LIGHTGRAY}},// HILITE_COLOR

    // ---------- STATUSBAR -------------
   .{.{BLACK, CYAN},      // STD_COLOR
     .{BLACK, CYAN},      // SELECT_COLOR
     .{BLACK, CYAN},      // FRAME_COLOR
     .{BLACK, CYAN}},     // HILITE_COLOR

    // ----------- EDITOR ------------
   .{.{LIGHTGRAY, BLUE},  // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{LIGHTGRAY, BLUE},  // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ---------- TITLEBAR ------------
   .{.{BLACK, CYAN},      // STD_COLOR
     .{BLACK, CYAN},      // SELECT_COLOR
     .{BLACK, CYAN},      // FRAME_COLOR
     .{WHITE, CYAN}},     // HILITE_COLOR

    // ------------ DUMMY -------------
   .{.{GREEN, LIGHTGRAY}, // STD_COLOR
     .{GREEN, LIGHTGRAY}, // SELECT_COLOR
     .{GREEN, LIGHTGRAY}, // FRAME_COLOR
     .{GREEN, LIGHTGRAY}},// HILITE_COLOR
};

// ----- default colors for mono video system -----
pub const bw = [CLASSCOUNT][4][2]u8{
    // ------------ NORMAL ------------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{LIGHTGRAY, BLACK}},// HILITE_COLOR

    // ---------- APPLICATION ---------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{LIGHTGRAY, BLACK}},// HILITE_COLOR

    // ------------ TEXTBOX -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ------------ LISTBOX -----------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ----------- EDITBOX ------------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ---------- MENUBAR -------------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{DARKGRAY, WHITE}}, // HILITE_COLOR
                          //  Inactive, Shortcut (both FG)

    // ---------- POPDOWNMENU ---------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{DARKGRAY, WHITE}}, // HILITE_COLOR
                          // Inactive ,Shortcut (both FG)

    // ------------ PICTUREBOX -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ------------- DIALOG -----------
   .{.{LIGHTGRAY, BLACK},  // STD_COLOR
     .{BLACK, LIGHTGRAY},  // SELECT_COLOR
     .{LIGHTGRAY, BLACK},  // FRAME_COLOR
     .{LIGHTGRAY, BLACK}}, // HILITE_COLOR

	// ------------ BOX ---------------
   .{.{LIGHTGRAY, BLACK},  // STD_COLOR
     .{LIGHTGRAY, BLACK},  // SELECT_COLOR
     .{LIGHTGRAY, BLACK},  // FRAME_COLOR
     .{LIGHTGRAY, BLACK}}, // HILITE_COLOR

    // ------------ BUTTON ------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{WHITE, LIGHTGRAY}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{DARKGRAY, WHITE}}, // HILITE_COLOR
                          // Inactive ,Shortcut (both FG)
    // ------------ COMBOBOX -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ------------- TEXT -----------
   .{.{0xff, 0xff},  // STD_COLOR
     .{0xff, 0xff},  // SELECT_COLOR
     .{0xff, 0xff},  // FRAME_COLOR
     .{0xff, 0xff}}, // HILITE_COLOR

    // ------------- RADIOBUTTON -----------
   .{.{LIGHTGRAY, BLACK},  // STD_COLOR
     .{BLACK, LIGHTGRAY},  // SELECT_COLOR
     .{LIGHTGRAY, BLACK},  // FRAME_COLOR
     .{LIGHTGRAY, BLACK}}, // HILITE_COLOR

    // ------------- CHECKBOX -----------
   .{.{LIGHTGRAY, BLACK},  // STD_COLOR
     .{BLACK, LIGHTGRAY},  // SELECT_COLOR
     .{LIGHTGRAY, BLACK},  // FRAME_COLOR
     .{LIGHTGRAY, BLACK}}, // HILITE_COLOR

    // ------------ SPINBUTTON -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ----------- ERRORBOX -----------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{LIGHTGRAY, BLACK}},// HILITE_COLOR

    // ----------- MESSAGEBOX ---------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{LIGHTGRAY, BLACK}},// HILITE_COLOR

    // ----------- HELPBOX ------------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{WHITE, BLACK},     // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{WHITE, LIGHTGRAY}},// HILITE_COLOR

    // ---------- STATUSBAR -------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ----------- EDITOR ------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{LIGHTGRAY, BLACK}},// HILITE_COLOR

    // ---------- TITLEBAR ------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ------------ DUMMY -------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}}, // HILITE_COLOR
};

// ----- default colors for reverse mono video -----
pub const reverse = [CLASSCOUNT][4][2]u8{
    // ------------ NORMAL ------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ---------- APPLICATION ---------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ------------ TEXTBOX -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ------------ LISTBOX -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ----------- EDITBOX ------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ---------- MENUBAR -------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{DARKGRAY, WHITE}}, // HILITE_COLOR
                          // Inactive, Shortcut (both FG)

    // ---------- POPDOWNMENU ---------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{DARKGRAY, WHITE}}, // HILITE_COLOR
                          // Inactive ,Shortcut (both FG)

    // ------------ PICTUREBOX -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ------------- DIALOG ----------- */
   .{.{BLACK, LIGHTGRAY},  // STD_COLOR
     .{LIGHTGRAY, BLACK},  // SELECT_COLOR
     .{BLACK, LIGHTGRAY},  // FRAME_COLOR
     .{BLACK, LIGHTGRAY}}, // HILITE_COLOR

	// ------------ BOX ---------------
   .{.{BLACK, LIGHTGRAY},  // STD_COLOR
     .{BLACK, LIGHTGRAY},  // SELECT_COLOR
     .{BLACK, LIGHTGRAY},  // FRAME_COLOR
     .{BLACK, LIGHTGRAY}}, // HILITE_COLOR

    // ------------ BUTTON ------------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{WHITE, BLACK},     // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{DARKGRAY, WHITE}}, // HILITE_COLOR
                          // Inactive ,Shortcut (both FG)
    // ------------ COMBOBOX -----------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ------------- TEXT -----------
   .{.{0xff, 0xff},  // STD_COLOR
     .{0xff, 0xff},  // SELECT_COLOR
     .{0xff, 0xff},  // FRAME_COLOR
     .{0xff, 0xff}}, // HILITE_COLOR

    // ------------- RADIOBUTTON -----------
   .{.{BLACK, LIGHTGRAY},  // STD_COLOR
     .{LIGHTGRAY, BLACK},  // SELECT_COLOR
     .{BLACK, LIGHTGRAY},  // FRAME_COLOR
     .{BLACK, LIGHTGRAY}}, // HILITE_COLOR

    // ------------- CHECKBOX -----------
   .{.{BLACK, LIGHTGRAY},  // STD_COLOR
     .{LIGHTGRAY, BLACK},  // SELECT_COLOR
     .{BLACK, LIGHTGRAY},  // FRAME_COLOR
     .{BLACK, LIGHTGRAY}}, // HILITE_COLOR

    // ------------ SPINBUTTON -----------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ----------- ERRORBOX -----------
   .{.{BLACK, LIGHTGRAY},      // STD_COLOR
     .{BLACK, LIGHTGRAY},      // SELECT_COLOR
     .{BLACK, LIGHTGRAY},      // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},     // HILITE_COLOR

    // ----------- MESSAGEBOX ---------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ----------- HELPBOX ------------
   .{.{BLACK, LIGHTGRAY}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{BLACK, LIGHTGRAY}, // FRAME_COLOR
     .{WHITE, LIGHTGRAY}},// HILITE_COLOR

    // ---------- STATUSBAR -------------
   .{.{LIGHTGRAY, BLACK},      // STD_COLOR
     .{LIGHTGRAY, BLACK},      // SELECT_COLOR
     .{LIGHTGRAY, BLACK},      // FRAME_COLOR
     .{LIGHTGRAY, BLACK}},     // HILITE_COLOR

    // ----------- EDITOR ------------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{BLACK, LIGHTGRAY}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{BLACK, LIGHTGRAY}},// HILITE_COLOR

    // ---------- TITLEBAR ------------
   .{.{LIGHTGRAY, BLACK},      // STD_COLOR
     .{LIGHTGRAY, BLACK},      // SELECT_COLOR
     .{LIGHTGRAY, BLACK},      // FRAME_COLOR
     .{LIGHTGRAY, BLACK}},     // HILITE_COLOR

    // ------------ DUMMY -------------
   .{.{LIGHTGRAY, BLACK}, // STD_COLOR
     .{LIGHTGRAY, BLACK}, // SELECT_COLOR
     .{LIGHTGRAY, BLACK}, // FRAME_COLOR
     .{LIGHTGRAY, BLACK}}, // HILITE_COLOR
};

// Accessories
pub export fn WndForeground(wnd:df.WINDOW) u8 {
    return wnd.*.WindowColors [STD_COLOR] [FG];
}

pub export fn WndBackground(wnd:df.WINDOW) u8 {
    return wnd.*.WindowColors [STD_COLOR] [BG];
}

pub export fn FrameForeground(wnd:df.WINDOW) u8 {
    return wnd.*.WindowColors [FRAME_COLOR] [FG];
}

pub export fn FrameBackground(wnd:df.WINDOW) u8 {
    return wnd.*.WindowColors [FRAME_COLOR] [BG];
}

pub export fn SelectForeground(wnd:df.WINDOW) u8 {
    return wnd.*.WindowColors [SELECT_COLOR] [FG];
}

pub export fn SelectBackground(wnd:df.WINDOW) u8 {
    return wnd.*.WindowColors [SELECT_COLOR] [BG];
}

pub export fn HighlightForeground(wnd:df.WINDOW) u8 {
    return wnd.*.WindowColors [HILITE_COLOR] [FG];
}

pub export fn HighlightBackground(wnd:df.WINDOW) u8 {
    return wnd.*.WindowColors [HILITE_COLOR] [BG];
}

pub export fn WindowClientColor(wnd:df.WINDOW, fg:u8, bg:u8) void {
    wnd.*.WindowColors [STD_COLOR] [FG] = fg;
    wnd.*.WindowColors [STD_COLOR] [BG] = bg;
}

pub export fn WindowReverseColor(wnd:df.WINDOW, fg:u8, bg:u8) void {
    wnd.*.WindowColors [SELECT_COLOR] [FG] = fg;
    wnd.*.WindowColors [SELECT_COLOR] [BG] = bg;
}

pub export fn WindowFrameColor(wnd:df.WINDOW, fg:u8, bg:u8) void {
    wnd.*.WindowColors [FRAME_COLOR] [FG] = fg;
    wnd.*.WindowColors [FRAME_COLOR] [BG] = bg;
}

pub export fn WindowHighlightColor(wnd:df.WINDOW, fg:u8, bg:u8) void {
    wnd.*.WindowColors [HILITE_COLOR] [FG] = fg;
    wnd.*.WindowColors [HILITE_COLOR] [BG] = bg;
}

// --------- set window colors ---------
pub export fn SetStandardColor(wnd:df.WINDOW) void {
    df.foreground = WndForeground(wnd);
    df.background = WndBackground(wnd);
}

pub export fn SetReverseColor(wnd:df.WINDOW) void {
    df.foreground = SelectForeground(wnd);
    df.background = SelectBackground(wnd);
}
