// ---------------- commands.h -----------------

const df = @import("ImportC.zig").df;

//
// Command values sent as the first parameter
// in the COMMAND message
//
// Add application-specific commands to this enum
//

pub const Command = enum (c_int) {
    ID_NULL = df.ID_NULL,
    // --------------- File menu ----------------
    ID_OPEN = df.ID_OPEN,
    ID_NEW = df.ID_NEW,
    ID_SAVE = df.ID_SAVE,
    ID_SAVEAS = df.ID_SAVEAS,
    ID_DELETEFILE = df.ID_DELETEFILE,
    ID_DOS = df.ID_DOS,
    ID_EXIT = df.ID_EXIT,
    // --------------- Edit menu ----------------
    ID_UNDO = df.ID_UNDO,
    ID_CUT = df.ID_CUT,
    ID_COPY = df.ID_COPY,
    ID_PASTE = df.ID_PASTE,
    ID_PARAGRAPH = df.ID_PARAGRAPH,
    ID_CLEAR = df.ID_CLEAR,
    ID_DELETETEXT = df.ID_DELETETEXT,
    // --------------- Search Menu --------------
    ID_SEARCH = df.ID_SEARCH,
    ID_REPLACE = df.ID_REPLACE,
    ID_SEARCHNEXT = df.ID_SEARCHNEXT,
    // --------------- Utilities Menu -------------
    ID_CALENDAR = df.ID_CALENDAR,
    ID_BARCHART = df.ID_BARCHART,
    // -------------- Options menu --------------
    ID_INSERT = df.ID_INSERT,
    ID_WRAP = df.ID_WRAP,
    ID_LOG = df.ID_LOG,
    ID_TABS = df.ID_TABS,
    ID_DISPLAY = df.ID_DISPLAY,
    ID_SAVEOPTIONS = df.ID_SAVEOPTIONS,
    // --------------- Window menu --------------
    ID_CLOSEALL = df.ID_CLOSEALL,
    ID_WINDOW = df.ID_WINDOW,
    ID_MOREWINDOWS = df.ID_MOREWINDOWS,
    // --------------- Help menu ----------------
    ID_HELPHELP = df.ID_HELPHELP,
    ID_EXTHELP = df.ID_EXTHELP,
    ID_KEYSHELP = df.ID_KEYSHELP,
    ID_HELPINDEX = df.ID_HELPINDEX,
    ID_ABOUT = df.ID_ABOUT,
    // --------------- System menu --------------
    ID_SYSRESTORE = df.ID_SYSRESTORE,
    ID_SYSMOVE = df.ID_SYSMOVE,
    ID_SYSSIZE = df.ID_SYSSIZE,
    ID_SYSMINIMIZE = df.ID_SYSMINIMIZE,
    ID_SYSMAXIMIZE = df.ID_SYSMAXIMIZE,
    ID_SYSCLOSE = df.ID_SYSCLOSE,
    // ---- FileOpen and SaveAs dialog boxes ----
    ID_FILENAME = df.ID_FILENAME,
    ID_FILES = df.ID_FILES,
    ID_DIRECTORY = df.ID_DIRECTORY,
    ID_PATH = df.ID_PATH,
    // ----- Search and Replace dialog boxes ----
    ID_SEARCHFOR = df.ID_SEARCHFOR,
    ID_REPLACEWITH = df.ID_REPLACEWITH,
    ID_MATCHCASE = df.ID_MATCHCASE,
    ID_REPLACEALL = df.ID_REPLACEALL,
    // ----------- Windows dialog box -----------
    ID_WINDOWLIST = df.ID_WINDOWLIST,
    // --------- generic command buttons --------
    ID_OK = df.ID_OK,
    ID_CANCEL = df.ID_CANCEL,
    ID_HELP = df.ID_HELP,
    // -------------- TabStops menu -------------
    ID_TAB2 = df.ID_TAB2,
    ID_TAB4 = df.ID_TAB4,
    ID_TAB6 = df.ID_TAB6,
    ID_TAB8 = df.ID_TAB8,
    // ------------ Display dialog box ----------
    ID_BORDER = df.ID_BORDER,
    ID_TITLE = df.ID_TITLE,
    ID_STATUSBAR = df.ID_STATUSBAR,
    ID_TEXTURE = df.ID_TEXTURE,
    ID_COLOR = df.ID_COLOR,
    ID_MONO = df.ID_MONO,
    ID_REVERSE = df.ID_REVERSE,
    // ------------- Log dialog box -------------
    ID_LOGLIST = df.ID_LOGLIST,
    ID_LOGGING = df.ID_LOGGING,
    // ------------ HelpBox dialog box ----------
    ID_HELPTEXT = df.ID_HELPTEXT,
    ID_BACK = df.ID_BACK,
    ID_PREV = df.ID_PREV,
    ID_NEXT = df.ID_NEXT,
    // ----------- InputBox dialog box ------------
    ID_INPUTTEXT = df.ID_INPUTTEXT,
};
