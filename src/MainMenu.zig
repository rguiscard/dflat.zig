const mSEPCHAR = mp.menus.SEPCHAR;
const Default = mp.menus.Default;
const Inactive = mp.menus.Inactive;
const Toggle = mp.menus.Toggle;
const Cascaded = mp.menus.Cascaded;

// --------------------- the main menu ---------------------
pub var MainMenu:mp.menus.MBAR = mp.menus.buildMenuBar(.{
    // --------------- the File popdown menu ----------------
    .{"~File", main.PrepFileMenu, "Read/write/print files. Go to DOS", -1, .{
            .{"~New",        .ID_NEW,       0,       Default    },
            .{"~Open...",    .ID_OPEN,      0,       Default    },
            menus.Separator,
            .{"~Save",       .ID_SAVE,      0,       Inactive   },
            .{"Save ~as...", .ID_SAVEAS,    0,       Inactive   },
            .{"D~elete",     .ID_DELETEFILE,0,       Inactive   },
            menus.Separator,
            .{"~Shell",      .ID_DOS,       0,       Default    },
            .{"E~xit",       .ID_EXIT,      df.ALT_X,Default    },
        },
    },
    .{"~Edit", main.PrepEditMenu, "Clipboard, delete text, paragraph", -1, .{
            .{"~Undo",       .ID_UNDO,      df.ALT_BS,   Inactive  },
            menus.Separator,
            .{"Cu~t",        .ID_CUT,       df.SHIFT_DEL,Inactive  },
            .{"~Copy",       .ID_COPY,      df.CTRL_INS, Inactive  },
            .{"~Paste",      .ID_PASTE,     df.SHIFT_INS,Inactive  },
            menus.Separator,
            .{"Cl~ear",      .ID_CLEAR,     0,           Inactive  },
            .{"~Delete",     .ID_DELETETEXT,df.DEL,      Inactive  },
            menus.Separator,
            .{"Pa~ragraph",  .ID_PARAGRAPH, df.ALT_P,    Inactive  },
        },
    },
    .{"~Search", main.PrepSearchMenu, "Search and replace", -1, .{
            .{"~Search...",   .ID_SEARCH,      0,     Inactive  },
            .{"~Replace...",  .ID_REPLACE,     0,     Inactive  },
            .{"~Next",        .ID_SEARCHNEXT,  df.F3, Inactive  },
        },
    },
    .{"~Utilities", null, "Utility programs", -1, .{
            .{"~Calendar",   .ID_CALENDAR,  0,  Default  },
            .{"~Bar chart",  .ID_BARCHART,  0,  Default  },
        },
    },
    // ------------- the Options popdown menu ---------------
    .{"~Options", null, "Editor and display options", -1, .{
            .{"~Display...",  .ID_DISPLAY,    0,       Default  },
            menus.Separator,
            .{"~Log messages",.ID_LOG,        df.ALT_L,Default  },
            menus.Separator,
            .{"~Insert",      .ID_INSERT,     df.INS,  Toggle   },
            .{"~Word wrap",   .ID_WRAP,       0,       Toggle   },
            .{"~Tabs ( )",    .ID_TABS,       0,       Cascaded },
            menus.Separator,
            .{"~Save options",.ID_SAVEOPTIONS,0,       Default  },
        },
    },
    // --------------- the Window popdown menu --------------
    .{"~Window", mp.app.PrepWindowMenu, "Select/close document windows", -1, .{
            .{null,     .ID_CLOSEALL,  0,  Default  },
            menus.Separator,
            .{null,     .ID_WINDOW,    0,  Default  },
            .{null,     .ID_WINDOW,    0,  Default  },
            .{null,     .ID_WINDOW,    0,  Default  },
            .{null,     .ID_WINDOW,    0,  Default  },
            .{null,     .ID_WINDOW,    0,  Default  },
            .{null,     .ID_WINDOW,    0,  Default  },
            .{null,     .ID_WINDOW,    0,  Default  },
            .{null,     .ID_WINDOW,    0,  Default  },
            .{null,     .ID_WINDOW,    0,  Default  },
            .{null,     .ID_WINDOW,    0,  Default  },
            .{null,     .ID_WINDOW,    0,  Default  },
            .{"~More Windows...",   .ID_MOREWINDOWS,  0,  Default  },
            .{null,     .ID_WINDOW,    0,  Default  },
        },
    },
    // --------------- the Help popdown menu ----------------
    .{"~Help", null, "Get help", -1, .{
            .{"~Help for help...", .ID_HELPHELP,  0,  Default  },
            .{"~Extended help...", .ID_EXTHELP,   0,  Default  },
            .{"~Keys help...",     .ID_KEYSHELP,  0,  Default  },
            .{"Help ~index...",    .ID_HELPINDEX, 0,  Default  },
            menus.Separator,
            .{"~About...",         .ID_ABOUT,     0,  Default  },
        },
    },

        // ----- cascaded pulldown from Tabs... above -----
        .{null, null, null, @intFromEnum(cmd.ID_TABS), .{
                .{"~2 tab stops",  .ID_TAB2,  0,  Default  },
                .{"~4 tab stops",  .ID_TAB4,  0,  Default  },
                .{"~6 tab stops",  .ID_TAB6,  0,  Default  },
                .{"~8 tab stops",  .ID_TAB8,  0,  Default  },
            },
        },
});

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
const df = mp.df;
const main = @import("main.zig");
const cmd = mp.Command;
const menus = mp.menus;
