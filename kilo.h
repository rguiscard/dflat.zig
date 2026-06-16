/* ------------- kilo.h ------------- */
#ifndef KILO_H
#define KILO_H

#include "dflat.h"

/* Per-window kilo editor state */
typedef struct kilo_state {
    int cx, cy;           /* Cursor position in rendered coordinates */
    int rowoff;           /* Row offset for scrolling */
    int coloff;           /* Column offset for scrolling */
    int numrows;          /* Number of rows in the editor */
    struct kilo_row *row; /* Array of editor rows */
    int dirty;            /* Text has been modified */
} kilo_state;

/* erow - single line of text (from kilo, adapted for dflat) */
typedef struct kilo_row {
    int idx;              /* Row index, zero-based */
    int size;             /* Size of chars, excluding null term */
    int rsize;            /* Size of render, excluding null term */
    char *chars;          /* Original text content */
    char *render;         /* Rendered content (tabs expanded) */
} kilo_row;

/* Function prototypes */
kilo_state *GetKiloState(WINDOW wnd);
void FreeKiloState(WINDOW wnd);

/* Row operations */
void kiloInsertRow(WINDOW wnd, int at, char *s, size_t len);
void kiloDelRow(WINDOW wnd, int at);
void kiloRowInsertChar(WINDOW wnd, int at, int c);
void kiloRowDelChar(WINDOW wnd, int at);
void kiloUpdateRow(WINDOW wnd, kilo_row *row);
void kiloFreeRow(kilo_row *row);

/* Rendering */
void kiloRenderLine(WINDOW wnd, int y);

/* Editor operations */
void kiloInsertChar(WINDOW wnd, int c);
void kiloInsertNewline(WINDOW wnd);
void kiloDelChar(WINDOW wnd);
void kiloMoveCursor(WINDOW wnd, int key);
void kiloSetCursorFromScreen(WINDOW wnd, int x, int y);

/* Text conversion */
char *kiloRowsToString(WINDOW wnd, int *buflen);

/* Process messages */
int KiloProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);

#endif