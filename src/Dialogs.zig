const std = @import("std");
const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");
const c = @import("Commands.zig").Command;
const CLASS = @import("Classes.zig").CLASS;
const k = CLASS; // abbreviation
const GapBuffer = @import("GapBuffer.zig");

pub const MAXCONTROLS = 30;
pub const MAXRADIOS = 20;

// -------- dialog box and control window structure -------
pub const DIALOGWINDOW = struct  {
    title:?[:0]const u8,  // window title
    x:isize,              // relative coordinates
    y:isize,
    h:isize,              // size
    w:isize,
};

// ------ one of these for each control window -------
pub const CTLWINDOW = struct {
    dwnd:DIALOGWINDOW = .{.title = null, .x = 0, .y = 0, .h = 0, .w = 0},
    Class:CLASS = k.NORMAL,   // LISTBOX, BUTTON, etc
//    itext:?[:0]u8 = null,         // initialized text
//    itext_allocated:bool = false, // itext is allocated in heap (true) or in stack (false)
    dtext:?[:0]u8 = null,         // default text, to be copied to gapbuffer later
    igapbuf:?*GapBuffer = null,   // initialized text in gapbuffer
    command:c = .ID_NULL,        // command code
    help:?[:0]const u8 = null,    // help mnemonic
    isetting:df.BOOL = df.OFF,    // initially ON or OFF
    setting:df.BOOL = df.OFF,     // ON or OFF
    win:?*Window = null,          // window handle
};

// --------- one of these for each dialog box -------
pub const DBOX = struct {
    HelpName:[:0]const u8,
    dwnd:DIALOGWINDOW,
    ctl:[MAXCONTROLS+1]CTLWINDOW,
};

// This needs to be var because some values will change.

// -------------- the File Open dialog box --------------- 
pub var FileOpen:DBOX = buildDialog(
    "FileOpen",
    .{"Open File", -1, -1, 19, 57},
    .{
        .{k.TEXT,     "~Filename:",    3, 1, 1, 9, .ID_FILENAME,  },
        .{k.EDITBOX,  null,           13, 1, 1,40, .ID_FILENAME,  },
        .{k.TEXT,     null        ,    3, 3, 1,50, .ID_PATH,      },
        .{k.TEXT,     "~Directories:", 3, 5, 1,12, .ID_DIRECTORY, },
        .{k.LISTBOX,  null,            3, 6,10,14, .ID_DIRECTORY, },
        .{k.TEXT,     "F~iles:",      19, 5, 1, 6, .ID_FILES,     },
        .{k.LISTBOX,  null,           19, 6,10,24, .ID_FILES,     },
        .{k.BUTTON,   "   ~OK   ",    46, 7, 1, 8, .ID_OK,        },
        .{k.BUTTON,   " ~Cancel ",    46,10, 1, 8, .ID_CANCEL,    },
        .{k.BUTTON,   "  ~Help  ",    46,13, 1, 8, .ID_HELP,      },
    },
);

// -------------- the Save As dialog box ---------------
pub var SaveAs:DBOX = buildDialog(
    "SaveAs",
    .{"Save As", -1, -1, 19, 57},
    .{
        .{k.TEXT,     "~Filename:",    3, 1, 1, 9, .ID_FILENAME,  },
        .{k.EDITBOX,  null,           13, 1, 1,40, .ID_FILENAME,  },
        .{k.TEXT,     null        ,    3, 3, 1,50, .ID_PATH,      },
        .{k.TEXT,     "~Directories:", 3, 5, 1,12, .ID_DIRECTORY, },
        .{k.LISTBOX,  null,            3, 6,10,14, .ID_DIRECTORY, },
        .{k.TEXT,     "F~iles:",      19, 5, 1, 6, .ID_FILES,     },
        .{k.LISTBOX,  null,           19, 6,10,24, .ID_FILES,     },
        .{k.BUTTON,   "   ~OK   ",    46, 7, 1, 8, .ID_OK,        },
        .{k.BUTTON,   " ~Cancel ",    46,10, 1, 8, .ID_CANCEL,    },
        .{k.BUTTON,   "  ~Help  ",    46,13, 1, 8, .ID_HELP,      },
    },
);

// -------------- the Search Text dialog box ---------------
pub var SearchTextDB:DBOX = buildDialog(
    "SearchTextDB",
    .{"Search Text", -1, -1, 9, 48},
    .{
        .{k.TEXT,     "~Search for:",             2, 1, 1, 11, .ID_SEARCHFOR, },
        .{k.EDITBOX,  null,                      14, 1, 1, 29, .ID_SEARCHFOR, },
        .{k.TEXT,     "~Match upper/lower case:", 2, 3, 1, 23, .ID_MATCHCASE, },
        .{k.CHECKBOX, null,                      26, 3, 1,  3, .ID_MATCHCASE, },
        .{k.BUTTON,   "   ~OK   ",                7, 5, 1,  8, .ID_OK,        },
        .{k.BUTTON,   " ~Cancel ",               19, 5, 1,  8, .ID_CANCEL,    },
        .{k.BUTTON,   "  ~Help  ",               31, 5, 1,  8, .ID_HELP,      },
    },
);

// -------------- the Replace Text dialog box ---------------
pub var ReplaceTextDB:DBOX = buildDialog(
    "ReplaceTextDB",
    .{"Replace Text", -1, -1, 12, 50},
    .{
        .{k.TEXT,     "~Search for:",              2, 1, 1, 11, .ID_SEARCHFOR,    },
        .{k.EDITBOX,  null,                       16, 1, 1, 29, .ID_SEARCHFOR,    },
        .{k.TEXT,     "~Replace for:",             2, 3, 1, 13, .ID_REPLACEWITH,  },
        .{k.EDITBOX,  null,                       16, 3, 1, 29, .ID_REPLACEWITH,  },
        .{k.TEXT,     "~Match upper/lower case:",  2, 5, 1, 23, .ID_MATCHCASE,    },
        .{k.CHECKBOX, null,                       26, 5, 1,  3, .ID_MATCHCASE,    },
        .{k.TEXT,     "Replace ~Every Match:",     2, 6, 1, 23, .ID_REPLACEALL,   },
        .{k.CHECKBOX, null,                       26, 6, 1,  3, .ID_REPLACEALL,   },
        .{k.BUTTON,   "   ~OK   ",                 7, 8, 1,  8, .ID_OK,           },
        .{k.BUTTON,   " ~Cancel ",                20, 8, 1,  8, .ID_CANCEL,       },
        .{k.BUTTON,   "  ~Help  ",                33, 8, 1,  8, .ID_HELP,         },
    },
);

// -------------- generic message dialog box ---------------
pub var MsgBox:DBOX = buildDialog(
    "MsgBox",
    .{null, -1, -1, 0, 0},
    .{
        .{k.TEXT,   null, 1, 1, 0, 0, .ID_NULL,   },
        .{k.BUTTON, null, 0, 0, 1, 8, .ID_OK,     },
        .{k.NORMAL, null, 0, 0, 1, 8, .ID_CANCEL, },
    },
);

// ----------- InputBox Dialog Box ------------
pub var InputBoxDB:DBOX = buildDialog(
    "InputBoxDB",
    .{null, -1, -1, 9, 0},
    .{
        .{k.TEXT,    null,       1, 1, 1, 0, .ID_NULL,       },
        .{k.EDITBOX, null,       1, 3, 1, 0, .ID_INPUTTEXT,  },
        .{k.BUTTON,  "   ~OK   ",0, 5, 1, 8, .ID_OK,         },
        .{k.BUTTON,  " ~Cancel ",0, 5, 1, 8, .ID_CANCEL,     },
    },
);

// ----------- SliderBox Dialog Box -------------
pub var SliderBoxDB:DBOX = buildDialog(
    "SliderBoxDB",
    .{null, -1, -1, 9, 0},
    .{
        .{k.TEXT,    null,       0, 1, 1, 0, .ID_NULL,    },
        .{k.TEXT,    null,       0, 3, 1, 0, .ID_NULL,    },
        .{k.BUTTON,  " Cancel ", 0, 5, 1, 8, .ID_CANCEL,  },
    },
);

// ------------ Display dialog box --------------
pub var Display:DBOX = buildDialog(
    "Display",
    .{"Display", -1, -1, 19, 35},
    .{
        .{k.BOX,         "Window",     7, 1, 6,20, .ID_NULL,     },
        .{k.CHECKBOX,    null,         9, 2, 1, 3, .ID_TITLE,    },
        .{k.TEXT,        "~Title",    15, 2, 1, 5, .ID_TITLE,    },
        .{k.CHECKBOX,    null,         9, 3, 1, 3, .ID_BORDER,   },
        .{k.TEXT,        "~Border",   15, 3, 1, 6, .ID_BORDER ,  },
        .{k.CHECKBOX,    null,         9, 4, 1, 3, .ID_STATUSBAR,},
        .{k.TEXT,        "Status bar",15, 4, 1,10, .ID_STATUSBAR,},
        .{k.CHECKBOX,    null,         9, 5, 1, 3, .ID_TEXTURE,  },
        .{k.TEXT,        "Te~xture",  15, 5, 1, 7, .ID_TEXTURE,  },
        .{k.BOX,         "Colors",     7, 8, 5,20, .ID_NULL,     },
        .{k.RADIOBUTTON, null,         9, 9, 1, 3, .ID_COLOR,    },
        .{k.TEXT,        "Co~lor",    13, 9, 1, 5, .ID_COLOR,    },
        .{k.RADIOBUTTON, null,         9,10, 1, 3, .ID_MONO,     },
        .{k.TEXT ,       "~Mono",     13,10, 1, 4, .ID_MONO,     },
        .{k.RADIOBUTTON, null,         9,11, 1, 3, .ID_REVERSE,  },
        .{k.TEXT,        "~Reverse",  13,11, 1, 7, .ID_REVERSE,  },
        .{k.BUTTON,   "   ~OK   ",     2,15, 1, 8, .ID_OK,       },
        .{k.BUTTON,   " ~Cancel ",    12,15, 1, 8, .ID_CANCEL,   },
        .{k.BUTTON,   "  ~Help  ",    22,15, 1, 8, .ID_HELP,     },
    },
);

// ------------ Windows dialog box -------------- 
pub var Windows:DBOX = buildDialog(
    "Windows",
    .{"Windows", -1, -1, 19, 24},
    .{
        .{k.LISTBOX, null,        1, 1,11,20, .ID_WINDOWLIST,  },
        .{k.BUTTON,  "   ~OK   ", 2,13, 1, 8, .ID_OK,          },
        .{k.BUTTON,  " ~Cancel ",12,13, 1, 8, .ID_CANCEL,      },
        .{k.BUTTON,  "  ~Help  ", 7,15, 1, 8, .ID_HELP,        },
    },
);

// ------------ Message Log dialog box --------------
pub var Log:DBOX = buildDialog(
    "Log",
    .{"D-Flat Message Log", -1, -1,18,41},
    .{
        .{k.TEXT,    "~Messages",10, 1, 1, 8, .ID_LOGLIST, },
        .{k.LISTBOX, null,        1, 2,14,26, .ID_LOGLIST, },
        .{k.TEXT,    "~Logging:",29, 4, 1,10, .ID_LOGGING, },
        .{k.CHECKBOX,null,       31, 5, 1, 3, .ID_LOGGING, },
        .{k.BUTTON,  "   ~OK   ",29, 7, 1, 8, .ID_OK,      },
        .{k.BUTTON,  " ~Cancel ",29,10, 1, 8, .ID_CANCEL,  },
        .{k.BUTTON,  "  ~Help  ",29,13, 1, 8, .ID_HELP,    },
    },
);

// ------------ the Help window dialog box --------------
// This need to be mutable because it will be modified at runtime.
pub var HelpBox:DBOX = buildDialog(
    "HelpBox",
    .{null, -1, -1,0,45},
    .{
        .{k.TEXTBOX, null,        1, 1, 0,40, .ID_HELPTEXT, },
        .{k.BUTTON,  "  ~Close ", 0, 0, 1, 8, .ID_CANCEL,   },
        .{k.BUTTON,  "  ~Back  ",10, 0, 1, 8, .ID_BACK,     },
        .{k.BUTTON,  "<< ~Prev ",20, 0, 1, 8, .ID_PREV,     },
        .{k.BUTTON,  " ~Next >>",30, 0, 1, 8, .ID_NEXT,     },
    },
);

fn buildDialog(comptime help:[:0]const u8, comptime window:anytype, comptime controls:anytype) DBOX {
    var result:DBOX = undefined;

    var ttl: ?[:0]const u8 = undefined;
    var x: c_int = undefined;
    var y: c_int = undefined;
    var h: c_int = undefined;
    var w: c_int = undefined;
    ttl, x, y, h, w = window;

    result = .{
        .HelpName = help,
        .dwnd = .{
            .title = if (ttl) |t| @constCast(t[0..:0]) else null,
            .x = x,
            .y = y,
            .h = h,
            .w = w,
        },
        .ctl = buildControls(controls),
    };

    return result;
}

fn buildControls(comptime controls:anytype) [MAXCONTROLS+1]CTLWINDOW {
    var result = [_]CTLWINDOW{.{.Class = k.NORMAL}}**(MAXCONTROLS+1); // NORMAL class is null
    inline for(controls, 0..) |control, idx| {
        var ty: CLASS = undefined;
        var tx: ?[:0]const u8 = undefined;
        var x: c_int = undefined;
        var y: c_int = undefined;
        var h: c_int = undefined;
        var w: c_int = undefined;
        var cc: c = undefined;
        ty, tx, x, y, h, w, cc = control;
//        const gapbuf:?*GapBuffer = null;

//        const itext = if ((ty == df.EDITBOX) or (ty == df.COMBOBOX)) null else if (tx) |t| @constCast(t) else null;
        const dtext = if ((ty == k.EDITBOX) or (ty == k.COMBOBOX)) null else if (tx) |t| @constCast(t) else null;
        result[idx] = .{
            .dwnd = .{.title = null, .x = x, .y = y, .h = h, .w = w},
            .Class = ty,
            .dtext = dtext,
//            .itext = itext,
//            .itext_allocated = false, // everything is in stack at this poing.
//            .igapbuf = gapbuf,
            .command = cc,
            .help = if (cc == .ID_NULL) null else @tagName(cc),
            .isetting = if (ty == k.BUTTON) df.ON else df.OFF,
            .setting = df.OFF,
            .win = null,
        };
    }

    return result;
}

