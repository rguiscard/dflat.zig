const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const menus = @import("Menus.zig");
const menu = @import("Menu.zig");
const menubar = @import("MenuBar.zig");
const popdown = @import("PopDown.zig");
const c = @import("Commands.zig").Command;

pub fn SystemMenuProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
        switch (msg) {
            df.CREATE_WINDOW => {
                win.holdmenu = menubar.ActiveMenuBar;
                menubar.ActiveMenuBar = &menus.SystemMenu;
                menus.SystemMenu.PullDown[0].Selection = 0;
            },
            df.LEFT_BUTTON => {
                const mx = p1 - win.GetLeft();
                const my = p2 - win.GetTop();
                if (df.HitControlBox(win.getParent().win, mx, my))
                    return true;
            },
            df.LB_CHOOSE => {
                df.PostMessage(wnd, df.CLOSE_WINDOW, 0, 0);
            },
            df.DOUBLE_CLICK => {
                if (p2 == win.getParent().GetTop()) {
                    df.PostMessage(win.getParent().win, msg, p1, p2);
                    _ = win.sendMessage(df.CLOSE_WINDOW, df.TRUE, 0);
                }
                return true;
            },
            df.SHIFT_CHANGED => {
                return true;
            },
            df.CLOSE_WINDOW => {
                menubar.ActiveMenuBar = win.holdmenu;
            },
            else => {
            }
        }
    return root.zDefaultWndProc(win, msg, p1, p2);
}

// ------- Build a system menu --------
pub fn BuildSystemMenu(win: *Window) void {
    const wnd = win.win;

    var lf:c_int = @intCast(win.GetLeft()+1);
    var tp:c_int = @intCast(win.GetTop()+1);
    const selections:[]menus.PopDown = &menus.SystemMenu.PullDown[0].Selections;
    const ht:c_int = popdown.MenuHeight(@constCast(&selections));
    const wd:c_int = popdown.MenuWidth(@constCast(&selections));

    if (win.getClass() == df.APPLICATION) {
        menus.SystemMenu.PullDown[0].Selections[6].Accelerator = df.ALT_F4;
    } else {
        menus.SystemMenu.PullDown[0].Selections[6].Accelerator = df.CTRL_F4;
    }

    if (lf+wd > df.SCREENWIDTH-1)
        lf = (df.SCREENWIDTH-1) - wd;
    if (tp+ht > df.SCREENHEIGHT-2)
        tp = (df.SCREENHEIGHT-2) - ht;

    const SystemMenuWin = Window.create(df.POPDOWNMENU, null,
                lf,tp,ht,wd,null,win,SystemMenuProc, 0);

    if (wnd.*.condition == df.ISRESTORED) {
        menu.DeactivateCommand(&menus.SystemMenu, c.ID_SYSRESTORE);
    } else {
        menu.ActivateCommand(&menus.SystemMenu, c.ID_SYSRESTORE);
    }

    if (df.TestAttribute(wnd, df.MOVEABLE)>0
            and (wnd.*.condition != df.ISMAXIMIZED)) {
        menu.ActivateCommand(&menus.SystemMenu, c.ID_SYSMOVE);
    } else {
        menu.DeactivateCommand(&menus.SystemMenu, c.ID_SYSMOVE);
    }

    if ((wnd.*.condition != df.ISRESTORED) or
            (df.TestAttribute(wnd, df.SIZEABLE) == df.FALSE)) {
        menu.DeactivateCommand(&menus.SystemMenu, c.ID_SYSSIZE);
    } else {
        menu.ActivateCommand(&menus.SystemMenu, c.ID_SYSSIZE);
    }

    if ((wnd.*.condition == df.ISMINIMIZED) or
            (df.TestAttribute(wnd, df.MINMAXBOX) == df.FALSE)) {
        menu.DeactivateCommand(&menus.SystemMenu, c.ID_SYSMINIMIZE);
    } else {
        menu.ActivateCommand(&menus.SystemMenu, c.ID_SYSMINIMIZE);
    }

    if ((wnd.*.condition != df.ISRESTORED) or
            (df.TestAttribute(wnd, df.MINMAXBOX) == df.FALSE)) {
        menu.DeactivateCommand(&menus.SystemMenu, c.ID_SYSMAXIMIZE);
    } else {
        menu.ActivateCommand(&menus.SystemMenu, c.ID_SYSMAXIMIZE);
    }

    _ = SystemMenuWin.sendMessage(df.BUILD_SELECTIONS,
                  @intCast(@intFromPtr(&menus.SystemMenu.PullDown[0])), 0);
    _ = SystemMenuWin.sendMessage(df.SETFOCUS, df.TRUE, 0);
    _ = SystemMenuWin.sendMessage(df.SHOW_WINDOW, 0, 0);
}
