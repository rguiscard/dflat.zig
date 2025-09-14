const mSEPCHAR = mp.menus.SEPCHAR;
const Default = mp.menus.Default;
const Inactive = mp.menus.Inactive;
const Toggle = mp.menus.Toggle;
const Cascaded = mp.menus.Cascaded;

// --------------------- the main menu ---------------------
pub var MainMenu:mp.menus.MBAR = mp.menus.buildMenuBar(.{
    // --------------- the File popdown menu ----------------
    .{"~File", main.PrepFileMenu, "Read/write/print files. Go to DOS", -1, .{
            .{"~New",        df.ID_NEW,       0,       Default,   "ID_NEW"       },
            .{"~Open...",    df.ID_OPEN,      0,       Default,   "ID_OPEN"      },
            .{mSEPCHAR,      0,               0,       Default,   null           },
            .{"~Save",       df.ID_SAVE,      0,       Inactive,  "ID_SAVE"      },
            .{"Save ~as...", df.ID_SAVEAS,    0,       Inactive,  "ID_SAVEAS"    },
            .{"D~elete",     df.ID_DELETEFILE,0,       Inactive,  "ID_DELETEFILE"},
            .{mSEPCHAR,      0,               0,       Default,   null           },
            .{"~Shell",      df.ID_DOS,       0,       Default,   "ID_DOS"       },
            .{"E~xit",       df.ID_EXIT,      df.ALT_X,Default,   "ID_EXIT"      },
        },
    },
    .{"~Edit", main.PrepEditMenu, "Clipboard, delete text, paragraph", -1, .{
            .{"~Undo",       df.ID_UNDO,      df.ALT_BS,   Inactive,"ID_UNDO"      },
            .{mSEPCHAR,      0,               0,           Default, null           },
            .{"Cu~t",        df.ID_CUT,       df.SHIFT_DEL,Inactive,"ID_CUT"       },
            .{"~Copy",       df.ID_COPY,      df.CTRL_INS, Inactive,"ID_COPY"      },
            .{"~Paste",      df.ID_PASTE,     df.SHIFT_INS,Inactive,"ID_PASTE"     },
            .{mSEPCHAR,      0,               0,           Default, null           },
            .{"Cl~ear",      df.ID_CLEAR,     0,           Inactive,"ID_CLEAR"     },
            .{"~Delete",     df.ID_DELETETEXT,df.DEL,      Inactive,"ID_DELETETEXT"},
            .{mSEPCHAR,      0,               0,           Default, null           },
            .{"Pa~ragraph",  df.ID_PARAGRAPH, df.ALT_P,    Inactive,"ID_PARAGRAPH" },
        },
    },
    .{"~Search", main.PrepSearchMenu, "Search and replace", -1, .{
            .{"~Search...",   df.ID_SEARCH,      0,     Inactive,  "ID_SEARCH"    },
            .{"~Replace...",  df.ID_REPLACE,     0,     Inactive,  "ID_REPLACE"   },
            .{"~Next",        df.ID_SEARCHNEXT,  df.F3, Inactive,  "ID_SEARCHNEXT"},
        },
    },
    .{"~Utilities", null, "Utility programs", -1, .{
            .{"~Calendar",   df.ID_CALENDAR,  0,  Default,  "ID_CALENDAR"  },
            .{"~Bar chart",  df.ID_BARCHART,  0,  Default,  "ID_BARCHART"  },
        },
    },
    // ------------- the Options popdown menu ---------------
    .{"~Options", null, "Editor and display options", -1, .{
            .{"~Display...",  df.ID_DISPLAY,    0,       Default, "ID_DISPLAY"      },
            .{mSEPCHAR,       0,                0,       Default, null              },
            .{"~Log messages",df.ID_LOG,        df.ALT_L,Default, "ID_LOG"          },
            .{mSEPCHAR,       0,                0,       Default, null              },
            .{"~Insert",      df.ID_INSERT,     df.INS,  Toggle,  "ID_INSERT"       },
            .{"~Word wrap",   df.ID_WRAP,       0,       Toggle,  "ID_WRAP"         },
            .{"~Tabs ( )",    df.ID_TABS,       0,       Cascaded,"ID_TABS"         },
            .{mSEPCHAR,       0,                0,       Default, null              },
            .{"~Save options",df.ID_SAVEOPTIONS,0,       Default, "ID_SAVEOPTIONS"  },
        },
    },
    // --------------- the Window popdown menu --------------
    .{"~Window", mp.app.PrepWindowMenu, "Select/close document windows", -1, .{
            .{null,     df.ID_CLOSEALL,  0,  Default,  null  },
            .{mSEPCHAR, 0,               0,  Default,  null  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
            .{"~More Windows...",   df.ID_MOREWINDOWS,  0,  Default,  "ID_MOREWINDOWS"  },
            .{null,     df.ID_WINDOW,    0,  Default,  null  },
        },
    },
    // --------------- the Help popdown menu ----------------
    .{"~Help", null, "Get help", -1, .{
            .{"~Help for help...", df.ID_HELPHELP,  0,  Default,  "ID_HELPHELP"  },
            .{"~Extended help...", df.ID_EXTHELP,   0,  Default,  "ID_EXTHELP"   },
            .{"~Keys help...",     df.ID_KEYSHELP,  0,  Default,  "ID_KEYSHELP"  },
            .{"Help ~index...",    df.ID_HELPINDEX, 0,  Default,  "ID_HELPINDEX" },
            .{mSEPCHAR,            0,               0,  Default,  null           },
            .{"~About...",         df.ID_ABOUT,     0,  Default,  "ID_ABOUT"     },
        },
    },

        // ----- cascaded pulldown from Tabs... above -----
        .{null, null, null, df.ID_TABS, .{
                .{"~2 tab stops",  df.ID_TAB2,  0,  Default,  "ID_TAB2"  },
                .{"~4 tab stops",  df.ID_TAB4,  0,  Default,  "ID_TAB4"  },
                .{"~6 tab stops",  df.ID_TAB6,  0,  Default,  "ID_TAB6"  },
                .{"~8 tab stops",  df.ID_TAB8,  0,  Default,  "ID_TAB8"  },
            },
        },
});

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
const df = mp.df;
const main = @import("main.zig");
