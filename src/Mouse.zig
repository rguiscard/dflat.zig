const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");

// ---------- reset the mouse ----------
pub fn resetmouse() void {
}

// ----- test to see if the mouse driver is installed -----
pub fn mouse_installed() bool {
    return true;
}

// ------ return true if mouse buttons are pressed -------
pub fn mousebuttons() c_int {
    return df.mouse_button;
}

// ---------- return mouse coordinates ----------
pub fn get_mouseposition(x:*c_int, y:*c_int) void {
    x.* = df.mouse_x;
    y.* = df.mouse_y;
}

// -------- position the mouse cursor --------
pub fn set_mouseposition(x:c_int, y:c_int) void {
    _ = x;
    _ = y;
    //char buf[32];
    //mouse_x = x;
    //mouse_y = y;
    //sprintf(buf, "\e[%d;%dH", y+1, x+1);
    //write(1, buf, strlen(buf));
}

// --------- display the mouse cursor --------
pub fn show_mousecursor() void {
    //const char *p = "\e[?25h";
    //write(1, p, strlen(p));
}

// --------- hide the mouse cursor -------
pub fn hide_mousecursor() void {
    //const char *p = "\e[?25l";
    //write(1, p, strlen(p));
}

// --- return true if a mouse button has been released ---
pub fn button_releases() c_int {
    return (df.mouse_button == df.kMouseLeftUp or df.mouse_button == df.kMouseRightUp);
}

// ----- set mouse travel limits -------
pub fn set_mousetravel(minx:c_int, maxx:c_int, miny:c_int, maxy:c_int) void {
    _ = minx;
    _ = maxx;
    _ = miny;
    _ = maxy;
}
