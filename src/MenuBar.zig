const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;
const rect = @import("Rect.zig");
const app = @import("Application.zig");
const menu = @import("Menu.zig");
const menus = @import("Menus.zig");
const popdown = @import("PopDown.zig");

// positions in menu bar & shortcut key value
var menupos = [_]struct{x1:isize, x2:isize, sc:u8} {.{.x1=-1, .x2=-1, .sc=0}}**10;
var mctr:usize = 0;
var mwin:?*Window = null;
var Selecting:bool = false;
var Cascaders = [_]df.WINDOW{0}**menus.MAXCASCADES;
var casc:usize = 0;
pub var ActiveMenuBar:?*menus.MBAR = null;
var ActiveMenu:?*[menus.MAXPULLDOWNS+1]menus.MENU = null; // this should be private

// ----------- SETFOCUS Message -----------
fn SetFocusMsg(win:*Window,p1:df.PARAM) bool {
    const rtn = root.zBaseWndProc(df.MENUBAR, win, df.SETFOCUS, p1, 0);
    if (p1>0) {
        _ = win.getParent().sendMessage(df.ADDSTATUS, 0, 0);
    } else {
        _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
    }
    return rtn;
}

// --------- BUILDMENU Message ---------
fn BuildMenuMsg(win:*Window, p1:df.PARAM) void {
    const wnd = win.win;
    reset_menubar(win);
    if (win.gapbuf) |buf| {
        const b = [_]u8{0}**80;
        var offset:usize = 3;
        var idx:usize = 0;
        const pp1:usize = @intCast(p1);
        ActiveMenuBar = @ptrFromInt(pp1);
        if (ActiveMenuBar) |mbar| {
            for(mbar.*.PullDown) |m| {
                if (m.Title) |title| {
                    if (title.len+3 > buf.items.len+offset)
                        break; // longer than buffer size. should compare to screenwidth ?
                    const len = popdown.CopyCommand(@constCast(b[0..]), title, false, wnd.*.WindowColors [df.STD_COLOR] [df.BG]);
                    while(offset > buf.len()) {
                        if (buf.insert(' ')) {} else |_| {}
                    }
                    buf.moveCursor(offset);
                    if (buf.insertSlice(b[0..@intCast(len)])) {} else |_| {}

                    menupos[idx].x1 = @intCast(offset);
                    offset += @intCast(title.len + (3+df.MSPACE));
                    menupos[idx].x2 = @intCast(offset-df.MSPACE);

                    if (std.mem.indexOfScalar(u8, title, df.SHORTCUTCHAR)) |pos| {
                        menupos[idx].sc = std.ascii.toLower(title[pos+1]);
                    }
                    idx += 1;
                    mctr += 1;
                }
            }
            // FIXME: width is not accurate
            while(buf.len() < df.SCREENWIDTH*2) {
                 if (buf.insert(' ')) {} else |_| {}
            }

            ActiveMenu = &mbar.*.PullDown;
        }
        wnd.*.text = @constCast(buf.toString().ptr);
        wnd.*.textlen = @intCast(buf.len());
    } else {
        // error 
    }
}

// ---------- PAINT Message ----------
fn PaintMsg(win:*Window) void {
    const wnd = win.win;
    if (Selecting)
        return;
    if (win == Window.inFocus) {
        _ = win.getParent().sendMessage(df.ADDSTATUS, 0, 0);
    }
    df.SetStandardColor(wnd);

    if (win.gapbuf) |buf| {
        buf.compact();
        if (root.global_allocator.dupeZ(u8, buf.items)) |text| {
            defer root.global_allocator.free(text);

//            df.wputs(wnd, wnd.*.text, 0, 0);
            df.wputs(wnd, text.ptr, 0, 0);

            if (ActiveMenuBar) |mbar| {
                if ((mbar.*.ActiveSelection != -1) and
                        ((win == Window.inFocus) or (mwin != null))) {

                    const idx:usize = @intCast(mbar.*.ActiveSelection);
                    const offset=menupos[idx].x1;
                    const offset1=menupos[idx].x2;

//                    wnd.*.text[@intCast(offset1)] = 0;
                    text[@intCast(offset1)] = 0;

                    df.SetReverseColor(wnd);
//                    df.cPaintMenu(wnd, @intCast(offset), @intCast(offset1), mbar.*.ActiveSelection);

                    if (std.mem.indexOfScalarPos(u8, text, @intCast(offset), df.CHANGECOLOR)) |idxx| {
                        text[idxx+2] = @intCast(df.background | 0x80);
                    }
                    // ActiveSelection suggest how many shortcut symbol ahead
                    df.wputs(wnd, &text[@intCast(offset)], @intCast(offset-mbar.*.ActiveSelection*4), 0);
                    buf.setChar(@intCast(offset1), ' ');

                    if ((mwin == null) and (win == Window.inFocus)) {
                        if (ActiveMenu) |amenu| {
                            const st = amenu[idx].StatusText;
                            if (st) |txt| {
                                _ = win.getParent().sendTextMessage(df.ADDSTATUS, @constCast(txt), 0);
                            }
                        }
                    }
                }
            }
        } else |_| {
        }
    }
}

// ------------ KEYBOARD Message -------------
fn KeyboardMsg(win:*Window,p1:df.PARAM) void {
    if ((mwin == null) and (p1 < 256)) {
        // ----- search for menu bar shortcut keys ----
        const cc = std.ascii.toLower(@intCast(p1));
        const a = df.AltConvert(@intCast(p1));
        for (menupos, 0..) |m, idx| {
            if (((Window.inFocus == win) and (m.sc == cc)) or
                ((a > 0) and (m.sc == a))) {
                _ = win.sendMessage(df.SETFOCUS, df.TRUE, 0);
                _ = win.sendMessage(df.MB_SELECTION, @intCast(idx), 0);
                return;
            }
        }
    }
    // -------- search for accelerator keys --------
    if (ActiveMenuBar) |mbar| {
        for (&mbar.*.PullDown) |*mnu| {
            if (mnu.Title != null) {
                if (mnu.PrepMenu) |proc| {
                    proc(GetDocFocus().win, @constCast(mnu));
                }
                for (&mnu.Selections) |*pd| {
                    if (pd.SelectionTitle) |_| {
                        if (pd.Accelerator == p1) {
                            if (pd.Attrib.INACTIVE) {
                                df.beep();
                            } else {
                                if (pd.Attrib.TOGGLE) {
                                    pd.Attrib.CHECKED = !pd.Attrib.CHECKED;
                                }
                                _ = GetDocFocus().sendMessage(df.SETFOCUS, df.TRUE, 0);
                                q.PostMessage(win.getParent().win, df.COMMAND, @intFromEnum(pd.ActionId), 0);
                            }
                        }
                    }
                }
            }
        }
    }
//    MENU *mnu;
//        int sel;
//    const mnu = ActiveMenu;
//-   while (mnu->Title != (void *)-1)    {
//    while (mnu->Title != NULL)    {
//        struct PopDown *pd = mnu->Selections;
//        if (mnu->PrepMenu)
//            (*(mnu->PrepMenu))(GetDocFocus(), mnu);
//        while (pd->SelectionTitle != NULL)    {
//            if (pd->Accelerator == (int) p1)    {
//                if (pd->Attrib & INACTIVE)
//                    beep();
//                else    {
//                    if (pd->Attrib & TOGGLE)
//                        pd->Attrib ^= CHECKED;
//                    SendMessage(GetDocFocus(),
//                        SETFOCUS, TRUE, 0);
//                    PostMessage(GetParent(wnd),
//                        COMMAND, pd->ActionId, 0);
//                }
//                return;
//            }
//            pd++;
//        }
//        mnu++;
//    }
//    switch ((int)p1)    {
//        case F1:
//            if (ActiveMenu == NULL || ActiveMenuBar == NULL)
//                                break;
//                        sel = ActiveMenuBar->ActiveSelection;
//                        if (sel == -1)  {
//                        BaseWndProc(MENUBAR, wnd, KEYBOARD, F1, 0);
//                                return;
//                        }
//                        mnu = ActiveMenu+sel;
//                        if (mwnd == NULL ||
//                                        mnu->Selections[0].SelectionTitle == NULL) {
//                DisplayHelp(wnd,mnu->Title);
//                return;
//                        }
//            break;
//        case '\r':
//            if (mwnd == NULL &&
//                    ActiveMenuBar->ActiveSelection != -1)
//                SendMessage(wnd, MB_SELECTION,
//                    ActiveMenuBar->ActiveSelection, 0);
//            break;
//        case F10:
//            if (wnd != inFocus && mwnd == NULL)    {
//                SendMessage(wnd, SETFOCUS, TRUE, 0);
//                            if ( ActiveMenuBar->ActiveSelection == -1)
//                                ActiveMenuBar->ActiveSelection = 0;
//                            SendMessage(wnd, PAINT, 0, 0);
//                break;
//            }
//            /* ------- fall through ------- */
//        case ESC:
//            if (inFocus == wnd && mwnd == NULL)    {
//                ActiveMenuBar->ActiveSelection = -1;
//                SendMessage(GetDocFocus(),SETFOCUS,TRUE,0);
//                SendMessage(wnd, PAINT, 0, 0);
//            }
//            break;
//        case FWD:
//            ActiveMenuBar->ActiveSelection++;
//            if (ActiveMenuBar->ActiveSelection == get_mctr())
//                ActiveMenuBar->ActiveSelection = 0;
//            if (mwnd != NULL)
//                SendMessage(wnd, MB_SELECTION,
//                    ActiveMenuBar->ActiveSelection, 0);
//            else
//                SendMessage(wnd, PAINT, 0, 0);
//            break;
//        case BS:
//            if (ActiveMenuBar->ActiveSelection == 0 ||
//                                        ActiveMenuBar->ActiveSelection == -1)
//                ActiveMenuBar->ActiveSelection = get_mctr();
//            --ActiveMenuBar->ActiveSelection;
//            if (mwnd != NULL)
//                SendMessage(wnd, MB_SELECTION,
//                    ActiveMenuBar->ActiveSelection, 0);
//            else
//                SendMessage(wnd, PAINT, 0, 0);
//            break;
//        default:
//            break;
//    }
}

// --------------- LEFT_BUTTON Message ----------
fn LeftButtonMsg(win:*Window,p1:df.PARAM) void {
    const mx = p1-win.GetLeft();
    // --- compute the selection that the left button hit ---
    for (menupos, 0..) |m, idx| {
        if (m.x1 == -1) {
            break; // out of range
        }
        const i:isize = @intCast(idx);
        if ((mx >= menupos[idx].x1-4*i) and
               (mx <= menupos[idx].x2-4*i-5)) {
            if (ActiveMenuBar) |mbar| {
                if ((idx != mbar.*.ActiveSelection) or (mwin == null)) {
                    _ = win.sendMessage(df.MB_SELECTION, i, 0);
                }
            }
            break;
        }
    }
}

// -------------- MB_SELECTION Message --------------
fn SelectionMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    var mx:c_int = 0;
    var my:c_int = 0;

    if (p2 == 0) {
        if (ActiveMenuBar) |mbar| {
            mbar.*.ActiveSelection = -1;
        }
        _ = win.sendMessage(df.PAINT, 0, 0);
    }
    Selecting = true;
    // should use Menu or Menu* ?
    if (ActiveMenu) |amenu| {
        const mnu = &amenu[@intCast(p1)];
//        const mnu = &ActiveMenu[@intCast(p1)];
        if (mnu.*.PrepMenu) |proc| {
            proc(GetDocFocus().win, @constCast(mnu));
        }
        const selections:[]menus.PopDown = &mnu.*.Selections;
        const wd = popdown.MenuWidth(@constCast(&selections));
        if (p2>0) {
            const brd = win.GetRight();
            if (mwin) |zin| {
                mx = @intCast(zin.GetLeft() + zin.WindowWidth() - 1);
                if (mx + wd > brd) {
                    mx = @intCast(brd - wd);
                }
                my = @intCast(zin.GetTop() + zin.win.*.selection);
            }
        } else {
            var offset = menupos[@intCast(p1)].x1 - 4 * p1;
            if (mwin) |m| {
                _ = m.sendMessage(df.CLOSE_WINDOW, 0, 0);
            }
            if (ActiveMenuBar) |mbar| { 
                mbar.*.ActiveSelection = @intCast(p1);
            }
            if (offset > win.WindowWidth()-wd) {
                offset = win.WindowWidth()-wd;
            }
            mx = @intCast(win.GetLeft()+offset);
            my = @intCast(win.GetTop()+1);
        }
        mwin = Window.create(df.POPDOWNMENU, null,
                    mx, my,
                    popdown.MenuHeight(@constCast(&selections)),
                    wd,
                    null,
                    win,
                    null,
                    df.SHADOW);
        if (p2 == 0) {
            Selecting = false;
            _ = win.sendMessage(df.PAINT, 0, 0);
            Selecting = true;
        }
        if (mnu.*.Selections[0].SelectionTitle != null) {
            if (mwin) |m| {
                _ = m.sendMessage(df.BUILD_SELECTIONS, @intCast(@intFromPtr(mnu)), 0);
                _ = m.sendMessage(df.SETFOCUS, df.TRUE, 0);
                _ = m.sendMessage(df.SHOW_WINDOW, 0, 0);
            }
        }
    }
    Selecting = false;
}

// --------- COMMAND Message ----------
fn CommandMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const cmd:c = @enumFromInt(p1);
    if (cmd == c.ID_HELP) {
        _ = root.zBaseWndProc(df.MENUBAR, win, df.COMMAND, p1, p2);
        return;
    }
    if (ActiveMenuBar) |mbar| {
        if (menu.isCascadedCommand(mbar, @enumFromInt(p1))>0) {
            // FIXME: Cascade menu will show, but command will not be sent.
            // Could possibly to title is not (void*)-1, but null.
            //
            // find the cascaded menu based on command id in p1
            for(mbar.*.PullDown[mctr..], mctr..) |mnu, del| {
                if ((mnu.CascadeId != -1) and // instead of using -1 for title, check CascadeId.
                    (mnu.CascadeId == p1)) {
                        if (casc < menus.MAXCASCADES) {
                            Cascaders[casc] = if (mwin) |m| m.win else null;
                            casc += 1;
                            _ = win.sendMessage(df.MB_SELECTION, @intCast(del), df.TRUE);
                        }
                        break;
                }
            }
        } else {
            if (mwin) |m| {
                _ = m.sendMessage(df.CLOSE_WINDOW, 0, 0);
            }
            _ = GetDocFocus().sendMessage(df.SETFOCUS, df.TRUE, 0);
            q.PostMessage(win.getParent().win, df.COMMAND, p1, p2);
        }
    }
}

// --------------- CLOSE_POPDOWN Message ---------------
fn ClosePopdownMsg(win:*Window) void {
    if (casc > 0) {
        casc -= 1;
        _ = q.SendMessage(Cascaders[casc], df.CLOSE_WINDOW, 0, 0);
    } else {
        mwin = null;
        if (ActiveMenuBar) |mbar| {
            mbar.*.ActiveSelection = -1;
        }
        if (Selecting == false) {
            _ = GetDocFocus().sendMessage(df.SETFOCUS, df.TRUE, 0);
            _ = win.sendMessage(df.PAINT, 0, 0);
        }
    }
}

// ---------------- CLOSE_WINDOW Message ---------------
fn CloseWindowMsg(win:*Window) void {
    const wnd = win.win;
    if (win.gapbuf) |buf| {
        buf.clear();
        // buf.deinit(); // free ?
//        win.text = null;
        wnd.*.text = null;
    }
    mctr = 0;
    if (ActiveMenuBar) |mbar| {
        mbar.*.ActiveSelection = -1;
    }
    ActiveMenu = null;
    ActiveMenuBar = null;
}

pub fn MenuBarProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            reset_menubar(win);
        },
        df.SETFOCUS => {
            return SetFocusMsg(win, p1);
        },
        df.BUILDMENU => {
            BuildMenuMsg(win, p1);
        },
        df.PAINT => {
            if ((df.isVisible(wnd)>0) and (wnd.*.text != null)) {
                PaintMsg(win);
                return false;
            }
        },
        df.BORDER => {
            if (mwin == null) {
                _ = win.sendMessage(df.PAINT, 0, 0);
            }
            return true;
        },
        df.KEYBOARD => {
            KeyboardMsg(win, p1);
            return true;
        },
        df.LEFT_BUTTON => {
            LeftButtonMsg(win, p1);
            return true;
        },
        df.MB_SELECTION => {
           SelectionMsg(win, p1, p2);
        },
        df.COMMAND => {
            CommandMsg(win, p1, p2);
            return true;
        },
        df.INSIDE_WINDOW => {
            return rect.InsideRect(@intCast(p1), @intCast(p2), win.WindowRect());
        },
        df.CLOSE_POPDOWN => {
            ClosePopdownMsg(win);
            return true;
        },
        df.CLOSE_WINDOW => {
            const rtn = root.zBaseWndProc(df.MENUBAR, win, msg, p1, p2);
            CloseWindowMsg(win);
            return rtn;
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.MENUBAR, win, msg, p1, p2);
}

// ------------- reset the MENUBAR --------------
fn reset_menubar(win:*Window) void {
    const wnd = win.win;
    if (win.getGapBuffer(@intCast(df.SCREENWIDTH+5))) |_| {
        wnd.*.text = null;
        wnd.*.textlen = 0;
    }
}

fn GetDocFocus() *Window {
    if (app.ApplicationWindow) |awin| {
        var win:?*Window = awin;
        if (win) |w| {
            win = w.lastWindow();
            while (win != null and (win.?.getClass() == df.MENUBAR or
                                    win.?.getClass() == df.STATUSBAR)) {
                win = win.?.prevWindow();
            }
            if (win) |ww| {
                var w1:*Window = ww;
                while (w1.*.childfocus) |cf| {
                    w1 = cf;
                    win = cf; // win need to keep updated
                }
            }
        }
        return win orelse awin;
//        return if (win != null) win.?.win else awin.win;
    } else {
        unreachable;
//        return null;
    }
}
