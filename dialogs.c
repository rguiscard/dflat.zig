/* ----------- dialogs.c --------------- */

#include "dflat.h"

/* -------------- the File Open dialog box --------------- */
/*
DIALOGBOX( FileOpen )
    DB_TITLE(        "Open File",    -1,-1,19,57)
    CONTROL(TEXT,    "~Filename:",    3, 1, 1, 9, ID_FILENAME)
    CONTROL(EDITBOX, NULL,           13, 1, 1,40, ID_FILENAME)
    CONTROL(TEXT,    NULL,            3, 3, 1,50, ID_PATH ) 
    CONTROL(TEXT,    "~Directories:", 3, 5, 1,12, ID_DIRECTORY )
    CONTROL(LISTBOX, NULL,            3, 6,10,14, ID_DIRECTORY )
    CONTROL(TEXT,    "F~iles:",      19, 5, 1, 6, ID_FILES )
    CONTROL(LISTBOX, NULL,           19, 6,10,24, ID_FILES )
    CONTROL(BUTTON,  "   ~OK   ",    46, 7, 1, 8, ID_OK)
    CONTROL(BUTTON,  " ~Cancel ",    46,10, 1, 8, ID_CANCEL)
    CONTROL(BUTTON,  "  ~Help  ",    46,13, 1, 8, ID_HELP)
ENDDB
*/

/* -------------- the Save As dialog box --------------- */
/*
DIALOGBOX( SaveAs )
    DB_TITLE(        "Save As",    -1,-1,19,57)
    CONTROL(TEXT,    "~Filename:",    3, 1, 1, 9, ID_FILENAME)
    CONTROL(EDITBOX, NULL,           13, 1, 1,40, ID_FILENAME)
    CONTROL(TEXT,    NULL,            3, 3, 1,50, ID_PATH ) 
    CONTROL(TEXT,    "~Directories:", 3, 5, 1,12, ID_DIRECTORY )
    CONTROL(LISTBOX, NULL,            3, 6,10,14, ID_DIRECTORY )
    CONTROL(TEXT,    "F~iles:",      19, 5, 1, 6, ID_FILES )
    CONTROL(LISTBOX, NULL,           19, 6,10,24, ID_FILES )
    CONTROL(BUTTON,  "   ~OK   ",    46, 7, 1, 8, ID_OK)
    CONTROL(BUTTON,  " ~Cancel ",    46,10, 1, 8, ID_CANCEL)
    CONTROL(BUTTON,  "  ~Help  ",    46,13, 1, 8, ID_HELP)
ENDDB
*/

/* -------------- the Search Text dialog box --------------- */
/*
DIALOGBOX( SearchTextDB )
    DB_TITLE(        "Search Text",    -1,-1,9,48)
    CONTROL(TEXT,    "~Search for:",          2, 1, 1, 11, ID_SEARCHFOR)
    CONTROL(EDITBOX, NULL,                   14, 1, 1, 29, ID_SEARCHFOR)
    CONTROL(TEXT, "~Match upper/lower case:", 2, 3, 1, 23, ID_MATCHCASE)
	CONTROL(CHECKBOX,  NULL,                 26, 3, 1,  3, ID_MATCHCASE)
    CONTROL(BUTTON, "   ~OK   ",              7, 5, 1,  8, ID_OK)
    CONTROL(BUTTON, " ~Cancel ",             19, 5, 1,  8, ID_CANCEL)
    CONTROL(BUTTON, "  ~Help  ",             31, 5, 1,  8, ID_HELP)
ENDDB
*/

/* -------------- the Replace Text dialog box --------------- */
/*
DIALOGBOX( ReplaceTextDB )
    DB_TITLE(        "Replace Text",    -1,-1,12,50)
    CONTROL(TEXT,    "~Search for:",          2, 1, 1, 11, ID_SEARCHFOR)
    CONTROL(EDITBOX, NULL,                   16, 1, 1, 29, ID_SEARCHFOR)
    CONTROL(TEXT,    "~Replace with:",        2, 3, 1, 13, ID_REPLACEWITH)
    CONTROL(EDITBOX, NULL,                   16, 3, 1, 29, ID_REPLACEWITH)
    CONTROL(TEXT, "~Match upper/lower case:", 2, 5, 1, 23, ID_MATCHCASE)
	CONTROL(CHECKBOX,  NULL,                 26, 5, 1,  3, ID_MATCHCASE)
    CONTROL(TEXT, "Replace ~Every Match:",    2, 6, 1, 23, ID_REPLACEALL)
	CONTROL(CHECKBOX,  NULL,                 26, 6, 1,  3, ID_REPLACEALL)
    CONTROL(BUTTON, "   ~OK   ",              7, 8, 1,  8, ID_OK)
    CONTROL(BUTTON, " ~Cancel ",             20, 8, 1,  8, ID_CANCEL)
    CONTROL(BUTTON, "  ~Help  ",             33, 8, 1,  8, ID_HELP)
ENDDB
*/

/* -------------- generic message dialog box --------------- */
/*
DIALOGBOX( MsgBox )
    DB_TITLE(       NULL,  -1,-1, 0, 0)
    CONTROL(TEXT,   NULL,   1, 1, 0, 0, 0)
    CONTROL(BUTTON, NULL,   0, 0, 1, 8, ID_OK)
    CONTROL(0,      NULL,   0, 0, 1, 8, ID_CANCEL)
ENDDB
*/

/* ----------- InputBox Dialog Box ------------ */
DIALOGBOX( InputBoxDB )
    DB_TITLE(        NULL,      -1,-1, 9, 0)
    CONTROL(TEXT,    NULL,       1, 1, 1, 0, 0)
	CONTROL(EDITBOX, NULL,       1, 3, 1, 0, ID_INPUTTEXT)
    CONTROL(BUTTON, "   ~OK   ", 0, 5, 1, 8, ID_OK)
    CONTROL(BUTTON, " ~Cancel ", 0, 5, 1, 8, ID_CANCEL)
ENDDB

/* ----------- SliderBox Dialog Box ------------- */
DIALOGBOX( SliderBoxDB )
    DB_TITLE(       NULL,      -1,-1, 9, 0)
    CONTROL(TEXT,   NULL,       0, 1, 1, 0, 0)
    CONTROL(TEXT,   NULL,       0, 3, 1, 0, 0)
    CONTROL(BUTTON, " Cancel ", 0, 5, 1, 8, ID_CANCEL)
ENDDB

#ifdef INCLUDE_WINDOWOPTIONS
#define offset 7
#else
#define offset 0
#endif

/* ------------ Display dialog box -------------- */
DIALOGBOX( Display )
    DB_TITLE(     "Display", -1, -1, 12+offset, 35)
#ifdef INCLUDE_WINDOWOPTIONS
	CONTROL(BOX,      "Window",    7, 1, 6,20, 0)
    CONTROL(CHECKBOX,    NULL,     9, 2, 1, 3, ID_TITLE)
    CONTROL(TEXT,     "~Title",   15, 2, 1, 5, ID_TITLE)
    CONTROL(CHECKBOX,    NULL,     9, 3, 1, 3, ID_BORDER)
    CONTROL(TEXT,     "~Border",  15, 3, 1, 6, ID_BORDER)
    CONTROL(CHECKBOX,    NULL,     9, 4, 1, 3, ID_STATUSBAR)
    CONTROL(TEXT,   "~Status bar",15, 4, 1,10, ID_STATUSBAR)
    CONTROL(CHECKBOX,    NULL,     9, 5, 1, 3, ID_TEXTURE)
    CONTROL(TEXT,     "Te~xture", 15, 5, 1, 7, ID_TEXTURE)
#endif
    CONTROL(BOX,      "Colors",    7, 1+offset,5,20, 0)
    CONTROL(RADIOBUTTON, NULL,     9, 2+offset,1,3,ID_COLOR)
    CONTROL(TEXT,     "Co~lor",   13, 2+offset,1,5,ID_COLOR)
    CONTROL(RADIOBUTTON, NULL,     9, 3+offset,1,3,ID_MONO)
    CONTROL(TEXT,     "~Mono",    13, 3+offset,1,4,ID_MONO)
    CONTROL(RADIOBUTTON, NULL,     9, 4+offset,1,3,ID_REVERSE)
    CONTROL(TEXT,     "~Reverse", 13, 4+offset,1,7,ID_REVERSE)

    CONTROL(BUTTON, "   ~OK   ",   2, 8+offset,1,8,ID_OK)
    CONTROL(BUTTON, " ~Cancel ",  12, 8+offset,1,8,ID_CANCEL)
    CONTROL(BUTTON, "  ~Help  ",  22, 8+offset,1,8,ID_HELP)
ENDDB

/* ------------ Windows dialog box -------------- */
DIALOGBOX( Windows )
    DB_TITLE(     "Windows", -1, -1, 19, 24)
    CONTROL(LISTBOX, NULL,         1,  1,11,20, ID_WINDOWLIST)
    CONTROL(BUTTON,  "   ~OK   ",  2, 13, 1, 8, ID_OK)
    CONTROL(BUTTON,  " ~Cancel ", 12, 13, 1, 8, ID_CANCEL)
    CONTROL(BUTTON,  "  ~Help  ",  7, 15, 1, 8, ID_HELP)
ENDDB

#ifdef INCLUDE_LOGGING
/* ------------ Message Log dialog box -------------- */
DIALOGBOX( Log )
    DB_TITLE(    "D-Flat Message Log", -1, -1, 18, 41)
    CONTROL(TEXT,  "~Messages",   10,   1,  1,  8, ID_LOGLIST)
    CONTROL(LISTBOX,    NULL,     1,    2, 14, 26, ID_LOGLIST)
    CONTROL(TEXT,    "~Logging:", 29,   4,  1, 10, ID_LOGGING)
    CONTROL(CHECKBOX,    NULL,    31,   5,  1,  3, ID_LOGGING)
    CONTROL(BUTTON,  "   ~OK   ", 29,   7,  1,  8, ID_OK)
    CONTROL(BUTTON,  " ~Cancel ", 29,  10,  1,  8, ID_CANCEL)
    CONTROL(BUTTON,  "  ~Help  ", 29,  13, 1,   8, ID_HELP)
ENDDB
#endif

/* ------------ the Help window dialog box -------------- */
/*
DIALOGBOX( HelpBox )
    DB_TITLE(         NULL,       -1, -1, 0, 45)
    CONTROL(TEXTBOX, NULL,         1,  1, 0, 40, ID_HELPTEXT)
    CONTROL(BUTTON,  "  ~Close ",  0,  0, 1,  8, ID_CANCEL)
    CONTROL(BUTTON,  "  ~Back  ", 10,  0, 1,  8, ID_BACK)
    CONTROL(BUTTON,  "<< ~Prev ", 20,  0, 1,  8, ID_PREV)
    CONTROL(BUTTON,  " ~Next >>", 30,  0, 1,  8, ID_NEXT)
ENDDB
*/
