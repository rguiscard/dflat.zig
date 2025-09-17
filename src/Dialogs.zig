const std = @import("std");
const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");
const c = @import("Commands.zig").Command;
const GapBuffer = @import("GapBuffer.zig");

pub const MAXCONTROLS = 30;
pub const MAXRADIOS = 20;

// -------- dialog box and control window structure -------
pub const DIALOGWINDOW = struct  {
    title:?[:0]const u8,  // window title
    x:c_int,              // relative coordinates
    y:c_int,
    h:c_int,              // size
    w:c_int,
};

// ------ one of these for each control window -------
pub const CTLWINDOW = struct {
    dwnd:DIALOGWINDOW = .{.title = null, .x = 0, .y = 0, .h = 0, .w = 0},
    Class:df.CLASS = 0,           // LISTBOX, BUTTON, etc
    itext:?[:0]u8 = null,         // initialized text
    itext_allocated:bool = false, // itext is allocated in heap (true) or in stack (false)
    igapbuf:?*GapBuffer = null,   // initialized text in gapbuffer
    command:c = c.ID_NULL,        // command code
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
        .{df.TEXT,     "~Filename:",    3, 1, 1, 9, c.ID_FILENAME,  },
        .{df.EDITBOX,  null,           13, 1, 1,40, c.ID_FILENAME,  },
        .{df.TEXT,     null        ,    3, 3, 1,50, c.ID_PATH,      },
        .{df.TEXT,     "~Directories:", 3, 5, 1,12, c.ID_DIRECTORY, },
        .{df.LISTBOX,  null,            3, 6,10,14, c.ID_DIRECTORY, },
        .{df.TEXT,     "F~iles:",      19, 5, 1, 6, c.ID_FILES,     },
        .{df.LISTBOX,  null,           19, 6,10,24, c.ID_FILES,     },
        .{df.BUTTON,   "   ~OK   ",    46, 7, 1, 8, c.ID_OK,        },
        .{df.BUTTON,   " ~Cancel ",    46,10, 1, 8, c.ID_CANCEL,    },
        .{df.BUTTON,   "  ~Help  ",    46,13, 1, 8, c.ID_HELP,      },
    },
);

// -------------- the Save As dialog box ---------------
pub var SaveAs:DBOX = buildDialog(
    "SaveAs",
    .{"Save As", -1, -1, 19, 57},
    .{
        .{df.TEXT,     "~Filename:",    3, 1, 1, 9, c.ID_FILENAME,  },
        .{df.EDITBOX,  null,           13, 1, 1,40, c.ID_FILENAME,  },
        .{df.TEXT,     null        ,    3, 3, 1,50, c.ID_PATH,      },
        .{df.TEXT,     "~Directories:", 3, 5, 1,12, c.ID_DIRECTORY, },
        .{df.LISTBOX,  null,            3, 6,10,14, c.ID_DIRECTORY, },
        .{df.TEXT,     "F~iles:",      19, 5, 1, 6, c.ID_FILES,     },
        .{df.LISTBOX,  null,           19, 6,10,24, c.ID_FILES,     },
        .{df.BUTTON,   "   ~OK   ",    46, 7, 1, 8, c.ID_OK,        },
        .{df.BUTTON,   " ~Cancel ",    46,10, 1, 8, c.ID_CANCEL,    },
        .{df.BUTTON,   "  ~Help  ",    46,13, 1, 8, c.ID_HELP,      },
    },
);

// -------------- the Search Text dialog box ---------------
pub var SearchTextDB:DBOX = buildDialog(
    "SearchTextDB",
    .{"Search Text", -1, -1, 9, 48},
    .{
        .{df.TEXT,     "~Search for:",             2, 1, 1, 11, c.ID_SEARCHFOR, },
        .{df.EDITBOX,  null,                      14, 1, 1, 29, c.ID_SEARCHFOR, },
        .{df.TEXT,     "~Match upper/lower case:", 2, 3, 1, 23, c.ID_MATCHCASE, },
        .{df.CHECKBOX, null,                      26, 3, 1,  3, c.ID_MATCHCASE, },
        .{df.BUTTON,   "   ~OK   ",                7, 5, 1,  8, c.ID_OK,        },
        .{df.BUTTON,   " ~Cancel ",               19, 5, 1,  8, c.ID_CANCEL,    },
        .{df.BUTTON,   "  ~Help  ",               31, 5, 1,  8, c.ID_HELP,      },
    },
);

// -------------- the Replace Text dialog box ---------------
pub var ReplaceTextDB:DBOX = buildDialog(
    "ReplaceTextDB",
    .{"Replace Text", -1, -1, 12, 50},
    .{
        .{df.TEXT,     "~Search for:",              2, 1, 1, 11, c.ID_SEARCHFOR,    },
        .{df.EDITBOX,  null,                       16, 1, 1, 29, c.ID_SEARCHFOR,    },
        .{df.TEXT,     "~Replace for:",             2, 3, 1, 13, c.ID_REPLACEWITH,  },
        .{df.EDITBOX,  null,                       16, 3, 1, 29, c.ID_REPLACEWITH,  },
        .{df.TEXT,     "~Match upper/lower case:",  2, 5, 1, 23, c.ID_MATCHCASE,    },
        .{df.CHECKBOX, null,                       26, 5, 1,  3, c.ID_MATCHCASE,    },
        .{df.TEXT,     "Replace ~Every Match:",     2, 6, 1, 23, c.ID_REPLACEALL,   },
        .{df.CHECKBOX, null,                       26, 6, 1,  3, c.ID_REPLACEALL,   },
        .{df.BUTTON,   "   ~OK   ",                 7, 8, 1,  8, c.ID_OK,           },
        .{df.BUTTON,   " ~Cancel ",                20, 8, 1,  8, c.ID_CANCEL,       },
        .{df.BUTTON,   "  ~Help  ",                33, 8, 1,  8, c.ID_HELP,         },
    },
);

// -------------- generic message dialog box ---------------
pub var MsgBox:DBOX = buildDialog(
    "MsgBox",
    .{null, -1, -1, 0, 0},
    .{
        .{df.TEXT,   null, 1, 1, 0, 0, c.ID_NULL,   },
        .{df.BUTTON, null, 0, 0, 1, 8, c.ID_OK,     },
        .{0,         null, 0, 0, 1, 8, c.ID_CANCEL, },
    },
);

// ----------- InputBox Dialog Box ------------
pub var InputBoxDB:DBOX = buildDialog(
    "InputBoxDB",
    .{null, -1, -1, 9, 0},
    .{
        .{df.TEXT,    null,       1, 1, 1, 0, c.ID_NULL,       },
        .{df.EDITBOX, null,       1, 3, 1, 0, c.ID_INPUTTEXT,  },
        .{df.BUTTON,  "   ~OK   ",0, 5, 1, 8, c.ID_OK,         },
        .{df.BUTTON,  " ~Cancel ",0, 5, 1, 8, c.ID_CANCEL,     },
    },
);

// ----------- SliderBox Dialog Box -------------
pub var SliderBoxDB:DBOX = buildDialog(
    "SliderBoxDB",
    .{null, -1, -1, 9, 0},
    .{
        .{df.TEXT,    null,       0, 1, 1, 0, c.ID_NULL,    },
        .{df.TEXT,    null,       0, 3, 1, 0, c.ID_NULL,    },
        .{df.BUTTON,  " Cancel ", 0, 5, 1, 8, c.ID_CANCEL,  },
    },
);

// ------------ Display dialog box --------------
pub var Display:DBOX = buildDialog(
    "Display",
    .{"Display", -1, -1, 19, 35},
    .{
        .{df.BOX,         "Window",     7, 1, 6,20, c.ID_NULL,     },
        .{df.CHECKBOX,    null,         9, 2, 1, 3, c.ID_TITLE,    },
        .{df.TEXT,        "~Title",    15, 2, 1, 5, c.ID_TITLE,    },
        .{df.CHECKBOX,    null,         9, 3, 1, 3, c.ID_BORDER,   },
        .{df.TEXT,        "~Border",   15, 3, 1, 6, c.ID_BORDER ,  },
        .{df.CHECKBOX,    null,         9, 4, 1, 3, c.ID_STATUSBAR,},
        .{df.TEXT,        "Status bar",15, 4, 1,10, c.ID_STATUSBAR,},
        .{df.CHECKBOX,    null,         9, 5, 1, 3, c.ID_TEXTURE,  },
        .{df.TEXT,        "Te~xture",  15, 5, 1, 7, c.ID_TEXTURE,  },
        .{df.BOX,         "Colors",     7, 8, 5,20, c.ID_NULL,     },
        .{df.RADIOBUTTON, null,         9, 9, 1, 3, c.ID_COLOR,    },
        .{df.TEXT,        "Co~lor",    13, 9, 1, 5, c.ID_COLOR,    },
        .{df.RADIOBUTTON, null,         9,10, 1, 3, c.ID_MONO,     },
        .{df.TEXT ,       "~Mono",     13,10, 1, 4, c.ID_MONO,     },
        .{df.RADIOBUTTON, null,         9,11, 1, 3, c.ID_REVERSE,  },
        .{df.TEXT,        "~Reverse",  13,11, 1, 7, c.ID_REVERSE,  },
        .{df.BUTTON,   "   ~OK   ",     2,15, 1, 8, c.ID_OK,       },
        .{df.BUTTON,   " ~Cancel ",    12,15, 1, 8, c.ID_CANCEL,   },
        .{df.BUTTON,   "  ~Help  ",    22,15, 1, 8, c.ID_HELP,     },
    },
);

// ------------ Windows dialog box -------------- 
pub var Windows:DBOX = buildDialog(
    "Windows",
    .{"Windows", -1, -1, 19, 24},
    .{
        .{df.LISTBOX, null,        1, 1,11,20, c.ID_WINDOWLIST,  },
        .{df.BUTTON,  "   ~OK   ", 2,13, 1, 8, c.ID_OK,          },
        .{df.BUTTON,  " ~Cancel ",12,13, 1, 8, c.ID_CANCEL,      },
        .{df.BUTTON,  "  ~Help  ", 7,15, 1, 8, c.ID_HELP,        },
    },
);

// ------------ Message Log dialog box --------------
pub var Log:DBOX = buildDialog(
    "Log",
    .{"D-Flat Message Log", -1, -1,18,41},
    .{
        .{df.TEXT,    "~Messages",10, 1, 1, 8, c.ID_LOGLIST, },
        .{df.LISTBOX, null,        1, 2,14,26, c.ID_LOGLIST, },
        .{df.TEXT,    "~Logging:",29, 4, 1,10, c.ID_LOGGING, },
        .{df.CHECKBOX,null,       31, 5, 1, 3, c.ID_LOGGING, },
        .{df.BUTTON,  "   ~OK   ",29, 7, 1, 8, c.ID_OK,      },
        .{df.BUTTON,  " ~Cancel ",29,10, 1, 8, c.ID_CANCEL,  },
        .{df.BUTTON,  "  ~Help  ",29,13, 1, 8, c.ID_HELP,    },
    },
);

// ------------ the Help window dialog box --------------
// This need to be mutable because it will be modified at runtime.
pub var HelpBox:DBOX = buildDialog(
    "HelpBox",
    .{null, -1, -1,0,45},
    .{
        .{df.TEXTBOX, null,        1, 1, 0,40, c.ID_HELPTEXT, },
        .{df.BUTTON,  "  ~Close ", 0, 0, 1, 8, c.ID_CANCEL,   },
        .{df.BUTTON,  "  ~Back  ",10, 0, 1, 8, c.ID_BACK,     },
        .{df.BUTTON,  "<< ~Prev ",20, 0, 1, 8, c.ID_PREV,     },
        .{df.BUTTON,  " ~Next >>",30, 0, 1, 8, c.ID_NEXT,     },
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
    var result = [_]CTLWINDOW{.{.Class = 0}}**(MAXCONTROLS+1);
    inline for(controls, 0..) |control, idx| {
        var ty: c_int = undefined ;
        var tx: ?[:0]const u8 = undefined;
        var x: c_int = undefined;
        var y: c_int = undefined;
        var h: c_int = undefined;
        var w: c_int = undefined;
        var cc: c = undefined;
        ty, tx, x, y, h, w, cc = control;

        const itext = if ((ty == df.EDITBOX) or (ty == df.COMBOBOX)) null else if (tx) |t| @constCast(t) else null;
        result[idx] = .{
            .dwnd = .{.title = null, .x = x, .y = y, .h = h, .w = w},
            .Class = ty,
            .itext = itext,
            .itext_allocated = false, // everything is in stack at this poing.
            .command = cc,
            .help = if (cc == c.ID_NULL) null else @tagName(cc),
            .isetting = if (ty == df.BUTTON) df.ON else df.OFF,
            .setting = df.OFF,
            .win = null,
        };
    }

    return result;
}

