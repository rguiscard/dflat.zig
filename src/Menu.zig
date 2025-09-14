const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const menus = @import("Menus.zig");

fn FindCmd(mn:*menus.MBAR, cmd:c_int) ?*menus.PopDown {
    for(&mn.*.PullDown) |*pulldown| {
        if (pulldown.Title != null) {
            for(&pulldown.Selections) |*selection| {
                if (selection.SelectionTitle != null) {
                    if (selection.ActionId == cmd) {
                        return @constCast(selection);
                    }
                }
            }
        }
    }
    return null;
}

pub fn GetCommandText(mn:*menus.MBAR, cmd:c_int) [*c]u8 {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        return pulldown.*.SelectionTitle;
    }
    return null;
}

pub fn isCascadedCommand(mn:*menus.MBAR, cmd:c_int) c_int {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        if (pulldown.*.Attrib & df.CASCADED > 0) {
            return df.TRUE;
        }
    }
    return df.FALSE;
}

pub fn ActivateCommand(mn:*menus.MBAR, cmd:c_int) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib &= ~df.INACTIVE;
    }
}

pub fn DeactivateCommand(mn:*menus.MBAR, cmd:c_int) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib |= df.INACTIVE;
    }
}

pub fn isActive(mn:*menus.MBAR, cmd:c_int) c_int {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        if (pulldown.*.Attrib & df.INACTIVE == 0) {
            return df.TRUE;
        }
    }
    return df.FALSE;
}

pub fn GetCommandToggle(mn:*menus.MBAR, cmd:c_int) c_int {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        if (pulldown.*.Attrib & df.CHECKED != 0) {
            return df.TRUE;
        }
    }
    return df.FALSE;
}

pub fn SetCommandToggle(mn:*menus.MBAR, cmd:c_int) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib |= df.CHECKED;
    }
}

pub fn ClearCommandToggle(mn:*menus.MBAR, cmd:c_int) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib &= ~df.CHECKED;
    }
}

pub fn InvertCommandToggle(mn:*menus.MBAR, cmd:c_int) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib ^= df.CHECKED;
    }
}
