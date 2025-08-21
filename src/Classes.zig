const df = @import("ImportC.zig").df;

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
pub const classdefs = [_]struct{
    []const u8,
    Klass,
    ?*const fn (wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int,
    isize} {

    .{"NORMAL",      Klass.FORCEINTTYPE, df.NormalProc,        0              },
    .{"APPLICATION", Klass.NORMAL,       df.ApplicationProc,   df.VISIBLE    |
                                                               df.SAVESELF   |
                                                               df.CONTROLBOX  },
    .{"TEXTBOX",     Klass.NORMAL,       df.TextBoxProc,       0              },
    .{"LISTBOX",     Klass.TEXTBOX,      df.ListBoxProc,       0              },
    .{"EDITBOX",     Klass.TEXTBOX,      df.EditBoxProc,       0              },
    .{"MENUBAR",     Klass.NORMAL,       df.MenuBarProc,       df.NOCLIP      },
    .{"POPDOWNMENU", Klass.LISTBOX,      df.PopDownProc,       df.SAVESELF   |
                                                               df.NOCLIP     |
                                                               df.HASBORDER   },
    .{"PICTUREBOX",  Klass.TEXTBOX,      df.PictureProc,       0              },
    .{"DIALOG",      Klass.NORMAL,       df.DialogProc,        df.SHADOW     |
                                                               df.MOVEABLE   |
                                                               df.CONTROLBOX |
                                                               df.HASBORDER  |
                                                               df.NOCLIP},
    .{"BOX",         Klass.NORMAL,       df.BoxProc,           df.HASBORDER   },
    .{"BUTTON",      Klass.TEXTBOX,      df.ButtonProc,        df.SHADOW      },
    .{"COMBOBOX",    Klass.EDITBOX,      df.ComboProc,         0              },
    .{"TEXT",        Klass.TEXTBOX,      df.TextProc,          0              },
    .{"RADIOBUTTON", Klass.TEXTBOX,      df.RadioButtonProc,   0              },
    .{"CHECKBOX",    Klass.TEXTBOX,      df.CheckBoxProc,      0              },
    .{"SPINBUTTON",  Klass.LISTBOX,      df.SpinButtonProc,    0              },
    .{"ERRORBOX",    Klass.DIALOG,       null,                 df.SHADOW     |
                                                               df.HASBORDER   },
    .{"MESSAGEBOX",  Klass.DIALOG,       null,                 df.SHADOW     |
                                                               df.HASBORDER   },
    .{"HELPBOX",     Klass.DIALOG,       df.HelpBoxProc,       df.MOVEABLE   |
                                                               df.SAVESELF   |
                                                               df.HASBORDER  |
                                                               df.NOCLIP     |
                                                               df.CONTROLBOX},
    .{"STATUSBAR",   Klass.TEXTBOX,      df.StatusBarProc,     df.NOCLIP      },
    .{"EDITOR",      Klass.EDITBOX,      df.EditorProc,        0              },

    // ========> Add new classes here <========

    // ---------- pseudo classes to create enums, etc. ----------
    .{"TITLEBAR",    Klass.FORCEINTTYPE, null,                 0              },
    .{"DUMMY",       Klass.FORCEINTTYPE, null,                 df.HASBORDER   },
};
