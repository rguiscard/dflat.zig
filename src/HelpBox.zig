const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const WndProc = @import("WndProc.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;
const k = @import("Classes.zig").CLASS;
const lists = @import("Lists.zig");
const normal = @import("Normal.zig");

const MAXHELPKEYWORDS = 50; // --- maximum keywords in a window ---
const MAXHELPSTACK = 100;

var HelpStack = [_]usize{0}**MAXHELPSTACK;
var stacked:usize = 0;

// --- keywords in the current help text --------
const keywords  = struct {
    hkey:*df.helps = undefined,
    lineno:usize = 0,
    off1:usize = 0,
    off2:usize = 0,
    off3:usize = 0,
    isDefinition:bool = false,
};

var thisword:?*keywords = null;
var thisword_idx:?usize = null;
var KeyWords = [_]keywords{.{}}**MAXHELPKEYWORDS;
var keywordcount:usize = 0;

var ThisHelp:?*df.helps = null;

// ------------- CREATE_WINDOW message ------------
fn CreateWindowMsg(win:*Window) void {
    const wnd = win.win;
    df.Helping = df.TRUE;
    win.Class = k.HELPBOX;
    win.InitWindowColors();
    if (ThisHelp) |help| {
        help.*.hwnd = wnd;
    }
}

// -------- read the help text into the editbox -------
pub fn ReadHelp(win:*Window) void {
    if (win.extension) |extension| {
        const dbox:*Dialogs.DBOX = extension.dbox;
        if (DialogBox.ControlWindow(dbox, c.ID_HELPTEXT)) |cwin| {
            cwin.wndproc = HelpTextProc;
            _ = cwin.sendMessage(df.CLEARTEXT, q.none);
            //df.cReadHelp(wnd, cwin.win);
            // ----- read the help text -------
            var hline = [_]u8{0}**100;
            var linectr:usize = 0;
            keywordcount = 0; // reset keywords
            while (true) { // per line
                var colorct:usize = 0;
                if (df.GetHelpLine(&hline) == null)
                    break;
                if (hline[0] == '<')
                    break;
                // remove last \n
                if (std.mem.indexOfScalar(u8, &hline, 0)) |end| {
                    hline[end-1] = 0;
                }
                var pos:usize = 0;
                while (true) { // per character
                    if (std.mem.indexOfScalarPos(u8, &hline, pos, '[')) |idx| {
                        // ----- hit a new key word -----
                        if (hline[idx+1] != '.' and hline[idx+1] != '*') {
                            pos = idx+1;
                            continue;
                        }
                        KeyWords[keywordcount].lineno = cwin.wlines;
                        KeyWords[keywordcount].off1 = idx;
                        KeyWords[keywordcount].off2 = idx - colorct*4;
                        KeyWords[keywordcount].isDefinition = (hline[idx+1] == '*');
                        colorct += 1;
                        pos = idx;
                        hline[pos] = df.CHANGECOLOR;
                        pos += 1;
                        hline[pos] = win.WindowColors[df.HILITE_COLOR][df.FG];
                        pos += 1;
                        hline[pos] = win.WindowColors[df.HILITE_COLOR][df.BG];
                        pos += 1;
                        const begin = pos;
                        if (std.mem.indexOfScalarPos(u8, &hline, pos, ']')) |end| {
                            // thisword cannot be null at this point ?
                            //if (thisword != NULL)
                            KeyWords[keywordcount].off3 = KeyWords[keywordcount].off2 + (end-begin);
                            hline[end] = df.RESETCOLOR;
                            pos = end+1;
                            
                        }
                        if (std.mem.indexOfScalarPos(u8, &hline, pos, '<')) |nbeg| {
                            if (std.mem.indexOfScalarPos(u8, &hline, nbeg, '>')) |nend| {
                                var hname:[80]u8 = @splat(0);
                                @memset(hname[0..hname.len], 0); // why this is needed ?
                                @memcpy(hname[0..(nend-nbeg-1)], hline[nbeg+1..nend]);
                                const n:[*c]u8 = @ptrCast(&hname);
                                const help:*df.helps = df.FindHelp(n);
                                KeyWords[keywordcount].hkey = help;
                                @memmove(hline[nbeg..hline.len-(nend+1-nbeg)], hline[nend+1..hline.len]);
                            }
                        }
                        keywordcount += 1;
			if (keywordcount >= MAXHELPKEYWORDS)
			    break;

                    } else {
                        break;
                    }
                }
                DialogBox.PutItemText(win, .ID_HELPTEXT, &hline);
                // -- display help text as soon as window is full --
                linectr += 1;
                if (linectr == cwin.ClientHeight())  {
                    const holdthis = thisword;
                    thisword = null;
                    _ = cwin.sendMessage(df.PAINT, .{.paint=.{null, false}});
                    thisword = holdthis;
                }
                if (linectr > cwin.ClientHeight() and
                    cwin.TestAttribute(df.VSCROLLBAR) == false) {
                    cwin.AddAttribute(df.VSCROLLBAR);
                    _ = cwin.sendMessage(df.BORDER, .{.paint=.{null, false}});
                }
            } // per line
        }
    }
    thisword = null;
    thisword_idx = null;
}

// ------------- COMMAND message ------------
fn CommandMsg(win: *Window, p1:c) bool {
    const cmd:c = p1;
    switch (cmd) {
        c.ID_PREV => {
            if (ThisHelp) |help| {
                const prevhlp:usize = @intCast(help.*.prevhlp);
                SelectHelp(win, df.FirstHelp+prevhlp, true);
            }
            return true;
        },
        c.ID_NEXT => {
            if (ThisHelp) |help| {
                const nexthlp:usize = @intCast(help.*.nexthlp);
                SelectHelp(win, df.FirstHelp+nexthlp, true);
            }
            return true;
        },
        c.ID_BACK => {
            if (stacked > 0) {
                stacked -= 1;
                const stked:usize = stacked;
                const helpstack:usize = HelpStack[stked];
                SelectHelp(win, df.FirstHelp+helpstack, false);
            }
            return true;
        },
        else => {
        }
    }
    return false;
}

fn KeyboardMsg(win: *Window, p1: u16) bool {
    if (win.extension) |extension| {
        const dbox:*Dialogs.DBOX = extension.dbox;
        if (DialogBox.ControlWindow(dbox, c.ID_HELPTEXT)) |cwin| {
            if (Window.inFocus == cwin) {
                switch(p1) {
                    '\r' => {
                        if (keywordcount > 0) {
                            if (thisword) |word| {
                                const hp = word.hkey.*.hname;
                                if (word.isDefinition) {
                                    DisplayDefinition(win.getParent().win, hp);
                                } else {
                                    SelectHelp(win, word.hkey, true);
                                }
                            }
                        }
                        return true;
                    },
                    '\t'=> {
                        if (keywordcount == 0)
                                return true;
                        if (thisword_idx) |idx| {
                            thisword_idx = idx+1;
                            if (thisword_idx.? >= keywordcount) {
                                thisword_idx = 0; // loop back
                            }
                        } else {
                            thisword_idx = 0;
                        }
                        if (thisword_idx) |idx|{
                            thisword = &KeyWords[idx];
                        }
//                        if (thisword == null or
//                                        ++thisword == KeyWords+keywordcount)
//                            thisword = &KeyWords[0];
                    },
                    df.SHIFT_HT => {
//                        if (!keywordcount)
//                                return TRUE;
//                        if (thisword == NULL || thisword == KeyWords)
//                                thisword = KeyWords+keywordcount;
//                        --thisword;
                    },
                    else => {
                        return false;
                    }
                }
                if (thisword) |word| {
                    if (word.lineno < cwin.wtop or
                        word.lineno >= cwin.wtop + cwin.ClientHeight())  {
// FIXME: this loop looks weird.
//                        var distance = @divFloor(cwin.ClientHeight(), 2);
//                        do {
//                            cwin.win.*.wtop = word.lineno-distance;
//                            distance = @divFloor(distance, 2);
//                        } while (cwnd->wtop < 0);
                    }
                }
                _ = cwin.sendMessage(df.PAINT, .{.paint=.{null, false}});
                return true;
//                return if (df.cHelpBoxKeyboardMsg(wnd, cwin.win, p1) == df.TRUE) true else false;
            }
        }
    }
    return false;
}

pub fn HelpBoxProc(win: *Window, msg: df.MESSAGE, params:q.Params) bool {
    switch (msg) {
        df.CREATE_WINDOW => {
            CreateWindowMsg(win);
        },
        df.INITIATE_DIALOG => {
            ReadHelp(win);
        },
        df.COMMAND => {
            const p1:c = params.command[0];
            const p2:usize = params.command[1];
            if (p2 == 0) {
                if (CommandMsg(win, p1))
                    return true;
            }
        },
        df.KEYBOARD => {
            const p1 = params.char[0];
            if (normal.WindowMoving == false) {
                if (KeyboardMsg(win, p1))
                    return true;
            }
        },
        df.CLOSE_WINDOW => {
            if (ThisHelp) |help| {
                help.*.hwnd = null;
            }
            df.Helping = df.FALSE;
        },
        else => {
        }
    }
    return root.BaseWndProc(k.HELPBOX, win, msg, params);
}

// ---- PAINT message for the helpbox text editbox ----
fn PaintMsg(win:*Window, params:q.Params) bool {
    const wnd = win.win;
    if (thisword) |word| {
        const pwin = win.getParent();
        var pos:usize = win.TextPointers[word.*.lineno];
        pos += @intCast(word.*.off1);
        wnd.*.text[pos+1] = pwin.WindowColors[df.SELECT_COLOR][df.FG];
        wnd.*.text[pos+2] = pwin.WindowColors[df.SELECT_COLOR][df.BG];
        const rtn = root.DefaultWndProc(win, df.PAINT, params);
        wnd.*.text[pos+1] = pwin.WindowColors[df.HILITE_COLOR][df.FG];
        wnd.*.text[pos+2] = pwin.WindowColors[df.HILITE_COLOR][df.BG];
        return rtn;
    }
    return root.DefaultWndProc(win, df.PAINT, params);
}

// ---- LEFT_BUTTON message for the helpbox text editbox ----
fn LeftButtonMsg(win:*Window, x:usize, y:usize) bool {
    const rtn = root.DefaultWndProc(win, df.LEFT_BUTTON, .{.position=.{x, y}});
    const mx:usize = if (x > win.GetClientLeft()) x - win.GetClientLeft() else 0;
    const my:usize = if (y+win.wtop > win.GetClientTop()) y - win.GetClientTop() + win.wtop else 0;

    for (&KeyWords, 0..) |*word, idx| {
        if (my == word.lineno) {
            if (mx >= word.off2 and mx < word.off3) {
                thisword = word;
                thisword_idx = idx;
                _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
                if (word.isDefinition) {
                    if (win.parent) |pw| {
                        DisplayDefinition(pw.win, word.hkey.*.hname); 
                    }
                }
                break;
            }
        }
        thisword = null;
        thisword_idx = null;
    }

//    thisword = KeyWords;
//    for (i = 0; i < keywordcount; i++)    {
//        if (my == thisword->lineno)    {
//            if (mx >= thisword->off2 &&
//                        mx < thisword->off3)    {
//                SendMessage(wnd, PAINT, 0, 0);
//                if (thisword->isDefinition)    {
//                    WINDOW pwnd = GetParent(wnd);
//                    if (pwnd != NULL)
//                        DisplayDefinition(GetParent(pwnd),
//                            thisword->hkey->hname);
//                }
//                break;
//            }
//        }
//        thisword++;
//    }
//        if (i == keywordcount)
//                thisword = NULL;
    return rtn;
}

// --- window processing module for HELPBOX's text EDITBOX --
pub fn HelpTextProc(win: *Window, msg: df.MESSAGE, params:q.Params) bool {
    switch (msg) {
        df.KEYBOARD => {
        },
        df.PAINT => {
            return PaintMsg(win, params);
        },
        df.LEFT_BUTTON => {
            const p1 = params.position[0];
            const p2 = params.position[1];
            return LeftButtonMsg(win, p1, p2);
        },
        df.DOUBLE_CLICK => {
            q.PostMessage(win, df.KEYBOARD, .{.char=.{'\r', 0}});
        },
        else => {
        }
    }
    return root.DefaultWndProc(win, msg, params);
}

// ---- strip tildes from the help name ----
fn StripTildes(input: []const u8, buffer: *[30]u8) []const u8 {
    const tilde = '~';
    var i: usize = 0;

    for (input) |cc| {
        if (cc != tilde) {
            buffer[i] = cc;
            i += 1;
        }
    }
    return buffer[0..i];
}

// --- return the comment associated with a help window ---
// not in use, should be private
fn HelpComment(Help:[]const u8) [*c]u8 {
    var buffer:[30]u8 = undefined;
    @memset(&buffer, 0);

    const FixedHelp = StripTildes(Help, &buffer);
    ThisHelp = df.FindHelp(@constCast(FixedHelp.ptr));
    if (ThisHelp) |help| {
        return help.*.comment;
    }
    return null;
}

// ---------- display help text -----------
pub fn DisplayHelp(win:*Window, Help:[]const u8) bool {
    var buffer:[30]u8 = undefined;
    var rtn = false;

    @memset(&buffer, 0);

    if (df.Helping > 0)
        return true;

    const FixedHelp = StripTildes(Help, &buffer);

    win.isHelping += 1;
    ThisHelp = df.FindHelp(@constCast(FixedHelp.ptr));
    if (ThisHelp) |thisHelp| {
        _ = thisHelp;
        df.helpfp = df.OpenHelpFile(&df.HelpFileName, "rb");
        if (df.helpfp) |_| {
            BuildHelpBox(win);
            DialogBox.DisableButton(&Dialogs.HelpBox, c.ID_BACK);

            // ------- display the help window -----
            _ = DialogBox.create(null, &Dialogs.HelpBox, df.TRUE, HelpBoxProc);

            if (Dialogs.HelpBox.dwnd.title) |ttl| {
                root.global_allocator.free(ttl);
                Dialogs.HelpBox.dwnd.title = null;
            }
            _ = df.fclose(df.helpfp);
            df.helpfp = null;
            rtn = true;
        }
    }
    win.isHelping -= 1;
    return rtn;
}

// ------- display a definition window --------- 
// This one does not work properly from origin
pub export fn DisplayDefinition(wnd:df.WINDOW, def:[*c]u8) void { // should be private
    const MAXHEIGHT = df.SCREENHEIGHT-10;
    const HoldThisHelp = ThisHelp;

    if (Window.get_zin(wnd)) |win| {
        var hwin:?*Window = win;
        if (win.Class == k.POPDOWNMENU) {
            hwin = win.parent;
        }
        var y:usize = 1;
        if (hwin) |hw| {
            if (hw.Class == k.MENUBAR) {
                y = 2;
            }
            ThisHelp = df.FindHelp(def);
            if (ThisHelp) |help| {
                const dwin = Window.create(
                            k.TEXTBOX,
                            null,
                            @intCast(hw.GetClientLeft()),
                            @intCast(hw.GetClientTop()+y),
                            @intCast(@min(help.*.hheight, MAXHEIGHT)+3),
                            @intCast(help.*.hwidth+2),
                            null,
                            win,
                            null,
                            df.HASBORDER | df.NOCLIP | df.SAVESELF,
                            .{});
//                    df.clearBIOSbuffer(); // no function
                // ----- read the help text -------
                df.SeekHelpLine(help.*.hptr, help.*.bit);
                while (true) {
                    //  df.clearBIOSbuffer(); // no function
                    var hline = [_]u8{0}**100;
                    if (df.GetHelpLine(&hline) == null)
                        break;
                    if (hline[0] == '<')
                        break;
                    if (std.mem.indexOfScalar(u8, &hline, 0)) |end| {
                        hline[end-1] = 0;
                    }
                    _ = dwin.sendTextMessage(df.ADDTEXT, &hline);
                }
                _ = dwin.sendMessage(df.SHOW_WINDOW, q.none);
                _ = q.SendMessage(null, df.WAITKEYBOARD, q.none);
                _ = q.SendMessage(null, df.WAITMOUSE, q.none);
                _ = dwin.sendMessage(df.CLOSE_WINDOW, .{.yes=false});
            }
        }
    }
    ThisHelp = HoldThisHelp;
}

fn BuildHelpBox(win:?*Window) void {
    const MAXHEIGHT = df.SCREENHEIGHT-10;

    if (ThisHelp) |help| {
        // -- seek to the first line of the help text --
        df.SeekHelpLine(help.*.hptr, help.*.bit);

        // ----- read the title -----
        var hline = [_]u8{0}**100;
        var len:usize = 0;
        _ = df.GetHelpLine(&hline);
        if (std.mem.indexOfScalar(u8, &hline, 0)) |end| {
            hline[end-1] = 0;
            len = end;
        }
        
        // FIXME: should replace with zig allocator
        if (Dialogs.HelpBox.dwnd.title) |ttl| {
            root.global_allocator.free(ttl);
            Dialogs.HelpBox.dwnd.title = null;
        }

        if (root.global_allocator.dupeZ(u8, hline[0..len])) |buf| {
            Dialogs.HelpBox.dwnd.title = buf;
        } else |_| {
        }

        // ----- set the height and width -----
        Dialogs.HelpBox.dwnd.h = @intCast(@min(help.*.hheight, MAXHEIGHT)+7);
        Dialogs.HelpBox.dwnd.w = @intCast(@max(45, help.*.hwidth+6));

        // ------ position the help window -----
        if (win) |w| {
            BestFit(w, &Dialogs.HelpBox.dwnd);
        }
        // ------- position the command buttons ------ 
        Dialogs.HelpBox.ctl[0].dwnd.w = @intCast(@max(40, help.*.hwidth+2));
        Dialogs.HelpBox.ctl[0].dwnd.h =
                    @intCast(@min(help.*.hheight, MAXHEIGHT)+2);
        const offset:usize = @divFloor(Dialogs.HelpBox.dwnd.w-40, 2);
        for (1..5) |i| {
            Dialogs.HelpBox.ctl[i].dwnd.y =
                            @intCast(@min(help.*.hheight, MAXHEIGHT)+3);
            Dialogs.HelpBox.ctl[i].dwnd.x = (i-1) * 10 + offset;
        }

        // ---- disable ineffective buttons ----
        if (help.*.nexthlp == -1) {
            DialogBox.DisableButton(&Dialogs.HelpBox, c.ID_NEXT);
        } else {
            DialogBox.EnableButton(&Dialogs.HelpBox, c.ID_NEXT);
        }
        if (help.*.prevhlp == -1) {
            DialogBox.DisableButton(&Dialogs.HelpBox, c.ID_PREV);
        } else {
            DialogBox.EnableButton(&Dialogs.HelpBox, c.ID_PREV);
        }
    }
}

// ----- select a new help window from its name -----
pub fn SelectHelp(win:*Window, newhelp:[*c]df.helps, recall:bool) void {
    if (newhelp != null) {
        _ = win.sendMessage(df.HIDE_WINDOW, q.none);

        if (ThisHelp) |help| {
            if (recall and stacked < df.MAXHELPSTACK) {
                HelpStack[stacked] = help-df.FirstHelp;
                stacked += 1;
            }
            ThisHelp = newhelp;
            const hname = std.mem.span(help.*.hname);
            _ = win.getParent().sendMessage(df.DISPLAY_HELP, .{.slice=hname});
        }

        if (stacked>0) {
            DialogBox.EnableButton(&Dialogs.HelpBox, c.ID_BACK);
        } else {
            DialogBox.DisableButton(&Dialogs.HelpBox, c.ID_BACK);
        }
        BuildHelpBox(null);
        if (Dialogs.HelpBox.dwnd.title) |ttl| {
            win.AddTitle(ttl);
        } // handle null title ?
        // --- reposition and resize the help window ---
        Dialogs.HelpBox.dwnd.x = @divFloor(@as(usize, @intCast(df.SCREENWIDTH))-Dialogs.HelpBox.dwnd.w, 2);
        Dialogs.HelpBox.dwnd.y = @divFloor(@as(usize, @intCast(df.SCREENHEIGHT))-Dialogs.HelpBox.dwnd.h, 2);
        _ = win.sendMessage(df.MOVE, .{.position=.{Dialogs.HelpBox.dwnd.x,
                                                   Dialogs.HelpBox.dwnd.y}});
        _ = win.sendMessage(df.SIZE,
                        .{.position=.{Dialogs.HelpBox.dwnd.x + Dialogs.HelpBox.dwnd.w - 1,
                                      Dialogs.HelpBox.dwnd.y + Dialogs.HelpBox.dwnd.h - 1}});
        // --- reposition the controls ---
        for (0..5) |i| {
            var x:usize = Dialogs.HelpBox.ctl[i].dwnd.x+win.GetClientLeft();
            var y:usize = Dialogs.HelpBox.ctl[i].dwnd.y+win.GetClientTop();
            const cw = Dialogs.HelpBox.ctl[i].win;
            if (cw) |cwin| {
                _ = cwin.sendMessage(df.MOVE, .{.position=.{x, y}});
            }
            if (i == 0) {
                x += Dialogs.HelpBox.ctl[i].dwnd.w - 1;
                y += Dialogs.HelpBox.ctl[i].dwnd.h - 1;
                if (cw) |cwin| {
                    _ = cwin.sendMessage(df.SIZE, .{.position=.{x, y}});
                }
            }
        }
        // --- read the help text into the help window ---
        ReadHelp(win);
        lists.ReFocus(win);
        _ = win.sendMessage(df.SHOW_WINDOW, q.none);
    }
}

fn OverLap(a: usize, b: usize) usize {
//    const ov = a - b;
//    return if (ov < 0) 0 else ov;
    return if (a < b) 0 else (a-b);
}


// ----- compute the best location for a help dialogbox -----
fn BestFit(win:*Window, dwnd:*Dialogs.DIALOGWINDOW) void {
    if (win.getClass() == k.MENUBAR or
        win.getClass() == k.APPLICATION) {
        dwnd.*.x = 0;
        dwnd.*.y = 0;
        dwnd.*.center = Window.CENTER_POSITION;
        return;
    }

    // --- compute above overlap ----
    const above:usize = OverLap(dwnd.*.h, win.GetTop());
    // --- compute below overlap ----
    const below:usize = OverLap(win.GetBottom(), @as(usize, @intCast(df.SCREENHEIGHT))-dwnd.*.h);
    // --- compute right overlap ----
    const right:usize = OverLap(win.GetRight(), @as(usize, @intCast(df.SCREENWIDTH))-dwnd.*.w);
    // --- compute left  overlap ----
    const left:usize = OverLap(dwnd.*.w, win.GetLeft());

    if (above < below) {
        dwnd.*.y = @max(0, win.GetTop()-dwnd.*.h-2);
    } else {
        dwnd.*.y = @min(@as(usize, @intCast(df.SCREENHEIGHT))-dwnd.*.h, win.GetBottom()+2);
    }
    if (right < left) {
        dwnd.*.x = @min(win.GetRight()+2, @as(usize, @intCast(df.SCREENWIDTH))-dwnd.*.w);
    } else {
        dwnd.*.x = @max(0, win.GetLeft()-dwnd.*.w-2);
    }

    if (dwnd.*.x == win.GetRight()+2 or dwnd.*.x == win.GetLeft()-dwnd.*.w-2) {
        dwnd.*.y = 0;
        dwnd.*.center.TOP = true;
    }
    if (dwnd.*.y == win.GetTop()-dwnd.*.h-2 or dwnd.*.y == win.GetBottom()+2) {
        dwnd.*.x = 0;
        dwnd.*.center.LEFT = true;
    }
}
 
