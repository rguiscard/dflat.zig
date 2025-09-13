const mSEPCHAR = mp.menus.SEPCHAR;

// --------------------- the main menu ---------------------
pub var MainMenu:mp.menus.MBAR = mp.menus.buildMenuBar(.{
    // --------------- the File popdown menu ----------------
    .{"~File", df.PrepFileMenu, "Read/write/print files. Go to DOS", -1, .{
            .{"~New",        df.ID_NEW,       0,       0,          "ID_NEW"       },
            .{"~Open...",    df.ID_OPEN,      0,       0,          "ID_OPEN"      },
            .{mSEPCHAR,      0,               0,       0,          null           },
            .{"~Save",       df.ID_SAVE,      0,       df.INACTIVE,"ID_SAVE"      },
            .{"Save ~as...", df.ID_SAVEAS,    0,       df.INACTIVE,"ID_SAVEAS"    },
            .{"D~elete",     df.ID_DELETEFILE,0,       df.INACTIVE,"ID_DELETEFILE"},
            .{mSEPCHAR,      0,               0,       0,          null           },
            .{"~Shell",      df.ID_DOS,       0,       0,          "ID_DOS"       },
            .{"E~xit",       df.ID_EXIT,      df.ALT_X,0,          "ID_EXIT"      },
        },
    },
    .{"~Edit", df.PrepEditMenu, "Clipboard, delete text, paragraph", -1, .{
            .{"~Undo",       df.ID_UNDO,  df.ALT_BS,     df.INACTIVE,     "ID_UNDO"   },
            .{mSEPCHAR,      0,               0,           0,          null           },
            .{"Cu~t",        df.ID_CUT,       df.SHIFT_DEL,df.INACTIVE,"ID_CUT"       },
            .{"~Copy",       df.ID_COPY,      df.CTRL_INS, df.INACTIVE,"ID_COPY"      },
            .{"~Paste",      df.ID_PASTE,     df.SHIFT_INS,df.INACTIVE,"ID_PASTE"     },
            .{mSEPCHAR,      0,               0,           0,          null           },
            .{"Cl~ear",      df.ID_CLEAR,     0,           df.INACTIVE,"ID_CLEAR"     },
            .{"~Delete",     df.ID_DELETETEXT,df.DEL,      df.INACTIVE,"ID_DELETETEXT"},
            .{mSEPCHAR,      0,               0,           0,          null           },
            .{"Pa~ragraph",  df.ID_PARAGRAPH, df.ALT_P,    df.INACTIVE,"ID_PARAGRAPH" },
        },
    },
    .{"~Search", df.PrepSearchMenu, "Search and replace", -1, .{
            .{"~Search...",   df.ID_SEARCH,      0,     df.INACTIVE,     "ID_SEARCH"    },
            .{"~Replace...",  df.ID_REPLACE,     0,     df.INACTIVE,     "ID_REPLACE"   },
            .{"~Next",        df.ID_SEARCHNEXT,  df.F3, df.INACTIVE,     "ID_SEARCHNEXT"},
        },
    },
    .{"~Utilities", null, "Utility programs", -1, .{
            .{"~Calendar",   df.ID_CALENDAR,      0,     0,     "ID_CALENDAR"  },
            .{"~Bar chart",  df.ID_BARCHART,      0,     0,     "ID_BARCHART"  },
        },
    },
    // ------------- the Options popdown menu ---------------
    .{"~Options", null, "Editor and display options", -1, .{
            .{"~Display...",  df.ID_DISPLAY,    0,       0,          "ID_DISPLAY"      },
            .{mSEPCHAR,       0,                0,       0,          null              },
            .{"~Log messages",df.ID_LOG,        df.ALT_L,0,          "ID_LOG"          },
            .{mSEPCHAR,       0,                0,       0,          null              },
            .{"~Insert",      df.ID_INSERT,     df.INS,  df.TOGGLE,  "ID_INSERT"       },
            .{"~Word wrap",   df.ID_WRAP,       0,       df.TOGGLE,  "ID_WRAP"         },
            .{"~Tabs ( )",    df.ID_TABS,       0,       df.CASCADED,"ID_TABS"         },
            .{mSEPCHAR,       0,                0,       0,          null              },
            .{"~Save options",df.ID_SAVEOPTIONS,0,       0,          "ID_SAVEOPTIONS"  },
        },
    },
    // --------------- the Window popdown menu --------------
    .{"~Window", df.PrepWindowMenu, "Select/close document windows", -1, .{
            .{null,   df.ID_CLOSEALL,    0,     0,     null  },
            .{mSEPCHAR,    0,          0,     0,     null  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
            .{"~More Windows...",   df.ID_MOREWINDOWS,      0,     0,     "ID_MOREWINDOWS"  },
            .{null,   df.ID_WINDOW,      0,     0,     null  },
        },
    },
    // --------------- the Help popdown menu ----------------
    .{"~Help", null, "Get help", -1, .{
            .{"~Help for help...", df.ID_HELPHELP,  0,     0,     "ID_HELPHELP"  },
            .{"~Extended help...", df.ID_EXTHELP,   0,     0,     "ID_EXTHELP"   },
            .{"~Keys help...",     df.ID_KEYSHELP,  0,     0,     "ID_KEYSHELP"  },
            .{"Help ~index...",    df.ID_HELPINDEX, 0,     0,     "ID_HELPINDEX" },
            .{mSEPCHAR,            0,               0,     0,     null           },
            .{"~About...",         df.ID_ABOUT,     0,     0,     "ID_ABOUT"     },
        },
    },

        // ----- cascaded pulldown from Tabs... above -----
        .{null, null, null, df.ID_TABS, .{
                .{"~2 tab stops",   df.ID_TAB2,    0,     0,     "ID_TAB2"  },
                .{"~4 tab stops",   df.ID_TAB4,    0,     0,     "ID_TAB4"  },
                .{"~6 tab stops",   df.ID_TAB6,    0,     0,     "ID_TAB6"  },
                .{"~8 tab stops",   df.ID_TAB8,    0,     0,     "ID_TAB8"  },
            },
        },
});

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
const df = mp.df;
const main = @import("main.zig");
