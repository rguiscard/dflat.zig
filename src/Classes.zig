const df = @import("ImportC.zig").df;
const wp = @import("WndProc.zig");
const Window = @import("Window.zig");
const normal = @import("Normal.zig");
const app = @import("Application.zig");
const dialbox = @import("DialogBox.zig");
const box = @import("Box.zig");
const picture = @import("PictureBox.zig");
const textbox = @import("TextBox.zig");
const menubar = @import("MenuBar.zig");
const listbox = @import("ListBox.zig");
const editbox = @import("EditBox.zig");
const button = @import("Button.zig");
const text = @import("Text.zig");
const radio = @import("RadioButton.zig");
const checkbox = @import("CheckBox.zig");
const statusbar = @import("StatusBar.zig");
const popdown = @import("PopDown.zig");
const editor = @import("Editor.zig");
const helpbox = @import("HelpBox.zig");

// ----------- classes.h ------------
//
//         Class definition source file
//         Make class changes to this source file
//         Other source files will adapt
//
//         You must add entries to the color tables in
//         CONFIG.C for new classes.

pub const CLASS = enum (i8) {
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

    // ---------- total count of classes (excl FORCEINTTYPE)
    CLASSCOUNT,
};

// The order need to match enum Klass
// Class Name  Base Class  Processor  Attribute
// ----------  ----------  ---------  ---------
pub const defs = [_]struct{
    []const u8,
    CLASS,
    ?*const fn (win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool,
    isize} {

    .{"NORMAL",      CLASS.FORCEINTTYPE, normal.NormalProc,        0              },
    .{"APPLICATION", CLASS.NORMAL,          app.ApplicationProc,   df.VISIBLE    |
                                                                   df.SAVESELF   |
                                                                   df.CONTROLBOX  },
    .{"TEXTBOX",     CLASS.NORMAL,      textbox.TextBoxProc,       0              },
    .{"LISTBOX",     CLASS.TEXTBOX,     listbox.ListBoxProc,       0              },
    .{"EDITBOX",     CLASS.TEXTBOX,     editbox.EditBoxProc,       0              },
    .{"MENUBAR",     CLASS.NORMAL,      menubar.MenuBarProc,       df.NOCLIP      },
    .{"POPDOWNMENU", CLASS.LISTBOX,     popdown.PopDownProc,       df.SAVESELF   |
                                                                   df.NOCLIP     |
                                                                   df.HASBORDER   },
    .{"PICTUREBOX",  CLASS.TEXTBOX,     picture.PictureProc,       0              },
    .{"DIALOG",      CLASS.NORMAL,      dialbox.DialogProc,        df.SHADOW     |
                                                                   df.MOVEABLE   |
                                                                   df.CONTROLBOX |
                                                                   df.HASBORDER  |
                                                                   df.NOCLIP      },
    .{"BOX",         CLASS.NORMAL,          box.BoxProc,           df.HASBORDER   },
    .{"BUTTON",      CLASS.TEXTBOX,      button.ButtonProc,        df.SHADOW      },
    .{"COMBOBOX",    CLASS.EDITBOX,          wp.ComboProc,         0              },
    .{"TEXT",        CLASS.TEXTBOX,        text.TextProc,          0              },
    .{"RADIOBUTTON", CLASS.TEXTBOX,       radio.RadioButtonProc,   0              },
    .{"CHECKBOX",    CLASS.TEXTBOX,    checkbox.CheckBoxProc,      0              },
    .{"SPINBUTTON",  CLASS.LISTBOX,          wp.SpinButtonProc,    0              },
    .{"ERRORBOX",    CLASS.DIALOG,       null,                     df.SHADOW     |
                                                                   df.HASBORDER   },
    .{"MESSAGEBOX",  CLASS.DIALOG,       null,                     df.SHADOW     |
                                                                   df.HASBORDER   },
    .{"HELPBOX",     CLASS.DIALOG,      helpbox.HelpBoxProc,       df.MOVEABLE   |
                                                                   df.SAVESELF   |
                                                                   df.HASBORDER  |
                                                                   df.NOCLIP     |
                                                                   df.CONTROLBOX},
    .{"STATUSBAR",   CLASS.TEXTBOX,   statusbar.StatusBarProc,     df.NOCLIP      },
    .{"EDITOR",      CLASS.EDITBOX,      editor.EditorProc,        0              },

    // ========> Add new classes here <========

    // ---------- pseudo classes to create enums, etc. ----------
    .{"TITLEBAR",    CLASS.FORCEINTTYPE, null,                     0              },
    .{"DUMMY",       CLASS.FORCEINTTYPE, null,                     df.HASBORDER   },
};
