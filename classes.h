/* ----------- classes.h ------------ */

#define SHADOW       0x0001
#define MOVEABLE     0x0002
#define SIZEABLE     0x0004
#define HASMENUBAR   0x0008
#define VSCROLLBAR   0x0010
#define HSCROLLBAR   0x0020
#define VISIBLE      0x0040
#define SAVESELF     0x0080
#define HASTITLEBAR  0x0100
#define CONTROLBOX   0x0200
#define MINMAXBOX    0x0400
#define NOCLIP       0x0800
#define READONLY     0x1000
#define MULTILINE    0x2000
#define HASBORDER    0x4000
#define HASSTATUSBAR 0x8000

/*
 *         Class definition source file
 *         Make class changes to this source file
 *         Other source files will adapt
 *
 *         You must add entries to the color tables in
 *         CONFIG.C for new classes.
 *
 *        Class Name  Base Class   Processor       Attribute    
 *       ------------  --------- ---------------  -----------
 */
#if 0
ClassDef(  NORMAL,      -1,      0 )
ClassDef(  APPLICATION, NORMAL,  VISIBLE   |
                                 SAVESELF  |
                                 CONTROLBOX )
ClassDef(  TEXTBOX,     NORMAL,  0          )
ClassDef(  LISTBOX,     TEXTBOX, 0          )
ClassDef(  EDITBOX,     TEXTBOX, 0          )
ClassDef(  MENUBAR,     NORMAL,  NOCLIP     )
ClassDef(  POPDOWNMENU, LISTBOX, SAVESELF  |
                                 NOCLIP    |
                                 HASBORDER  )
#ifndef BUILD_SMALL_DFLAT
#ifdef INCLUDE_PICTUREBOX
ClassDef(  PICTUREBOX,  TEXTBOX, 0          )
#endif
ClassDef(  DIALOG,      NORMAL,  SHADOW    |
                                 MOVEABLE  |
                                 CONTROLBOX|
                                 HASBORDER |
                                 NOCLIP     )
ClassDef(  BOX,         NORMAL,  HASBORDER  )
ClassDef(  BUTTON,      TEXTBOX, SHADOW     )
ClassDef(  COMBOBOX,    EDITBOX, 0          )
ClassDef(  TEXT,        TEXTBOX, 0          )
ClassDef(  RADIOBUTTON, TEXTBOX, 0          )
ClassDef(  CHECKBOX,    TEXTBOX, 0          )
ClassDef(  SPINBUTTON,  LISTBOX, 0          )
ClassDef(  ERRORBOX,    DIALOG,  SHADOW    |
                                 HASBORDER  )
ClassDef(  MESSAGEBOX,  DIALOG,  SHADOW    |
                                 HASBORDER  )
ClassDef(  HELPBOX,     DIALOG,  MOVEABLE  |
                                 SAVESELF  |
                                 HASBORDER |
                                 NOCLIP    |
                                 CONTROLBOX )
#endif

ClassDef(  STATUSBAR,   TEXTBOX, NOCLIP     )
ClassDef(  EDITOR,      EDITBOX, 0          )
/*
 *  ========> Add new classes here <========
 */

/* ---------- pseudo classes to create enums, etc. ---------- */
ClassDef(  TITLEBAR,    -1,      0          )
ClassDef(  DUMMY,       -1,      HASBORDER  )
#endif
