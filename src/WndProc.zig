const df = @import("ImportC.zig").df;
const picture = @import("PictureBox.zig");
const dialbox = @import("DialogBox.zig");

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

// Porting priority
// - dialbox.c: several CreateWindow
// - memopad.c: several CreateWindow (done)
// - sysmenu.c: one CreateWindow (done)
// - watch.c: one CreateWindow (done)

pub export fn NormalProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cNormalProc(wnd, msg, p1, p2);
}

pub export fn ApplicationProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cApplicationProc(wnd, msg, p1, p2);
}

pub export fn TextBoxProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cTextBoxProc(wnd, msg, p1, p2);
}

pub export fn ListBoxProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cListBoxProc(wnd, msg, p1, p2);
}

pub export fn EditBoxProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cEditBoxProc(wnd, msg, p1, p2);
}

pub export fn MenuBarProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cMenuBarProc(wnd, msg, p1, p2);
}

pub export fn PopDownProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cPopDownProc(wnd, msg, p1, p2);
}

pub export fn PictureProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return picture.PictureProc(wnd, msg, p1, p2);
}

pub export fn DialogProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return dialbox.DialogProc(wnd, msg, p1, p2);
}

pub export fn BoxProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cBoxProc(wnd, msg, p1, p2);
}

pub export fn ButtonProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cButtonProc(wnd, msg, p1, p2);
}

pub export fn ComboProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    _ = wnd;
    _ = msg;
    _ = p1;
    _ = p2;
    return df.FALSE;
// not currently in use. port later.
//    return df.cComboProc(wnd, msg, p1, p2);
}

pub export fn TextProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cTextProc(wnd, msg, p1, p2);
}

pub export fn RadioButtonProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cRadioButtonProc(wnd, msg, p1, p2);
}

pub export fn CheckBoxProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cCheckBoxProc(wnd, msg, p1, p2);
}

pub export fn SpinButtonProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cSpinButtonProc(wnd, msg, p1, p2);
}

pub export fn HelpBoxProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cHelpBoxProc(wnd, msg, p1, p2);
}

pub export fn StatusBarProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cStatusBarProc(wnd, msg, p1, p2);
}

pub export fn EditorProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cEditorProc(wnd, msg, p1, p2);
}

// Those are called directly by CreateWindow()
pub export fn HelpTextProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cHelpTextProc(wnd, msg, p1, p2);
}

pub export fn MemoPadProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cMemoPadProc(wnd, msg, p1, p2);
}

pub export fn OurEditorProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cOurEditorProc(wnd, msg, p1, p2);
}

// For DialogBox, called in dflat.h
pub export fn MessageBoxProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cMessageBoxProc(wnd, msg, p1, p2);
}

pub export fn YesNoBoxProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cYesNoBoxProc(wnd, msg, p1, p2);
}

pub export fn ErrorBoxProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cErrorBoxProc(wnd, msg, p1, p2);
}

pub export fn CancelBoxProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cCancelBoxProc(wnd, msg, p1, p2);
}

pub export fn InputBoxProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cInputBoxProc(wnd, msg, p1, p2);
}

// From dialbox.c
pub export fn ControlProc(wnd:df.WINDOW, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) callconv(.c) c_int {
    return df.cControlProc(wnd, msg, p1, p2);
}
