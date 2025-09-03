const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

fn FindCmd(mn:*df.MBAR, cmd:c_int) ?*df.PopDown {
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

pub export fn GetCommandText(mn:*df.MBAR, cmd:c_int) callconv(.c) [*c]u8 {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        return pulldown.*.SelectionTitle;
    }
    return null;
}

pub export fn isCascadedCommand(mn:*df.MBAR, cmd:c_int) callconv(.c) c_int {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        if (pulldown.*.Attrib & df.CASCADED > 0) {
            return df.TRUE;
        }
    }
    return df.FALSE;
}

pub export fn ActivateCommand(mn:*df.MBAR, cmd:c_int) callconv(.c) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib &= ~df.INACTIVE;
    }
}

pub export fn DeactivateCommand(mn:*df.MBAR, cmd:c_int) callconv(.c) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib |= df.INACTIVE;
    }
}

pub export fn isActive(mn:*df.MBAR, cmd:c_int) callconv(.c) c_int {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        if (pulldown.*.Attrib & df.INACTIVE == 0) {
            return df.TRUE;
        }
    }
    return df.FALSE;
}

pub export fn GetCommandToggle(mn:*df.MBAR, cmd:c_int) callconv(.c) c_int {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        if (pulldown.*.Attrib & df.CHECKED != 0) {
            return df.TRUE;
        }
    }
    return df.FALSE;
}

pub export fn SetCommandToggle(mn:*df.MBAR, cmd:c_int) callconv(.c) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib |= df.CHECKED;
    }
}

pub export fn ClearCommandToggle(mn:*df.MBAR, cmd:c_int) callconv(.c) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib &= ~df.CHECKED;
    }
}

pub export fn InvertCommandToggle(mn:*df.MBAR, cmd:c_int) callconv(.c) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib ^= df.CHECKED;
    }
}
