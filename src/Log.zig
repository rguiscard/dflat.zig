const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const menus = @import("Menus.zig");
const checkbox = @import("CheckBox.zig");
const Class = @import("Classes.zig");
const Menu = @import("Menu.zig");
const menubar = @import("MenuBar.zig");
const listbox = @import("ListBox.zig");
const c = @import("Commands.zig").Command;

var log:?*df.FILE = null;

pub export fn LogMessages (win:?*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) void {
    if (log) |L| {
        const m = messages[@intCast(msg)];
        if (m[0] != ' ') {
            var class:[]const u8 = "";
            var title:?[:0]const u8 = null;
            if (win) |w| {
                const idx:usize = @intCast(@intFromEnum(w.Class));
                if (idx < 128) {
                    class = Class.defs[idx][0]; // name
                    title = w.title;
                }
            }
            _ = df.fprintf(L, "%-20.20s %-12.12s %-20.20s, %5.5ld, %5.5ld\n", 
                               if (title) |ttl| ttl.ptr else null, 
                               @constCast(class.ptr), m, p1, p2);
        }
    }
}

pub fn LogProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const control = DialogBox.ControlWindow(&Dialogs.Log, .ID_LOGLIST);
    switch (msg)    {
        df.INITIATE_DIALOG => {
            if (control) |cwin| {
                cwin.AddAttribute(df.MULTILINE | df.VSCROLLBAR);
                for (messages) |m| {
                    const x = std.mem.span(m);
                    _ = cwin.sendTextMessage(df.ADDTEXT, x, 0);
                }
                _ = cwin.sendMessage(df.SHOW_WINDOW, 0, 0);
            }
        },
        df.COMMAND => {
            const cmd:c = @enumFromInt(p1);
            if (cmd == .ID_OK) {
                if (control) |cwin| {
                    const cwnd = cwin.win;
                    const tl = df.GetTextLines(cwnd);
                    for(0..@intCast(tl)) |item| {
                        if (listbox.ItemSelected(cwin, @intCast(item))) {
                            messages[item][0] = df.LISTSELECTOR;
                        }
                    }
                }
            }
        },
        else => {
        }
    }
    return root.zDefaultWndProc(win, msg, p1, p2);
}

pub fn MessageLog(win:*Window) void {
    const Log = &Dialogs.Log;
    if (DialogBox.create(win, Log, df.TRUE, LogProc)) {
        if (checkbox.CheckBoxSetting(Log, .ID_LOGGING)) {
            log = df.fopen("DFLAT.LOG", "wt");
            if (menubar.ActiveMenuBar) |mb| {
                Menu.SetCommandToggle(mb, .ID_LOG);
            }
        } else if (log != null)    {
            _ = df.fclose(log);
            log = null;
            if (menubar.ActiveMenuBar) |mb| {
                Menu.ClearCommandToggle(mb, .ID_LOG);
            }
        }
    }
}

// FIXME: need a prettier way to generate an array of mutable strings
var messages = &[_][*:0]u8{
    // -------------- process communication messages -----------
    @constCast(" START".ptr),                    // start message processing
    @constCast(" STOP".ptr),             // stop message processing
    @constCast(" COMMAND".ptr),          // send a command to a window
    // -------------- window management messages ---------------
    @constCast(" CREATE_WINDOW".ptr),    // create a window
    @constCast(" OPEN_WINDOW".ptr),      // open a window
    @constCast(" SHOW_WINDOW".ptr),      // show a window
    @constCast(" HIDE_WINDOW".ptr),      // hide a window
    @constCast(" CLOSE_WINDOW".ptr),     // delete a window
    @constCast(" SETFOCUS".ptr),         // set and clear the focus
    @constCast(" PAINT".ptr),            // paint the window's data space
    @constCast(" BORDER".ptr),            // paint the window's border
    @constCast(" TITLE".ptr),            // display the window's title
    @constCast(" MOVE".ptr),             // move the window
    @constCast(" SIZE".ptr),             // change the window's size
    @constCast(" MAXIMIZE".ptr),         // maximize the window
    @constCast(" MINIMIZE".ptr),         // minimize the window
    @constCast(" RESTORE".ptr),          // restore the window
    @constCast(" INSIDE_WINDOW".ptr),    // test x/y inside a window
    // ---------------- clock messages -------------------------
    @constCast(" CLOCKTICK".ptr),        // the clock ticked
    @constCast(" CAPTURE_CLOCK".ptr),    // capture clock into a window
    @constCast(" RELEASE_CLOCK".ptr),    // release clock to the system
    // -------------- keyboard and screen messages -------------
    @constCast(" KEYBOARD".ptr),              // key was pressed
    @constCast(" CAPTURE_KEYBOARD".ptr),   // capture keyboard into a window
    @constCast(" RELEASE_KEYBOARD".ptr),   // release keyboard to system
    @constCast(" KEYBOARD_CURSOR".ptr),  // position the keyboard cursor
    @constCast(" CURRENT_KEYBOARD_CURSOR".ptr), //read the cursor position
    @constCast(" HIDE_CURSOR".ptr),      // hide the keyboard cursor
    @constCast(" SHOW_CURSOR".ptr),      // display the keyboard cursor
    @constCast(" SAVE_CURSOR".ptr),      // save the cursor's configuration
    @constCast(" RESTORE_CURSOR".ptr),       // restore the saved cursor
    @constCast(" SHIFT_CHANGED".ptr),    // the shift status changed
    @constCast(" WAITKEYBOARD".ptr),     // waits for a key to be released
    // ---------------- mouse messages -------------------------
    @constCast(" RESET_MOUSE".ptr),      // reset the mouse
    @constCast(" MOUSE_TRAVEL".ptr),     // set the mouse travel
    @constCast(" MOUSE_INSTALLED".ptr),  // test for mouse installed
    @constCast(" RIGHT_BUTTON".ptr),     // right button pressed
    @constCast(" LEFT_BUTTON".ptr),      // left button pressed
    @constCast(" DOUBLE_CLICK".ptr),     // left button double-clicked
    @constCast(" MOUSE_MOVED".ptr),      // mouse changed position
    @constCast(" BUTTON_RELEASED".ptr),  // mouse button released
    @constCast(" CURRENT_MOUSE_CURSOR".ptr), // get mouse position
    @constCast(" MOUSE_CURSOR".ptr),     // set mouse position
    @constCast(" SHOW_MOUSE".ptr),       // make mouse cursor visible
    @constCast(" HIDE_MOUSE".ptr),       // hide mouse cursor
    @constCast(" WAITMOUSE".ptr),        // wait until button released
    @constCast(" TESTMOUSE".ptr),        // test any mouse button pressed
    @constCast(" CAPTURE_MOUSE".ptr),    // capture mouse into a window
    @constCast(" RELEASE_MOUSE".ptr),    // release the mouse to system
    // ---------------- text box messages ----------------------
    @constCast(" ADDTEXT".ptr),               // append text to the text box
    @constCast(" INSERTTEXT".ptr),            // insert line of text
    @constCast(" DELETETEXT".ptr),            // delete line of text
    @constCast(" CLEARTEXT".ptr),             // clear the edit box
    @constCast(" SETTEXT".ptr),               // copy text to text buffer
    @constCast(" SCROLL".ptr),                // vertical line scroll
    @constCast(" HORIZSCROLL".ptr),           // horizontal column scroll
    @constCast(" SCROLLPAGE".ptr),            // vertical page scroll
    @constCast(" HORIZPAGE".ptr),             // horizontal page scroll
    @constCast(" SCROLLDOC".ptr),             // scroll to beginning/end
    // ---------------- edit box messages ----------------------
    @constCast(" GETTEXT".ptr),               // get text from an edit box
    @constCast(" SETTEXTLENGTH".ptr),         // set maximum text length
    // ---------------- menubar messages -----------------------
    @constCast(" BUILDMENU".ptr),             // build the menu display
    @constCast(" MB_SELECTION".ptr),          // menubar selection
    // ---------------- popdown messages -----------------------
    @constCast(" BUILD_SELECTIONS".ptr),   // build the menu display
    @constCast(" CLOSE_POPDOWN".ptr),         // tell parent popdown is closing
    // ---------------- list box messages ----------------------
    @constCast(" LB_SELECTION".ptr),          // sent to parent on selection
    @constCast(" LB_CHOOSE".ptr),             // sent when user chooses
    @constCast(" LB_CURRENTSELECTION".ptr), // return the current selection
    @constCast(" LB_GETTEXT".ptr),            // return the text of selection
    @constCast(" LB_SETSELECTION".ptr),     // sets the listbox selection
    // ---------------- dialog box messages --------------------
    @constCast(" INITIATE_DIALOG".ptr),  // begin a dialog
    @constCast(" ENTERFOCUS".ptr),       // tell DB control got focus
    @constCast(" LEAVEFOCUS".ptr),       // tell DB control lost focus
    @constCast(" ENDDIALOG".ptr),        // end a dialog
    // ---------------- help box messages ----------------------
    @constCast(" DISPLAY_HELP".ptr),
    // --------------- application window messages -------------
    @constCast(" ADDSTATUS".ptr),
    // --------------- picture box messages --------------------
    @constCast(" DRAWVECTOR".ptr),
    @constCast(" DRAWBOX".ptr),
    @constCast(" DRAWBAR".ptr),
};
