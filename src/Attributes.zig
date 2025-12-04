pub const SHADOW:u16       = 0x0001;
pub const MOVEABLE:u16     = 0x0002;
pub const SIZEABLE:u16     = 0x0004;
pub const HASMENUBAR:u16   = 0x0008;
pub const VSCROLLBAR:u16   = 0x0010;
pub const HSCROLLBAR:u16   = 0x0020;
pub const VISIBLE:u16      = 0x0040;
pub const SAVESELF:u16     = 0x0080;
pub const HASTITLEBAR:u16  = 0x0100;
pub const CONTROLBOX:u16   = 0x0200;
pub const MINMAXBOX:u16    = 0x0400;
pub const NOCLIP:u16       = 0x0800;
pub const READONLY:u16     = 0x1000;
pub const MULTILINE:u16    = 0x2000;
pub const HASBORDER:u16    = 0x4000;
pub const HASSTATUSBAR:u16 = 0x8000;

pub const Center = packed struct {
    LEFT: bool = false,
    TOP: bool = false,
    WIDTH: bool = false,
    HEIGHT: bool = false,
};

pub const Property = enum (u16) {
    SHADOW = SHADOW,
    MOVEABLE = MOVEABLE,
    SIZEABLE = SIZEABLE,
    HASMENUBAR = HASMENUBAR,
    VSCROLLBAR = VSCROLLBAR,
    HSCROLLBAR = HSCROLLBAR,
    VISIBLE = VISIBLE,
    SAVESELF = SAVESELF,
    HASTITLEBAR = HASTITLEBAR,
    CONTROLBOX = CONTROLBOX,
    MINMAXBOX = MINMAXBOX,
    NOCLIP = NOCLIP,
    READONLY = READONLY,
    MULTILINE = MULTILINE,
    HASBORDER = HASBORDER,
    HASSTATUSBAR = HASSTATUSBAR,
};
