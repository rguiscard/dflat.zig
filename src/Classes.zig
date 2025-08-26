const df = @import("ImportC.zig").df;
const wp = @import("WndProc.zig");
const Window = @import("Window.zig");

// ----------- classes.h ------------
//
//         Class definition source file
//         Make class changes to this source file
//         Other source files will adapt
//
//         You must add entries to the color tables in
//         CONFIG.C for new classes.

pub const Klass = enum (c_int) {
    FORCEINTTYPE = -1,      // required or enum type is unsigned char
    NORMAL = 0,
    APPLICATION,
    TEXTBOX,
    LISTBOX,
    EDITBOX,
    MENUBAR,
    POPDOWNMENU,
    PICTUREBOX,
    DIALOG,
    BOX,
    BUTTON,
    COMBOBOX,
    TEXT,
    RADIOBUTTON,
    CHECKBOX,
    SPINBUTTON,
    ERRORBOX,
    MESSAGEBOX,
    HELPBOX,
    STATUSBAR,
    EDITOR,

    //  ========> Add new classes here <========

    // ---------- pseudo classes to create enums, etc.
    TITLEBAR,
    DUMMY,
};

// The order need to match enum Klass
// Class Name  Base Class  Processor  Attribute
// ----------  ----------  ---------  ---------
pub const defs = [_]struct{
    []const u8,
    Klass,
    ?*const fn (win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int,
    isize} {

    .{"NORMAL",      Klass.FORCEINTTYPE, wp.NormalProc,        0              },
    .{"APPLICATION", Klass.NORMAL,       wp.ApplicationProc,   df.VISIBLE    |
                                                               df.SAVESELF   |
                                                               df.CONTROLBOX  },
    .{"TEXTBOX",     Klass.NORMAL,       wp.TextBoxProc,       0              },
    .{"LISTBOX",     Klass.TEXTBOX,      wp.ListBoxProc,       0              },
    .{"EDITBOX",     Klass.TEXTBOX,      wp.EditBoxProc,       0              },
    .{"MENUBAR",     Klass.NORMAL,       wp.MenuBarProc,       df.NOCLIP      },
    .{"POPDOWNMENU", Klass.LISTBOX,      wp.PopDownProc,       df.SAVESELF   |
                                                               df.NOCLIP     |
                                                               df.HASBORDER   },
    .{"PICTUREBOX",  Klass.TEXTBOX,      wp.PictureProc,       0              },
    .{"DIALOG",      Klass.NORMAL,       wp.DialogProc,        df.SHADOW     |
                                                               df.MOVEABLE   |
                                                               df.CONTROLBOX |
                                                               df.HASBORDER  |
                                                               df.NOCLIP},
    .{"BOX",         Klass.NORMAL,       wp.BoxProc,           df.HASBORDER   },
    .{"BUTTON",      Klass.TEXTBOX,      wp.ButtonProc,        df.SHADOW      },
    .{"COMBOBOX",    Klass.EDITBOX,      wp.ComboProc,         0              },
    .{"TEXT",        Klass.TEXTBOX,      wp.TextProc,          0              },
    .{"RADIOBUTTON", Klass.TEXTBOX,      wp.RadioButtonProc,   0              },
    .{"CHECKBOX",    Klass.TEXTBOX,      wp.CheckBoxProc,      0              },
    .{"SPINBUTTON",  Klass.LISTBOX,      wp.SpinButtonProc,    0              },
    .{"ERRORBOX",    Klass.DIALOG,       null,                 df.SHADOW     |
                                                               df.HASBORDER   },
    .{"MESSAGEBOX",  Klass.DIALOG,       null,                 df.SHADOW     |
                                                               df.HASBORDER   },
    .{"HELPBOX",     Klass.DIALOG,       wp.HelpBoxProc,       df.MOVEABLE   |
                                                               df.SAVESELF   |
                                                               df.HASBORDER  |
                                                               df.NOCLIP     |
                                                               df.CONTROLBOX},
    .{"STATUSBAR",   Klass.TEXTBOX,      wp.StatusBarProc,     df.NOCLIP      },
    .{"EDITOR",      Klass.EDITBOX,      wp.EditorProc,        0              },

    // ========> Add new classes here <========

    // ---------- pseudo classes to create enums, etc. ----------
    .{"TITLEBAR",    Klass.FORCEINTTYPE, null,                 0              },
    .{"DUMMY",       Klass.FORCEINTTYPE, null,                 df.HASBORDER   },
};
