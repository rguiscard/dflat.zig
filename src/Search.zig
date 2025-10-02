const std = @import("std");
const df = @import("ImportC.zig").df;
const c = @import("Commands.zig").Command;
const root = @import("root.zig");
const MessageBox = @import("MessageBox.zig");
const Window = @import("Window.zig");
const DialogBox = @import("DialogBox.zig");
const Dialogs = @import("Dialogs.zig");
const textbox = @import("TextBox.zig");
const editbox = @import("EditBox.zig");
const checkbox = @import("CheckBox.zig");

var CheckCase = true;
var Replacing = false;
var lastsize:usize = 0;

// - case-insensitive, white-space-normalized char compare -
fn SearchCmp(a:u8, b:u8) bool {
    _ = a;
    _ = b;
//    if (b == '\n')
//        b = ' ';
//    if (CheckCase)
//        return a != b;
//    return tolower(a) != tolower(b);
    return true;
}

// ----- replace a matching block of text -----
fn replacetext(wnd:df.WINDOW, cp1:[]const u8, db:*df.DBOX) void {
    _ = wnd;
    _ = cp1;
    _ = db;
//    char *cr = GetEditBoxText(db, ID_REPLACEWITH);
//    char *cp = GetEditBoxText(db, ID_SEARCHFOR);
//    int oldlen = strlen(cp); /* length of text being replaced */
//    int newlen = strlen(cr); /* length of replacing text      */
//    int dif;
//        lastsize = newlen;
//    if (oldlen < newlen)    {
//        /* ---- new text expands text size ---- */
//        dif = newlen-oldlen;
//        if (wnd->textlen < strlen(wnd->text)+dif)    {
//            /* ---- need to reallocate the text buffer ---- */
//            int offset = (int)(cp1-(char *)wnd->text);
//            wnd->textlen += dif;
//            wnd->text = DFrealloc(wnd->text, wnd->textlen+2);
//            cp1 = wnd->text + offset;
//        }
//        memmove(cp1+dif, cp1, strlen(cp1)+1);
//    }
//    else if (oldlen > newlen)    {
//        /* ---- new text collapses text size ---- */
//        dif = oldlen-newlen;
//        memmove(cp1, cp1+dif, strlen(cp1)+1);
//    }
//    strncpy(cp1, cr, newlen);
}

// ------- search for the occurrance of a string ------- 
fn SearchTextBox(win:*Window, incr:bool) void {
    const wnd = win.win;

    var cp1:[*c]u8 = null;
    var pp1:usize = 0; // based on zp1
    const dbox = if (Replacing) &Dialogs.ReplaceTextDB else  &Dialogs.SearchTextDB;
    const searchtext = DialogBox.GetEditBoxText(dbox, c.ID_SEARCHFOR);
    var FoundOne = false;
    var rpl = true;
    if (searchtext) |cp| {
        while ((rpl == true) and (cp.len > 0)) {
            if (Replacing) {
                rpl = checkbox.CheckBoxSetting(&Dialogs.ReplaceTextDB, c.ID_REPLACEALL);
            }

            if (textbox.TextBlockMarked(win)) {
                textbox.ClearTextBlock(win);
                _ = win.sendMessage(df.PAINT, 0, 0);
            }
            // search for a match starting at cursor position
            cp1 = df.zCurrChar(wnd);
            pp1 = win.currPos();
            if (incr) {
                cp1 = cp1 + lastsize; // start past the last hit
                pp1 = pp1 + lastsize;
            }
            // --- compare at each character position ---
            const zp = cp;
            const zp1 = std.mem.span(cp1);
            var index:?usize = null;
            // FIXME: original code is whitespace normalized ('\n' -> ' ')
            if (CheckCase) {
                index = std.mem.indexOf(u8, zp1, zp);
            } else {
                index = std.ascii.indexOfIgnoreCase(zp1, zp);
            }
            if (index) |i| {
                // ----- match at *cp1 -------
                FoundOne = true;

                // mark a block at beginning of matching text
//                cp1 = cp1+i;
//                const s2 = cp1+zp.len;
//                wnd.*.BlkEndLine = df.TextLineNumber(wnd, s2);
//                wnd.*.BlkBegLine = df.TextLineNumber(wnd, cp1);
//                if (wnd.*.BlkEndLine < wnd.*.BlkBegLine) {
//                    wnd.*.BlkEndLine = wnd.*.BlkBegLine;
//                }
//                wnd.*.BlkEndCol = BlkEndColFromLine(wnd, s2);
//                wnd.*.BlkBegCol = BlkBegColFromLine(wnd, cp1);
                pp1 = pp1+i; // based on zp1
                const pp2 = pp1+zp.len;
                cp1 = cp1+i;
//                const s2 = cp1+zp.len;
//                wnd.*.BlkEndLine = df.TextLineNumber(wnd, s2);
//                wnd.*.BlkBegLine = df.TextLineNumber(wnd, cp1);
                win.BlkEndLine = textbox.TextLineNumber(win, pp2);
                win.BlkBegLine = textbox.TextLineNumber(win, pp1);
                if (win.BlkEndLine < win.BlkBegLine) {
                    win.BlkEndLine = win.BlkBegLine;
                }
//                wnd.*.BlkEndCol = BlkEndColFromLine(wnd, s2);
                win.BlkEndCol = pp2-win.textLine(win.BlkEndLine);
//                wnd.*.BlkBegCol = BlkBegColFromLine(wnd, cp1);
                win.BlkBegCol = pp1-win.textLine(win.BlkBegLine);

                // position the cursor at the matching text
                wnd.*.CurrCol = @intCast(win.BlkBegCol);
                wnd.*.CurrLine = @intCast(win.BlkBegLine);
                wnd.*.WndRow = wnd.*.CurrLine - wnd.*.wtop;

                // -- remember the size of the matching text --
                lastsize = cp.len;

                // align the window scroll to matching text
                if (editbox.WndCol(win) > (win.ClientWidth()-1)) {
                    wnd.*.wleft = wnd.*.CurrCol;
                }
                if (wnd.*.WndRow > (win.ClientHeight()-1)) {
                    wnd.*.wtop = wnd.*.CurrLine;
                    wnd.*.WndRow = 0;
                }

                _ = win.sendMessage(df.PAINT, 0, 0);
                _ = win.sendMessage(df.KEYBOARD_CURSOR, editbox.WndCol(win), wnd.*.WndRow);

//                if (Replacing)    {
//                    if (rpl || YesNoBox("Replace the text?"))  {
//                        replacetext(wnd, cp1, db);
//                        wnd->TextChanged = TRUE;
//                        BuildTextPointers(wnd);
//                            if (rpl)    {
//                            incr = TRUE;
//                            continue;
//                            }
//                    }
//                    win.ClearTextBlock();
//                    _ = win.sendMessage(msg.PAINT, 0, 0);
//                }
                return;
            }
            break;
        }
    }
    if (FoundOne == false) {
        const t = "Search/Replace Text";
        const m = "No match found";
        _ = MessageBox.MessageBox(t, m);
    }
}

// ------- search for the occurrance of a string,
//         replace it with a specified string -------
pub fn ReplaceText(win:*Window) void {
    Replacing = true;
    lastsize = 0;
    if (CheckCase) {
        DialogBox.SetCheckBox(&Dialogs.ReplaceTextDB, c.ID_MATCHCASE);
    }
    if (DialogBox.create(null, &Dialogs.ReplaceTextDB, df.TRUE, null)) {
        CheckCase = checkbox.CheckBoxSetting(&Dialogs.ReplaceTextDB, c.ID_MATCHCASE);
        SearchTextBox(win, false);
    }
}

// ------- search for the first occurrance of a string ------
pub fn SearchText(win:*Window) void {
    Replacing = false;
    lastsize = 0;
    if (CheckCase) {
        DialogBox.SetCheckBox(&Dialogs.SearchTextDB, c.ID_MATCHCASE);
    }
    if (DialogBox.create(null, &Dialogs.SearchTextDB, df.TRUE, null)) {
        CheckCase = checkbox.CheckBoxSetting(&Dialogs.SearchTextDB, c.ID_MATCHCASE);
        SearchTextBox(win, false);
    }
}

// ------- search for the next occurrance of a string -------
pub fn SearchNext(win:*Window) void {
    SearchTextBox(win, true);
}
