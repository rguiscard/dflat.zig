const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const menus = @import("Menus.zig");
const Command = @import("Commands.zig").Command;

fn FindCmd(mn:*menus.MBAR, cmd:Command) ?*menus.PopDown {
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

pub fn GetCommandText(mn:*menus.MBAR, cmd:Command) ?[]const u8 {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        if (pulldown.*.SelectionTitle) |title| {
            return title;
        }
    }
    return null;
}

pub fn isCascadedCommand(mn:*menus.MBAR, cmd:Command) c_int {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        if (pulldown.*.Attrib.CASCADED) {
            return df.TRUE;
        }
    }
    return df.FALSE;
}

pub fn ActivateCommand(mn:*menus.MBAR, cmd:Command) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib.INACTIVE = false;
    }
}

pub fn DeactivateCommand(mn:*menus.MBAR, cmd:Command) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib.INACTIVE = true;
    }
}

pub fn isActive(mn:*menus.MBAR, cmd:Command) c_int {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        if (pulldown.*.Attrib.INACTIVE == false) {
            return df.TRUE;
        }
    }
    return df.FALSE;
}

pub fn GetCommandToggle(mn:*menus.MBAR, cmd:Command) bool {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        if (pulldown.*.Attrib.CHECKED) {
            return true;
        }
    }
    return false;
}

pub fn SetCommandToggle(mn:*menus.MBAR, cmd:Command) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib.CHECKED = true;
    }
}

pub fn ClearCommandToggle(mn:*menus.MBAR, cmd:Command) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib.CHECKED = false;
    }
}

pub fn InvertCommandToggle(mn:*menus.MBAR, cmd:c_int) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
//        pulldown.*.Attrib ^= df.CHECKED;
        pulldown.*.Attrib.CHECKED = !pulldown.*.Attrib.CHECKE;
    }
}
