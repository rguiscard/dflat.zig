const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

pub export fn SystemMenuProc(wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    if (Window.get_zin(wnd)) |zin| {
        const win = zin;
        switch (msg) {
            df.CREATE_WINDOW => {
                wnd.*.holdmenu = df.ActiveMenuBar;
                df.ActiveMenuBar = &df.SystemMenu;
                df.SystemMenu.PullDown[0].Selection = 0;
            },
            df.LEFT_BUTTON => {
                const wnd1 = df.GetParent(wnd);
                const mx = p1 - win.GetLeft();
                const my = p2 - win.GetTop();
                if (df.HitControlBox(wnd1, mx, my))
                    return df.TRUE;
            },
            df.LB_CHOOSE => {
                df.PostMessage(wnd, df.CLOSE_WINDOW, 0, 0);
            },
            df.DOUBLE_CLICK => {
                if (p2 == df.GetTop(df.GetParent(wnd))) {
                    df.PostMessage(df.GetParent(wnd), msg, p1, p2);
                    _ = df.SendMessage(wnd, df.CLOSE_WINDOW, df.TRUE, 0);
                }
                return df.TRUE;
            },
            df.SHIFT_CHANGED => {
                return df.TRUE;
            },
            df.CLOSE_WINDOW => {
                df.ActiveMenuBar = wnd.*.holdmenu;
            },
            else => {
            }
        }
    }
    return root.zDefaultWndProc(wnd, msg, p1, p2);
}

// ------- Build a system menu --------
pub export fn BuildSystemMenu(wnd: df.WINDOW) callconv(.c) void {
    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));

    var lf:c_int = @intCast(win.GetLeft()+1);
    var tp:c_int = @intCast(win.GetTop()+1);
    const ht:c_int = df.MenuHeight(&df.SystemMenu.PullDown[0].Selections);
    const wd:c_int = df.MenuWidth(&df.SystemMenu.PullDown[0].Selections);

    if (df.GetClass(wnd) == df.APPLICATION) {
        df.SystemMenu.PullDown[0].Selections[6].Accelerator = df.ALT_F4;
    } else {
        df.SystemMenu.PullDown[0].Selections[6].Accelerator = df.CTRL_F4;
    }

    if (lf+wd > df.SCREENWIDTH-1)
        lf = (df.SCREENWIDTH-1) - wd;
    if (tp+ht > df.SCREENHEIGHT-2)
        tp = (df.SCREENHEIGHT-2) - ht;

    const SystemMenuWin = Window.create(df.POPDOWNMENU, null,
                lf,tp,ht,wd,null,wnd,SystemMenuProc, 0);

    if (wnd.*.condition == df.ISRESTORED) {
        df.DeactivateCommand(&df.SystemMenu, df.ID_SYSRESTORE);
    } else {
        df.ActivateCommand(&df.SystemMenu, df.ID_SYSRESTORE);
    }

    if (df.TestAttribute(wnd, df.MOVEABLE)>0
            and (wnd.*.condition != df.ISMAXIMIZED)) {
        df.ActivateCommand(&df.SystemMenu, df.ID_SYSMOVE);
    } else {
        df.DeactivateCommand(&df.SystemMenu, df.ID_SYSMOVE);
    }

    if ((wnd.*.condition != df.ISRESTORED) or
            (df.TestAttribute(wnd, df.SIZEABLE) == df.FALSE)) {
        df.DeactivateCommand(&df.SystemMenu, df.ID_SYSSIZE);
    } else {
        df.ActivateCommand(&df.SystemMenu, df.ID_SYSSIZE);
    }

    if ((wnd.*.condition == df.ISMINIMIZED) or
            (df.TestAttribute(wnd, df.MINMAXBOX) == df.FALSE)) {
        df.DeactivateCommand(&df.SystemMenu, df.ID_SYSMINIMIZE);
    } else {
        df.ActivateCommand(&df.SystemMenu, df.ID_SYSMINIMIZE);
    }

    if ((wnd.*.condition != df.ISRESTORED) or
            (df.TestAttribute(wnd, df.MINMAXBOX) == df.FALSE)) {
        df.DeactivateCommand(&df.SystemMenu, df.ID_SYSMAXIMIZE);
    } else {
        df.ActivateCommand(&df.SystemMenu, df.ID_SYSMAXIMIZE);
    }

    _ = SystemMenuWin.sendMessage(df.BUILD_SELECTIONS,
                  @intCast(@intFromPtr(&df.SystemMenu.PullDown[0])), 0);
    _ = SystemMenuWin.sendMessage(df.SETFOCUS, df.TRUE, 0);
    _ = SystemMenuWin.sendMessage(df.SHOW_WINDOW, 0, 0);
}
