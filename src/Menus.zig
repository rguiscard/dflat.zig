const std = @import("std");
const df = @import("ImportC.zig").df;
const c = @import("Commands.zig").Command;

pub const MAXPULLDOWNS  = 15;
pub const MAXSELECTIONS  = 20;
pub const MAXCASCADES = 3;  // nesting level of cascaded menus
pub const SEPCHAR = "\xc4";
pub const Separator = .{SEPCHAR,        c.ID_NULL,          0,     Default};

pub const PopDownAttrib = packed struct {
    INACTIVE: bool = false,
    CHECKED: bool = false,
    TOGGLE: bool = false,
    CASCADED: bool = false,
};
pub const Default:PopDownAttrib = .{};
pub const Inactive:PopDownAttrib = .{.INACTIVE = true};
pub const Toggle:PopDownAttrib = .{.TOGGLE = true};
pub const Cascaded:PopDownAttrib = .{.CASCADED = true};

// for editbox.c
export const ID_DELETETEXT:c_int = @intFromEnum(c.ID_DELETETEXT);
export const ID_HELPTEXT:c_int = @intFromEnum(c.ID_HELPTEXT);

// ----------- popdown menu selection structure
//       one for each selection on a popdown menu ---------
pub const PopDown = struct {
    SelectionTitle:?[]const u8 = null, // title of the selection
    ActionId:c = c.ID_NULL,            // the command executed
    Accelerator:c_int = 0,             // the accelerator key
    Attrib:PopDownAttrib = .{},        // INACTIVE | CHECKED | TOGGLE | CASCADED
    help:?[:0]const u8 = null,         // Help mnemonic
};

// ----------- popdown menu structure
//       one for each popdown menu on the menu bar --------
pub const MENU = struct {
    Title:?[]const u8 = null,      // title on the menu bar
    PrepMenu:?*const fn (w: ?*anyopaque, mnu: *MENU) void = null, // function
    StatusText:?[]const u8 = null, // text for the status bar
    CascadeId:c_int = 0,           // command id of cascading selection
    Selection:c_int = 0,           // most recent selection
    Selections:[MAXSELECTIONS+1]PopDown,
};

// ----- one for each menu bar -----
pub const MBAR = struct {
    ActiveSelection:c_int,
    PullDown:[MAXPULLDOWNS+1]MENU,
};

// ------------- the System Menu ---------------------
pub var SystemMenu:MBAR = buildMenuBar(.{
    .{"System Menu", null, null, -1, .{
            .{"~Restore",     c.ID_SYSRESTORE,    0,     Default},
            .{"~Move",        c.ID_SYSMOVE,       0,     Default},
            .{"~Size",        c.ID_SYSSIZE,       0,     Default},
            .{"Mi~nimize",    c.ID_SYSMINIMIZE,   0,     Default},
            .{"Ma~Ximize",    c.ID_SYSMAXIMIZE,   0,     Default},
            Separator,
            .{"~Close",       c.ID_SYSCLOSE,      0,     Default},
        },
    },
    
});

pub fn buildMenuBar(comptime pulldowns:anytype) MBAR {
    const result:MBAR = .{
        .ActiveSelection = -1,
        .PullDown = buildMenu(pulldowns),
    };

    return result;
}

fn buildMenu(comptime pulldowns:anytype) [MAXPULLDOWNS+1]MENU {
    var result = [_]MENU{
         .{
             .Title = null,
             .Selection = 0,
             .Selections = [_]PopDown{ // this will be replace later. need better solution.
                 .{
                     .SelectionTitle = null,
                     .ActionId = c.ID_NULL,
                     .Accelerator = 0,
                     .Attrib = .{},
                     .help = null,
                 }
             }**(MAXSELECTIONS+1),
          }
    }**(MAXPULLDOWNS+1);

    inline for(pulldowns, 0..) |pulldown, idx| {
        var title:?[]const u8 = undefined;
        var PrepMenu:?*const fn (w: ?*anyopaque, mnu: *MENU) void = undefined;
        var StatusText:?[]const u8 = undefined;
        var CascadeId:c_int = -1;
        title, PrepMenu, StatusText, CascadeId, _ = pulldown;

        result[idx] = .{
            .Title = title,
            .PrepMenu = PrepMenu,
            .StatusText = StatusText,
            .CascadeId = CascadeId,
            .Selections = buildPopDown(pulldown[4])
        };
    }
  
    return result;
}

fn buildPopDown(comptime popdowns:anytype) [MAXSELECTIONS+1]PopDown {
    var result = [_]PopDown{
        .{
            .SelectionTitle = null,
            .ActionId = c.ID_NULL,
            .Accelerator = 0,
            .Attrib = .{},
            .help = null,
        }
    }**(MAXSELECTIONS+1);


    inline for(popdowns, 0..) |popdown, idx| {
        var SelectTitle: ?[]const u8 = undefined;
        var ActionId: c = undefined;
        var Accelerator: c_int = undefined;
        var Attrib:PopDownAttrib = undefined;
        SelectTitle, ActionId, Accelerator, Attrib = popdown;


        result[idx] = .{
            .SelectionTitle = SelectTitle,
            .ActionId = ActionId,
            .Accelerator = Accelerator,
            .Attrib = Attrib,
            .help = if (ActionId == c.ID_NULL) null else @tagName(ActionId),
        };
    }

    return result;
}
