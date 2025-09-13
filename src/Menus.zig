const std = @import("std");
const df = @import("ImportC.zig").df;

pub const MAXPULLDOWNS  = 15;
pub const MAXSELECTIONS  = 20;
pub const MAXCASCADES = 3;  // nesting level of cascaded menus
pub const SEPCHAR = "\xc4";

// ----------- popdown menu structure
//       one for each popdown menu on the menu bar --------
pub const MENU = struct {
    Title:[*c]u8 = null,           // title on the menu bar
    PrepMenu:?*const fn (w: ?*anyopaque, mnu: *MENU) void = null, // function
    StatusText:[*c]u8 = null,      // text for the status bar
    CascadeId:c_int = 0,           // command id of cascading selection
    Selection:c_int = 0,           // most recent selection
    Selections:[MAXSELECTIONS+1]df.PopDown,
};

// ----- one for each menu bar -----
pub const MBAR = struct {
    ActiveSelection:c_int,
    PullDown:[MAXPULLDOWNS+1]MENU,
};

// ------------- the System Menu ---------------------
pub var SystemMenu:MBAR = buildMenuBar(.{
    .{"System Menu", null, null, -1, .{
            .{"~Restore",     df.ID_SYSRESTORE,    0,     0,     "ID_SYSRESTORE" },
            .{"~Move",        df.ID_SYSMOVE,       0,     0,     "ID_SYSMOVE"    },
            .{"~Size",        df.ID_SYSSIZE,       0,     0,     "ID_SYSMOVE"    },
            .{"Mi~nimize",    df.ID_SYSMINIMIZE,   0,     0,     "ID_SYSMINIMIZE"},
            .{"Ma~Ximize",    df.ID_SYSMAXIMIZE,   0,     0,     "ID_SYSMAXIMIZE"},
            .{SEPCHAR,     0,                   0,     0,     null            },
            .{"~Close",       df.ID_SYSCLOSE,      0,     0,     "ID_SYSCLOSE"   },
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
             .Selections = [_]df.PopDown{ // this will be replace later. need better solution.
                 .{
                     .SelectionTitle = null,
                     .ActionId = 0,
                     .Accelerator = 0,
                     .Attrib = 0,
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
            .Title = if (title) |t| @constCast(t.ptr) else null,
            .PrepMenu = PrepMenu,
            .StatusText = if (StatusText) |s| @constCast(s.ptr) else null,
            .CascadeId = CascadeId,
            .Selections = buildPopDown(pulldown[4])
        };
    }
  
    return result;
}

fn buildPopDown(comptime popdowns:anytype) [MAXSELECTIONS+1]df.PopDown {
    var result = [_]df.PopDown{
        .{
            .SelectionTitle = null,
            .ActionId = 0,
            .Accelerator = 0,
            .Attrib = 0,
            .help = null,
        }
    }**(MAXSELECTIONS+1);


    inline for(popdowns, 0..) |popdown, idx| {
        var SelectTitle: ?[]const u8 = undefined;
        var ActionId: c_int= undefined;
        var Accelerator: c_int = undefined;
        var Attrib: c_int = undefined;
        var help:?[]const u8= undefined;
        SelectTitle, ActionId, Accelerator, Attrib, help = popdown;

        result[idx] = .{
            .SelectionTitle = if (SelectTitle) |t| @constCast(t.ptr) else null,
            .ActionId = ActionId,
            .Accelerator = Accelerator,
            .Attrib = Attrib,
            .help = if (help) |name| @constCast(name.ptr) else null,
        };
    }

    return result;
}
