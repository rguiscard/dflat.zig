const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const menus = @import("Menus.zig");
const menu = @import("Menu.zig");
const menubar = @import("MenuBar.zig");
const popdown = @import("PopDown.zig");
const c = @import("Commands.zig").Command;
const k = @import("Classes.zig").CLASS;
const q = @import("Message.zig");

pub fn SystemMenuProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    switch (msg) {
        df.CREATE_WINDOW => {
            win.holdmenu = menubar.ActiveMenuBar;
            menubar.ActiveMenuBar = &menus.SystemMenu;
            menus.SystemMenu.PullDown[0].Selection = 0;
        },
        df.LEFT_BUTTON => {
            const pp1:usize = @intCast(p1);
            const pp2:usize = @intCast(p2);
            const mx:usize = if (pp1 > win.GetLeft()) pp1 - win.GetLeft() else 0;
            const my:usize = if (pp2 > win.GetTop()) pp2 - win.GetTop() else 0;
            if (win.parent) |pw| {
                if (pw.HitControlBox(mx, my))
                    return true;
            }
        },
        df.LB_CHOOSE => {
            q.PostMessage(win, df.CLOSE_WINDOW, 0, 0);
        },
        df.DOUBLE_CLICK => {
            if (p2 == win.getParent().GetTop()) {
                q.PostMessage(win.parent, msg, p1, p2);
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
    return root.DefaultWndProc(win, msg, p1, p2);
}

// ------- Build a system menu --------
pub fn BuildSystemMenu(win: *Window) void {
    var lf:usize = win.GetLeft()+1;
    var tp:usize = win.GetTop()+1;
    const selections:[]menus.PopDown = &menus.SystemMenu.PullDown[0].Selections;
    const ht:usize = @intCast(popdown.MenuHeight(@constCast(&selections)));
    const wd:usize = @intCast(popdown.MenuWidth(@constCast(&selections)));

    if (win.getClass() == k.APPLICATION) {
        menus.SystemMenu.PullDown[0].Selections[6].Accelerator = df.ALT_F4;
    } else {
        menus.SystemMenu.PullDown[0].Selections[6].Accelerator = df.CTRL_F4;
    }

    if (lf+wd > df.SCREENWIDTH-1) {
        const screen_wd:usize = @intCast(df.SCREENWIDTH-1);
        lf = screen_wd - wd;
    }
    if (tp+ht > df.SCREENHEIGHT-2) {
        const screen_ht:usize = @intCast(df.SCREENHEIGHT-2);
        tp = screen_ht - ht;
    }

    const SystemMenuWin = Window.create(k.POPDOWNMENU, null,
                @intCast(lf),@intCast(tp),@intCast(ht),@intCast(wd),null,win,SystemMenuProc, 0);

    if (win.condition == .ISRESTORED) {
        menu.DeactivateCommand(&menus.SystemMenu, c.ID_SYSRESTORE);
    } else {
        menu.ActivateCommand(&menus.SystemMenu, c.ID_SYSRESTORE);
    }

    if (win.TestAttribute(df.MOVEABLE)
            and (win.condition != .ISMAXIMIZED)) {
        menu.ActivateCommand(&menus.SystemMenu, c.ID_SYSMOVE);
    } else {
        menu.DeactivateCommand(&menus.SystemMenu, c.ID_SYSMOVE);
    }

    if ((win.condition != .ISRESTORED) or
            (win.TestAttribute(df.SIZEABLE) == false)) {
        menu.DeactivateCommand(&menus.SystemMenu, c.ID_SYSSIZE);
    } else {
        menu.ActivateCommand(&menus.SystemMenu, c.ID_SYSSIZE);
    }

    if ((win.condition == .ISMINIMIZED) or
            (win.TestAttribute(df.MINMAXBOX) == false)) {
        menu.DeactivateCommand(&menus.SystemMenu, c.ID_SYSMINIMIZE);
    } else {
        menu.ActivateCommand(&menus.SystemMenu, c.ID_SYSMINIMIZE);
    }

    if ((win.condition != .ISRESTORED) or
            (win.TestAttribute(df.MINMAXBOX) == false)) {
        menu.DeactivateCommand(&menus.SystemMenu, c.ID_SYSMAXIMIZE);
    } else {
        menu.ActivateCommand(&menus.SystemMenu, c.ID_SYSMAXIMIZE);
    }

    _ = SystemMenuWin.sendMessage(df.BUILD_SELECTIONS,
                  @intCast(@intFromPtr(&menus.SystemMenu.PullDown[0])), 0);
    _ = SystemMenuWin.sendMessage(df.SETFOCUS, df.TRUE, 0);
    _ = SystemMenuWin.sendMessage(df.SHOW_WINDOW, 0, 0);
}
