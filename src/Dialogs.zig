const std = @import("std");
const df = @import("ImportC.zig").df;

// This needs to be var because some values will change.

// -------------- the File Open dialog box --------------- 
pub export var FileOpen:df.DBOX = buildDialog(
    "FileOpen",
    .{"Open File", -1, -1, 19, 57},
    .{
        .{df.TEXT,     "~Filename:",    3, 1, 1, 9, df.ID_FILENAME,  "ID_FILENAME" },
        .{df.EDITBOX,  null,           13, 1, 1,40, df.ID_FILENAME,  "ID_FILENAME" },
        .{df.TEXT,     null        ,    3, 3, 1,50, df.ID_PATH,      "ID_PATH"     },
        .{df.TEXT,     "~Directories:", 3, 5, 1,12, df.ID_DIRECTORY, "ID_DIRECTORY"},
        .{df.LISTBOX,  null,            3, 6,10,14, df.ID_DIRECTORY, "ID_DIRECTORY"},
        .{df.TEXT,     "F~iles:",      19, 5, 1, 6, df.ID_FILES,     "ID_FILES"    },
        .{df.LISTBOX,  null,           19, 6,10,24, df.ID_FILES,     "ID_FILES"    },
        .{df.BUTTON,   "   ~OK   ",    46, 7, 1, 8, df.ID_OK,        "ID_OK"       },
        .{df.BUTTON,   " ~Cancel ",    46,10, 1, 8, df.ID_CANCEL,    "ID_CANCEL"   },
        .{df.BUTTON,   "  ~Help  ",    46,13, 1, 8, df.ID_HELP,      "ID_HELP"     },
    },
);

// -------------- the Save As dialog box ---------------
pub export var SaveAs:df.DBOX = buildDialog(
    "SaveAs",
    .{"Save As", -1, -1, 19, 57},
    .{
        .{df.TEXT,     "~Filename:",    3, 1, 1, 9, df.ID_FILENAME,  "ID_FILENAME" },
        .{df.EDITBOX,  null,           13, 1, 1,40, df.ID_FILENAME,  "ID_FILENAME" },
        .{df.TEXT,     null        ,    3, 3, 1,50, df.ID_PATH,      "ID_PATH"     },
        .{df.TEXT,     "~Directories:", 3, 5, 1,12, df.ID_DIRECTORY, "ID_DIRECTORY"},
        .{df.LISTBOX,  null,            3, 6,10,14, df.ID_DIRECTORY, "ID_DIRECTORY"},
        .{df.TEXT,     "F~iles:",      19, 5, 1, 6, df.ID_FILES,     "ID_FILES"    },
        .{df.LISTBOX,  null,           19, 6,10,24, df.ID_FILES,     "ID_FILES"    },
        .{df.BUTTON,   "   ~OK   ",    46, 7, 1, 8, df.ID_OK,        "ID_OK"       },
        .{df.BUTTON,   " ~Cancel ",    46,10, 1, 8, df.ID_CANCEL,    "ID_CANCEL"   },
        .{df.BUTTON,   "  ~Help  ",    46,13, 1, 8, df.ID_HELP,      "ID_HELP"     },
    },
);

// -------------- the Search Text dialog box ---------------
pub export var SearchTextDB:df.DBOX = buildDialog(
    "SearchTextDB",
    .{"Search Text", -1, -1, 9, 48},
    .{
        .{df.TEXT,     "~Search for:",             2, 1, 1, 11, df.ID_SEARCHFOR, "ID_SEARCHFOR"},
        .{df.EDITBOX,  null,                      14, 1, 1, 29, df.ID_SEARCHFOR, "ID_SEARCHFOR"},
        .{df.TEXT,     "~Match upper/lower case:", 2, 3, 1, 23, df.ID_MATCHCASE, "ID_MATCHCASE"},
        .{df.CHECKBOX, null,                      26, 3, 1,  3, df.ID_MATCHCASE, "ID_MATCHCASE"},
        .{df.BUTTON,   "   ~OK   ",                7, 5, 1,  8, df.ID_OK,        "ID_OK"       },
        .{df.BUTTON,   " ~Cancel ",               19, 5, 1,  8, df.ID_CANCEL,    "ID_CANCEL"   },
        .{df.BUTTON,   "  ~Help  ",               31, 5, 1,  8, df.ID_HELP,      "ID_HELP"     },
    },
);

// -------------- the Replace Text dialog box ---------------
pub export var ReplaceTextDB:df.DBOX = buildDialog(
    "ReplaceTextDB",
    .{"Replace Text", -1, -1, 12, 50},
    .{
        .{df.TEXT,     "~Search for:",              2, 1, 1, 11, df.ID_SEARCHFOR,   "ID_SEARCHFOR"  },
        .{df.EDITBOX,  null,                       16, 1, 1, 29, df.ID_SEARCHFOR,   "ID_SEARCHFOR"  },
        .{df.TEXT,     "~Replace for:",             2, 3, 1, 13, df.ID_REPLACEWITH, "ID_REPLACEWITH"},
        .{df.EDITBOX,  null,                       16, 3, 1, 29, df.ID_REPLACEWITH, "ID_REPLACEWITH"},
        .{df.TEXT,     "~Match upper/lower case:",  2, 5, 1, 23, df.ID_MATCHCASE,   "ID_MATCHCASE"  },
        .{df.CHECKBOX, null,                       26, 5, 1,  3, df.ID_MATCHCASE,   "ID_MATCHCASE"  },
        .{df.TEXT,     "Replace ~Every Match:",     2, 6, 1, 23, df.ID_REPLACEALL,  "ID_REPLACEALL" },
        .{df.CHECKBOX, null,                       26, 6, 1,  3, df.ID_REPLACEALL,  "ID_REPLACEALL" },
        .{df.BUTTON,   "   ~OK   ",                 7, 8, 1,  8, df.ID_OK,          "ID_OK"         },
        .{df.BUTTON,   " ~Cancel ",                20, 8, 1,  8, df.ID_CANCEL,      "ID_CANCEL"     },
        .{df.BUTTON,   "  ~Help  ",                33, 8, 1,  8, df.ID_HELP,        "ID_HELP"       },
    },
);

// -------------- generic message dialog box ---------------
pub export var MsgBox:df.DBOX = buildDialog(
    "MsgBox",
    .{null, -1, -1, 0, 0},
    .{
        .{df.TEXT,   null, 1, 1, 0, 0, 0,            null       },
        .{df.BUTTON, null, 0, 0, 1, 8, df.ID_OK,     "ID_OK"    },
        .{0,         null, 0, 0, 1, 8, df.ID_CANCEL, "ID_CANCEL"},
    },
);

// ------------ Display dialog box --------------
pub var Display:df.DBOX = buildDialog(
    "Display",
    .{"Display", -1, -1, 19, 35},
    .{
        .{df.BOX,      "Window",  7, 1, 6,20, 0,            null          },
        .{df.CHECKBOX, null,      9, 2, 1, 3, df.ID_TITLE,  "ID_TITLE"    },
        .{df.TEXT,     "~Title", 15, 2, 1, 5, df.ID_TITLE,  "ID_TITLE"    },
        .{df.CHECKBOX, null,      9, 3, 1, 3, df.ID_BORDER, "ID_BORDER"   },
        .{df.TEXT,     "~Border",15, 3, 1, 6, df.ID_BORDER, "ID_BORDER"   },
        .{df.CHECKBOX, null,      9, 4, 1, 3, df.ID_STATUSBAR, "ID_STATUSBAR"   },
        .{df.TEXT,     "Status bar",15, 4, 1,10, df.ID_STATUSBAR, "ID_STATUSBAR"   },
        .{df.CHECKBOX, null,       9, 5, 1, 3, df.ID_TEXTURE, "ID_TEXTURE"   },
        .{df.TEXT,     "Te~xture",15, 5, 1, 7, df.ID_TEXTURE, "ID_TEXTURE"   },
        .{df.BOX,         "Colors",   7, 8, 5,20, 0,            null          },
        .{df.RADIOBUTTON, null,       9, 9, 1, 3, df.ID_COLOR, "ID_COLOR"   },
        .{df.TEXT,        "Co~lor",  13, 9, 1, 5, df.ID_COLOR, "ID_COLOR"   },
        .{df.RADIOBUTTON, null,       9,10, 1, 3, df.ID_MONO,  "ID_MONO"   },
        .{df.TEXT ,       "~Mono",   13,10, 1, 4, df.ID_MONO,  "ID_MONO"   },
        .{df.RADIOBUTTON, null,       9,11, 1, 3, df.ID_REVERSE,  "ID_REVERSE"   },
        .{df.TEXT,        "~Reverse",13,11, 1, 7, df.ID_REVERSE,  "ID_REVERSE"   },
        .{df.BUTTON,   "   ~OK   ",   2,15, 1,  8, df.ID_OK,          "ID_OK"         },
        .{df.BUTTON,   " ~Cancel ",  12,15, 1,  8, df.ID_CANCEL,      "ID_CANCEL"     },
        .{df.BUTTON,   "  ~Help  ",  22,15, 1,  8, df.ID_HELP,        "ID_HELP"       },
    },
);

// ------------ Message Log dialog box --------------
pub const Log:df.DBOX = buildDialog(
    "Log",
    .{"D-Flat Message Log", -1, -1,18,41},
    .{
        .{df.TEXT,    "~Messages",10, 1, 1, 8, df.ID_LOGLIST, "ID_LOGLIST"},
        .{df.LISTBOX, null,        1, 2,14,26, df.ID_LOGLIST, "ID_LOGLIST"},
        .{df.TEXT,    "~Logging:",29, 4, 1,10, df.ID_LOGGING, "ID_LOGGING"},
        .{df.CHECKBOX,null,       31, 5, 1, 3, df.ID_LOGGING, "ID_LOGGING"},
        .{df.BUTTON,  "   ~OK   ",29, 7, 1, 8, df.ID_OK,      "ID_OK"     },
        .{df.BUTTON,  " ~Cancel ",29,10, 1, 8, df.ID_CANCEL,  "ID_CANCEL" },
        .{df.BUTTON,  "  ~Help  ",29,13, 1, 8, df.ID_HELP,    "ID_HELP"   },
    },
);

// ------------ the Help window dialog box --------------
// This need to be mutable because it will be modified at runtime.
pub export var HelpBox:df.DBOX = buildDialog( // remove export after porting other c code
    "HelpBox",
    .{null, -1, -1,0,45},
    .{
        .{df.TEXTBOX, null,        1, 1, 0,40, df.ID_HELPTEXT, "ID_HELPTEXT"},
        .{df.BUTTON,  "  ~Close ", 0, 0, 1, 8, df.ID_CANCEL,   "ID_CANCEL"  },
        .{df.BUTTON,  "  ~Back  ",10, 0, 1, 8, df.ID_BACK,     "ID_BACK"    },
        .{df.BUTTON,  "<< ~Prev ",20, 0, 1, 8, df.ID_PREV,     "ID_PREV"    },
        .{df.BUTTON,  " ~Next >>",30, 0, 1, 8, df.ID_NEXT,     "ID_NEXT"    },
    },
);

fn buildDialog(comptime help:[]const u8, comptime window:anytype, comptime controls:anytype) df.DBOX {
    var result:df.DBOX = undefined;

    var ttl: ?[]const u8 = undefined;
    var x: c_int = undefined;
    var y: c_int = undefined;
    var h: c_int = undefined;
    var w: c_int = undefined;
    ttl, x, y, h, w = window;

    result = .{
        .HelpName = @constCast(help.ptr),
        .dwnd = .{
            .title = if (ttl) |t| @constCast(t.ptr) else null,
            .x = x,
            .y = y,
            .h = h,
            .w = w,
        },
        .ctl = buildControls(controls),
    };

    return result;
}

fn buildControls(comptime controls:anytype) [df.MAXCONTROLS+1]df.CTLWINDOW {
    var result:[df.MAXCONTROLS+1]df.CTLWINDOW = undefined;
    inline for(0..(df.MAXCONTROLS+1)) |idx| {
        result[idx] = .{
            .Class = 0, // it use Class == 0 to indicate end of available controls
        };
    }
    inline for(controls, 0..) |control, idx| {
        var ty: c_int = undefined ;
        var tx: ?[]const u8 = undefined;
        var x: c_int = undefined;
        var y: c_int = undefined;
        var h: c_int = undefined;
        var w: c_int = undefined;
        var c: c_int = undefined;
        var help: ?[]const u8 = undefined;
        ty, tx, x, y, h, w, c, help = control;

        const itext = if ((ty == df.EDITBOX) or (ty == df.COMBOBOX)) null else if (tx) |t| @constCast(t.ptr) else null;
        result[idx] = .{
            .dwnd = .{.title = null, .x = x, .y = y, .h = h, .w = w},
            .Class = ty,
            .itext = itext,
            .command = c,
            .help = if (help) |name| @constCast(name.ptr) else null,
            .isetting = if (ty == df.BUTTON) df.ON else df.OFF,
            .setting = df.OFF,
            .wnd = null,
        };
    }

    return result;
}

