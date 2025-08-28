const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");
const picture = @import("PictureBox.zig");
const normal = @import("Normal.zig");
const app = @import("Application.zig");
const dialbox = @import("DialogBox.zig");
const box = @import("Box.zig");
const textbox = @import("TextBox.zig");

// This is temporarily put all wndproc together.
// Once each file in c is ported to zig, this will not be in use.

// Here are the rules for window parameter
// # Coming from c
// - SendMessage(df.WINDOW)
// - BaseWndProc(df.WINDOW)
// - DefaultWndProc(df.WINDOW)
// - PostMessage (df.WINDOW)
// # Coming from zig
// - Window.sendMessage(*Window)
// - zBaseWndProc(*Window)
// - zDefaultWndProc(*Window)
// - EveneQueue(*Window)

pub export fn NormalProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return normal.NormalProc(win, msg, p1, p2);
}

pub export fn ApplicationProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return app.ApplicationProc(win, msg, p1, p2);
}

pub export fn TextBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return textbox.TextBoxProc(win, msg, p1, p2);
}

pub export fn ListBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cListBoxProc(wnd, msg, p1, p2);
}

pub export fn EditBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cEditBoxProc(wnd, msg, p1, p2);
}

pub export fn MenuBarProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cMenuBarProc(wnd, msg, p1, p2);
}

pub export fn PopDownProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cPopDownProc(wnd, msg, p1, p2);
}

pub export fn PictureProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return picture.PictureProc(win, msg, p1, p2);
}

pub export fn DialogProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return dialbox.DialogProc(win, msg, p1, p2);
}

pub export fn BoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return box.BoxProc(win, msg, p1, p2);
}

pub export fn ButtonProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cButtonProc(wnd, msg, p1, p2);
}

pub export fn ComboProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    _ = wnd;
    _ = msg;
    _ = p1;
    _ = p2;
    return df.FALSE;
// not currently in use. port later.
//    return df.cComboProc(wnd, msg, p1, p2);
}

pub export fn TextProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cTextProc(wnd, msg, p1, p2);
}

pub export fn RadioButtonProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cRadioButtonProc(wnd, msg, p1, p2);
}

pub export fn CheckBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cCheckBoxProc(wnd, msg, p1, p2);
}

pub export fn SpinButtonProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cSpinButtonProc(wnd, msg, p1, p2);
}

pub export fn HelpBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cHelpBoxProc(wnd, msg, p1, p2);
}

pub export fn StatusBarProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cStatusBarProc(wnd, msg, p1, p2);
}

pub export fn EditorProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cEditorProc(wnd, msg, p1, p2);
}

// Those are called directly by CreateWindow()
pub export fn HelpTextProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cHelpTextProc(wnd, msg, p1, p2);
}

// For DialogBox, called in dflat.h
pub export fn CancelBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cCancelBoxProc(wnd, msg, p1, p2);
}

pub export fn InputBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    return df.cInputBoxProc(wnd, msg, p1, p2);
}
