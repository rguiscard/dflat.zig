/* ----------- classes.h ------------ */
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
