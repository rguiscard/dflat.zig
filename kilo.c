/* ------------- kilo.c ------------- */
#include "kilo.h"

/* Get or create the per-window kilo editor state */
kilo_state *GetKiloState(WINDOW wnd)
{
    kilo_state *k = (kilo_state *)wnd->extension;
    if (k == NULL) {
        k = DFcalloc(1, sizeof(kilo_state));
        wnd->extension = k;
    }
    return k;
}

void FreeKiloState(WINDOW wnd)
{
    kilo_state *k = (kilo_state *)wnd->extension;
    if (k != NULL) {
        int i;
        for (i = 0; i < k->numrows; i++) {
            kiloFreeRow(&k->row[i]);
            free(k->row[i].chars);
        }
        free(k->row);
        free(k);
        wnd->extension = NULL;
    }
}

/* Update rendered version of a row (expands tabs) */
void kiloUpdateRow(WINDOW wnd, kilo_row *row)
{
    int tabs = 0;
    int j;
    int idx;

    /* Count tabs */
    for (j = 0; j < row->size; j++)
        if (row->chars[j] == '\t')
            tabs++;

    /* Allocate render buffer */
    free(row->render);
    row->render = DFmalloc(row->size + tabs * 8 + 1);
    row->rsize = 0;
    idx = 0;
    for (j = 0; j < row->size; j++) {
        if (row->chars[j] == '\t') {
            row->render[idx++] = ' ';
            while ((idx + 1) % cfg.Tabs == 0)
                row->render[idx++] = ' ';
        } else {
            row->render[idx++] = row->chars[j];
        }
    }
    row->render[idx] = '\0';
    row->rsize = idx;
}

/* Free row's heap allocated stuff */
void kiloFreeRow(kilo_row *row)
{
    free(row->render);
    row->render = NULL;
}

/* Insert a row at the specified position */
void kiloInsertRow(WINDOW wnd, int at, char *s, size_t len)
{
    kilo_state *k = GetKiloState(wnd);
    
    if (at > k->numrows) 
        at = k->numrows;
    
    k->row = DFrealloc(k->row, sizeof(kilo_row) * (k->numrows + 1));
    
    /* Shift rows if inserting in middle */
    if (at != k->numrows) {
        memmove(k->row + at + 1, k->row + at, sizeof(kilo_row) * (k->numrows - at));
        for (int j = at + 1; j <= k->numrows; j++)
            k->row[j].idx = j;
    }
    
    k->row[at].size = len;
    k->row[at].chars = DFmalloc(len + 1);
    memcpy(k->row[at].chars, s, len);
    k->row[at].chars[len] = '\0';
    k->row[at].idx = at;
    k->row[at].render = NULL;
    k->row[at].rsize = 0;
    
    kiloUpdateRow(wnd, &k->row[at]);
    k->numrows++;
    k->dirty++;
}

/* Remove a row */
void kiloDelRow(WINDOW wnd, int at)
{
    kilo_state *k = GetKiloState(wnd);
    
    if (at >= k->numrows) 
        return;
    
    kiloFreeRow(&k->row[at]);
    free(k->row[at].chars);
    
    if (at < k->numrows - 1) {
        memmove(k->row + at, k->row + at + 1, sizeof(kilo_row) * (k->numrows - at - 1));
        for (int j = at; j < k->numrows - 1; j++)
            k->row[j].idx = j;
    }
    k->numrows--;
    k->dirty++;
}

/* Insert character at cursor position */
void kiloRowInsertChar(WINDOW wnd, int at, int c)
{
    kilo_state *k = GetKiloState(wnd);
    int filerow = k->rowoff + k->cy;
    kilo_row *row;
    
    if (filerow >= k->numrows) {
        /* Add empty rows as needed */
        while (k->numrows <= filerow) {
            kiloInsertRow(wnd, k->numrows, "", 0);
        }
    }
    
    row = &k->row[filerow];
    
    if (at > row->size) {
        /* Pad with spaces if needed */
        int padlen = at - row->size;
        row->chars = DFrealloc(row->chars, row->size + padlen + 2);
        memset(row->chars + row->size, ' ', padlen);
        row->chars[row->size + padlen + 1] = '\0';
        row->size += padlen + 1;
    } else {
        row->chars = DFrealloc(row->chars, row->size + 2);
        memmove(row->chars + at + 1, row->chars + at, row->size - at + 1);
        row->size++;
    }
    row->chars[at] = c;
    kiloUpdateRow(wnd, row);
    k->dirty++;
}

/* Delete character at cursor position */
void kiloRowDelChar(WINDOW wnd, int at)
{
    kilo_state *k = GetKiloState(wnd);
    int filerow = k->rowoff + k->cy;
    kilo_row *row;
    
    if (filerow >= k->numrows) 
        return;
    
    row = &k->row[filerow];
    
    if (row->size <= at) 
        return;
    
    memmove(row->chars + at, row->chars + at + 1, row->size - at);
    kiloUpdateRow(wnd, row);
    row->size--;
    k->dirty++;
}

/* Render a line to the window */
void kiloRenderLine(WINDOW wnd, int y)
{
    kilo_state *k = GetKiloState(wnd);
    int filerow = k->rowoff + y;
    
    if (filerow >= k->numrows) {
        /* Blank line */
        wputuchline(wnd, ' ', 0, y, ClientWidth(wnd));
        return;
    }
    
    kilo_row *row = &k->row[filerow];
    int len = row->rsize - k->coloff;
    
    if (len <= 0) {
        wputuchline(wnd, ' ', 0, y, ClientWidth(wnd));
        return;
    }
    
    if (len > ClientWidth(wnd))
        len = ClientWidth(wnd);
    
    /* Convert to uint32_t for writeline */
    uint32_t uline[MAXCOLS];
    int i;
    for (i = 0; i < len; i++) {
        uline[i] = (uint32_t)(unsigned char)row->render[k->coloff + i];
    }
    uline[len] = 0;
    
    writeline(wnd, uline, 0, y);
}

/* --- CREATE_WINDOW Message --- */
static int CreateWindowMsg(WINDOW wnd)
{
    BaseWndProc(KILO, wnd, CREATE_WINDOW, 0, 0);
    return TRUE;
}

/* --- PAINT Message --- */
static int PaintMsg(WINDOW wnd, PARAM p1, PARAM p2)
{
    int y;
    RECT rc;
    
    /* Build the rectangle to paint */
    if ((RECT *)p1 == NULL)
        rc = RelativeWindowRect(wnd, WindowRect(wnd));
    else
        rc = *(RECT *)p1;
    
    rc = AdjustRectangle(wnd, rc);
    
    for (y = RectTop(rc); y <= RectBottom(rc); y++) {
        int yy = y - TopBorderAdj(wnd);
        if (yy >= 0 && yy < ClientHeight(wnd))
            kiloRenderLine(wnd, yy);
    }
    return TRUE;
}

/* --- SETTEXT Message --- */
static int SetTextMsg(WINDOW wnd, PARAM p1)
{
    char *txt = (char *)p1;
    char *line = DFmalloc(MAXCOLS);
    char *p = txt;
    
    kilo_state *k = GetKiloState(wnd);
    
    /* Clear existing rows */
    int i;
    for (i = 0; i < k->numrows; i++) {
        free(k->row[i].chars);
        free(k->row[i].render);
    }
    free(k->row);
    k->row = NULL;
    k->numrows = 0;
    
    /* Insert each line */
    while (*p) {
        int len = 0;
        while (p[len] && p[len] != '\n')
            len++;
        
        kiloInsertRow(wnd, k->numrows, p, len);
        p += len;
        if (*p == '\n')
            p++;
    }
    
    k->dirty = 0;
    free(line);
    return TRUE;
}

/* --- CLEARTEXT Message --- */
static int ClearTextMsg(WINDOW wnd)
{
    kilo_state *k = GetKiloState(wnd);
    
    int i;
    for (i = 0; i < k->numrows; i++) {
        free(k->row[i].chars);
        free(k->row[i].render);
    }
    free(k->row);
    k->row = NULL;
    k->numrows = 0;
    k->dirty = 0;
    k->cx = k->cy = k->rowoff = k->coloff = 0;
    
    return TRUE;
}

/* --- SIZE Message --- */
static int SizeMsg(WINDOW wnd, PARAM p1, PARAM p2)
{
    BaseWndProc(KILO, wnd, SIZE, p1, p2);
    
    /* Adjust cursor position if it's now out of bounds */
    kilo_state *k = GetKiloState(wnd);
    int maxcol = ClientWidth(wnd) - 1;
    
    if (k->cx > maxcol)
        k->cx = maxcol;
    
    return TRUE;
}

/* --- KEYBOARD Message --- */
static int KeyboardMsg(WINDOW wnd, PARAM p1, PARAM p2)
{
    int c = (int)p1;
    kilo_state *k = GetKiloState(wnd);
    int filerow, filecol;
    
    if (WindowMoving || WindowSizing || ((int)p2 & ALTKEY))
        return FALSE;
    
    switch (c) {
        case '\t':
        case SHIFT_HT:
        case ESC:
        case F1: case F2: case F3: case F4: case F5:
        case F6: case F7: case F8: case F9: case F10:
        case INS: case SHIFT_INS: case SHIFT_DEL:
            /* Pass through to parent or ignore */
            return FALSE;
            
        case UP:
            if (k->cy == 0) {
                if (k->rowoff > 0)
                    k->rowoff--;
            } else {
                k->cy--;
            }
            break;
            
        case DN:
            if (k->rowoff + k->cy + 1 >= k->numrows)
                break;
            if (k->cy == ClientHeight(wnd) - 1)
                k->rowoff++;
            else
                k->cy++;
            break;
            
        case BS:  /* Left arrow */
            if (k->cx == 0) {
                if (k->coloff > 0) {
                    k->coloff--;
                } else if (k->rowoff + k->cy > 0) {
                    /* Move to end of previous line */
                    k->cy--;
                    k->cx = k->row[k->rowoff + k->cy].rsize;
                    if (k->cx > ClientWidth(wnd) - 1) {
                        k->coloff = k->cx - (ClientWidth(wnd) - 1);
                        k->cx = ClientWidth(wnd) - 1;
                    }
                }
            } else {
                k->cx--;
            }
            break;
            
        case FWD:  /* Right arrow */
            filerow = k->rowoff + k->cy;
            if (filerow < k->numrows) {
                int rowlen = k->row[filerow].rsize;
                if (k->cx + k->coloff < rowlen) {
                    if (k->cx == ClientWidth(wnd) - 1)
                        k->coloff++;
                    else
                        k->cx++;
                } else if (filerow + 1 < k->numrows) {
                    /* Move to start of next line */
                    k->cx = 0;
                    k->coloff = 0;
                    k->cy++;
                }
            }
            break;
            
        case PGUP:
            if (k->rowoff > 0) {
                k->rowoff -= ClientHeight(wnd);
                if (k->rowoff < 0)
                    k->rowoff = 0;
            } else {
                k->cy = 0;
            }
            break;
            
        case PGDN:
            if (k->rowoff + k->cy + ClientHeight(wnd) < k->numrows) {
                k->rowoff += ClientHeight(wnd);
            } else {
                /* Scroll to end */
                k->rowoff = k->numrows - ClientHeight(wnd);
                if (k->rowoff < 0)
                    k->rowoff = 0;
                if (k->rowoff + k->cy >= k->numrows)
                    k->cy = k->numrows - k->rowoff - 1;
                if (k->cy < 0)
                    k->cy = 0;
            }
            break;
            
        case HOME:
            k->cx = 0;
            k->coloff = 0;
            break;
            
        case END:
            filerow = k->rowoff + k->cy;
            if (filerow < k->numrows) {
                k->cx = k->row[filerow].rsize - k->coloff;
                if (k->cx > ClientWidth(wnd) - 1) {
                    k->coloff = k->row[filerow].rsize - (ClientWidth(wnd) - 1);
                    k->cx = ClientWidth(wnd) - 1;
                } else if (k->cx < 0)
                    k->cx = 0;
            }
            break;
            
        case '\r':
            /* Enter - insert newline */
            {
                filerow = k->rowoff + k->cy;
                filecol = k->coloff + k->cx;
                kilo_row *row = (filerow < k->numrows) ? &k->row[filerow] : NULL;
                
                if (!row) {
                    if (filerow == k->numrows)
                        kiloInsertRow(wnd, k->numrows, "", 0);
                    row = &k->row[filerow];
                }
                
                int filecol_adjusted = filecol;
                if (filecol_adjusted > row->size)
                    filecol_adjusted = row->size;
                
                if (filecol_adjusted == 0) {
                    kiloInsertRow(wnd, filerow, "", 0);
                } else {
                    /* Split line */
                    kiloInsertRow(wnd, filerow + 1, row->chars + filecol_adjusted, 
                                  row->size - filecol_adjusted);
                    row->chars[filecol_adjusted] = '\0';
                    row->size = filecol_adjusted;
                    kiloUpdateRow(wnd, row);
                }
                
                if (k->cy == ClientHeight(wnd) - 1)
                    k->rowoff++;
                else
                    k->cy++;
                k->cx = 0;
                k->coloff = 0;
            }
            break;
            
        default:
            if (((c & ~0x7F) == 0) && (isprint(c) || c == '\r')) {
                kiloRowInsertChar(wnd, k->coloff + k->cx, c);
                
                filerow = k->rowoff + k->cy;
                if (k->cx == ClientWidth(wnd) - 1)
                    k->coloff++;
                else
                    k->cx++;
            } else {
                return FALSE;
            }
            break;
    }
    
    /* Clamp cursor to line length */
    filerow = k->rowoff + k->cy;
    if (filerow < k->numrows) {
        int rowlen = k->row[filerow].rsize;
        int filecol = k->coloff + k->cx;
        if (filecol > rowlen) {
            k->cx -= filecol - rowlen;
            if (k->cx < 0) {
                k->coloff += k->cx;
                k->cx = 0;
            }
        }
    }
    
    SendMessage(wnd, PAINT, 0, 0);
    SendMessage(wnd, KEYBOARD_CURSOR, k->cx, k->cy);
    return TRUE;
}

/* --- LEFT_BUTTON Message --- */
static int LeftButtonMsg(WINDOW wnd, PARAM p1, PARAM p2)
{
    RECT rc = ClientRect(wnd);
    int mx = (int)p1 - GetClientLeft(wnd);
    int my = (int)p2 - GetClientTop(wnd);
    
    if (!InsideRect(p1, p2, rc))
        return FALSE;
    
    /* Convert screen to editor coordinates */
    kiloSetCursorFromScreen(wnd, mx, my);
    kilo_state *k = GetKiloState(wnd);
    SendMessage(wnd, KEYBOARD_CURSOR, k->cx, k->cy);
    return TRUE;
}

/* Convert screen position to editor cursor position */
void kiloSetCursorFromScreen(WINDOW wnd, int x, int y)
{
    kilo_state *k = GetKiloState(wnd);
    
    if (y < 0) 
        y = 0;
    if (y >= ClientHeight(wnd))
        y = ClientHeight(wnd) - 1;
    
    k->cy = y;
    k->rowoff = max(0, k->rowoff); /* Keep rowoff valid */
    
    /* Find the column position */
    int filerow = k->rowoff + k->cy;
    if (filerow >= k->numrows)
        return;
    
    kilo_row *row = &k->row[filerow];
    
    /* Simple column mapping - could be improved for tabs */
    k->cx = x;
    k->coloff = 0;
    
    if (k->cx > row->rsize)
        k->cx = row->rsize;
}

/* --- CLOSE_WINDOW Message --- */
static int CloseWindowMsg(WINDOW wnd, PARAM p1, PARAM p2)
{
    FreeKiloState(wnd);
    return BaseWndProc(KILO, wnd, CLOSE_WINDOW, p1, p2);
}

/* --- Window-processing module for KILO class --- */
int KiloProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2)
{
    switch (msg) {
        case CREATE_WINDOW:
            return CreateWindowMsg(wnd);
        case PAINT:
            return PaintMsg(wnd, p1, p2);
        case SETTEXT:
            return SetTextMsg(wnd, p1);
        case CLEARTEXT:
            return ClearTextMsg(wnd);
        case SIZE:
            return SizeMsg(wnd, p1, p2);
        case KEYBOARD:
            return KeyboardMsg(wnd, p1, p2);
        case LEFT_BUTTON:
            if (LeftButtonMsg(wnd, p1, p2))
                return TRUE;
            break;
        case CLOSE_WINDOW:
            return CloseWindowMsg(wnd, p1, p2);
        default:
            break;
    }
    return BaseWndProc(KILO, wnd, msg, p1, p2);
}
