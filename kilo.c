/* ------------- kilo.c ------------- */
#include "kilo.h"

/* Forward declarations */
static int ComputeKiloVScrollBox(WINDOW wnd);
static int ComputeKiloHScrollBox(WINDOW wnd);

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
void kiloRenderLine(WINDOW wnd, int yscreen, int yclient)
{
    SetStandardColor(wnd);
    
    int xwin = BorderAdj(wnd);  /* Window-relative x for client area */
    int render_width = ClientWidth(wnd);
    
    kilo_state *k = GetKiloState(wnd);
    int filerow = k->rowoff + yclient;
    
    if (filerow >= k->numrows) {
        /* Blank line */
        wputuchline(wnd, ' ', xwin, TopBorderAdj(wnd) + yclient, render_width);
        return;
    }
    
    kilo_row *row = &k->row[filerow];
    int len = row->rsize - k->coloff;
    
    if (len <= 0) {
        wputuchline(wnd, ' ', xwin, TopBorderAdj(wnd) + yclient, render_width);
        return;
    }
    
    if (len > render_width)
        len = render_width;
    
    /* Convert to uint32_t for writeline */
    uint32_t uline[MAXCOLS];
    int i;
    for (i = 0; i < len; i++) {
        uline[i] = (uint32_t)(unsigned char)row->render[k->coloff + i];
    }
    uline[len] = 0;
    
    /* writeline expects window-relative coordinates */
    writeline(wnd, uline, xwin, TopBorderAdj(wnd) + yclient);
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
    
    /* Skip non-client areas */
    if (TestAttribute(wnd, HASBORDER | HASTITLEBAR)) {
        if (RectTop(rc) < TopBorderAdj(wnd))
            RectTop(rc) = TopBorderAdj(wnd);
        if (RectBottom(rc) >= WindowHeight(wnd) - BottomBorderAdj(wnd))
            RectBottom(rc) = WindowHeight(wnd) - BottomBorderAdj(wnd) - 1;
    }
    
    /* Adjust for border - don't overwrite right border scrollbar */
    if (TestAttribute(wnd, HASBORDER) && RectRight(rc) >= WindowWidth(wnd) - 1) {
        if (RectLeft(rc) >= WindowWidth(wnd) - 1)
            return TRUE;
        RectRight(rc) = WindowWidth(wnd) - 2;
    }
    
    rc = AdjustRectangle(wnd, rc);
    int render_width = ClientWidth(wnd);
    
    /* Clear the client area first */
    SetStandardColor(wnd);
    for (y = RectTop(rc); y <= RectBottom(rc); y++) {
        int yy = y - TopBorderAdj(wnd);
        if (yy >= 0 && yy < ClientHeight(wnd))
            wputuchline(wnd, ' ', BorderAdj(wnd), y, render_width);
    }
    
    for (y = RectTop(rc); y <= RectBottom(rc); y++) {
        /* y is screen coordinate; convert to client-relative */
        int yy = y - TopBorderAdj(wnd);
        if (yy >= 0 && yy < ClientHeight(wnd))
            kiloRenderLine(wnd, y, yy);
    }
    
    /* Update scrollbar position */
    if (TestAttribute(wnd, VSCROLLBAR)) {
        kilo_state *k = GetKiloState(wnd);
        int vscrollbox = ComputeKiloVScrollBox(wnd);
        if (vscrollbox != wnd->VScrollBox) {
            wnd->VScrollBox = vscrollbox;
            SendMessage(wnd, BORDER, p1, 0);
        }
    }
    
    if (TestAttribute(wnd, HSCROLLBAR)) {
        kilo_state *k = GetKiloState(wnd);
        int hscrollbox = ComputeKiloHScrollBox(wnd);
        if (hscrollbox != wnd->HScrollBox) {
            wnd->HScrollBox = hscrollbox;
            SendMessage(wnd, BORDER, p1, 0);
        }
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
    
    /* Clamp cursor to new window size */
    kilo_state *k = GetKiloState(wnd);
    
    int maxcol = ClientWidth(wnd) - 1;
    if (k->cx > maxcol && maxcol >= 0)
        k->cx = maxcol;
    
    int maxrow = ClientHeight(wnd) - 1;
    if (k->cy > maxrow && maxrow >= 0)
        k->cy = maxrow;
    
    /* Clamp rowoff to valid range */
    if (k->rowoff + k->cy >= k->numrows && k->numrows > 0)
        k->rowoff = max(0, k->numrows - ClientHeight(wnd));
    
    /* Clamp coloff to valid range */
    int maxlen = 0;
    int i;
    for (i = 0; i < k->numrows; i++) {
        if (k->row[i].rsize > maxlen)
            maxlen = k->row[i].rsize;
    }
    if (k->coloff + k->cx >= maxlen && maxlen > 0)
        k->coloff = max(0, maxlen - ClientWidth(wnd));
    
    SendMessage(wnd, PAINT, 0, 0);
    SendMessage(wnd, KEYBOARD_CURSOR, k->cx, k->cy);
    
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
    int mx = (int)p1 - GetLeft(wnd);
    int my = (int)p2 - GetTop(wnd);
    
    /* Handle sizing (bottom-right corner) - fall through to base proc */
    if (mx == WindowWidth(wnd) - 1 && my == WindowHeight(wnd) - 1) {
        return FALSE;
    }
    
    if (TestAttribute(wnd, VSCROLLBAR) && mx == WindowWidth(wnd) - 1) {
        /* Click on vertical scrollbar - adjust rowoff */
        kilo_state *k = GetKiloState(wnd);
        
        if (my == 1) {
            /* Top arrow: show earlier lines (rowoff decreases) */
            if (k->rowoff > 0) {
                k->rowoff--;
                SendMessage(wnd, PAINT, 0, 0);
                SendMessage(wnd, KEYBOARD_CURSOR, k->cx, k->cy);
            }
            return TRUE;
        }
        if (my == WindowHeight(wnd) - 2) {
            /* Bottom arrow: show later lines (rowoff increases) */
            if (k->rowoff + ClientHeight(wnd) < k->numrows) {
                k->rowoff++;
                SendMessage(wnd, PAINT, 0, 0);
                SendMessage(wnd, KEYBOARD_CURSOR, k->cx, k->cy);
            }
            return TRUE;
        }
        /* Click on scrollbar track */
        int barlen = ClientHeight(wnd) - 2;
        if (my >= 2 && my <= barlen + 1) {
            int pagelen = k->numrows - ClientHeight(wnd);
            int new_rowoff;
            if (pagelen > barlen)
                new_rowoff = (my - 1) * pagelen / barlen;
            else
                new_rowoff = my - 1;
            
            if (new_rowoff != k->rowoff) {
                k->rowoff = new_rowoff;
                SendMessage(wnd, PAINT, 0, 0);
                SendMessage(wnd, KEYBOARD_CURSOR, k->cx, k->cy);
            }
        }
        return TRUE;
    }
    
    if (TestAttribute(wnd, HSCROLLBAR) && my == WindowHeight(wnd) - 1) {
        /* Click on horizontal scrollbar - adjust coloff */
        kilo_state *k = GetKiloState(wnd);
        
        if (mx == 1) {
            /* Left arrow: scroll left */
            if (k->coloff > 0) {
                k->coloff--;
                SendMessage(wnd, PAINT, 0, 0);
                SendMessage(wnd, KEYBOARD_CURSOR, k->cx, k->cy);
            }
            return TRUE;
        }
        if (mx == WindowWidth(wnd) - 2) {
            /* Right arrow: scroll right - but not over VSCROLLBAR */
            int maxlen = 0;
            int i;
            for (i = 0; i < k->numrows; i++) {
                if (k->row[i].rsize > maxlen)
                    maxlen = k->row[i].rsize;
            }
            if (k->coloff + ClientWidth(wnd) < maxlen) {
                k->coloff++;
                SendMessage(wnd, PAINT, 0, 0);
                SendMessage(wnd, KEYBOARD_CURSOR, k->cx, k->cy);
            }
            return TRUE;
        }
        
        /* Click on scrollbar track - scroll to position */
        int barlen = ClientWidth(wnd) - 2;
        int maxlen = 0;
        int i;
        for (i = 0; i < k->numrows; i++) {
            if (k->row[i].rsize > maxlen)
                maxlen = k->row[i].rsize;
        }
        int pagelen = maxlen - ClientWidth(wnd);
        
        if (mx >= 2 && mx <= barlen + 1) {
            int new_coloff;
            if (pagelen > barlen)
                new_coloff = (mx - 1) * pagelen / barlen;
            else
                new_coloff = mx - 1;
            
            if (new_coloff != k->coloff) {
                k->coloff = new_coloff;
                SendMessage(wnd, PAINT, 0, 0);
                SendMessage(wnd, KEYBOARD_CURSOR, k->cx, k->cy);
            }
        }
        return TRUE;
    }
    
    RECT rc = ClientRect(wnd);
    if (!InsideRect(p1, p2, rc))
        return FALSE;
    
    /* Convert screen to editor coordinates */
    kiloSetCursorFromScreen(wnd, mx, my);
    kilo_state *k = GetKiloState(wnd);
    SendMessage(wnd, KEYBOARD_CURSOR, k->cx, k->cy);
    return TRUE;
}

/* --- HORIZSCROLL Message --- */
static int HorizScrollMsg(WINDOW wnd, PARAM p1)
{
    kilo_state *k = GetKiloState(wnd);
    int cw = ClientWidth(wnd);
    int maxlen = 0;
    int i;
    
    /* Find max line length */
    for (i = 0; i < k->numrows; i++) {
        if (k->row[i].rsize > maxlen)
            maxlen = k->row[i].rsize;
    }
    
    if ((int)p1) {
        /* ----- scroll right (coloff increases) ----- */
        if (k->coloff + cw >= maxlen)
            return FALSE;
        k->coloff++;
    } else {
        /* ----- scroll left (coloff decreases) ----- */
        if (k->coloff == 0)
            return FALSE;
        k->coloff--;
    }
    
    SendMessage(wnd, PAINT, 0, 0);
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

/* ------ compute the vertical scroll box position for Kilo editor ------ */
static int ComputeKiloVScrollBox(WINDOW wnd)
{
    kilo_state *k = GetKiloState(wnd);
    int pagelen = k->numrows - ClientHeight(wnd);
    int barlen = ClientHeight(wnd) - 2;
    int vscrollbox;
    
    if (pagelen < 1 || barlen < 1)
        return 1;
    
    if (pagelen > barlen)
        vscrollbox = 1 + (k->rowoff * barlen / pagelen);
    else
        vscrollbox = 1 + k->rowoff;
    
    if (vscrollbox > barlen)
        vscrollbox = barlen;
    
    return vscrollbox;
}

/* ------ compute the horizontal scroll box position for Kilo editor ------ */
static int ComputeKiloHScrollBox(WINDOW wnd)
{
    kilo_state *k = GetKiloState(wnd);
    int maxlen = 0;
    int i;
    for (i = 0; i < k->numrows; i++) {
        if (k->row[i].rsize > maxlen)
            maxlen = k->row[i].rsize;
    }
    int pagelen = maxlen - ClientWidth(wnd);
    int barlen = ClientWidth(wnd) - 2;
    int hscrollbox;
    
    if (pagelen < 1 || barlen < 1)
        return 1;
    
    if (pagelen > barlen)
        hscrollbox = 1 + (k->coloff * barlen / pagelen);
    else
        hscrollbox = 1 + k->coloff;
    
    if (hscrollbox > barlen)
        hscrollbox = barlen;
    
    return hscrollbox;
}

/* --- SCROLL Message --- */
static int ScrollMsg(WINDOW wnd, PARAM p1)
{
    kilo_state *k = GetKiloState(wnd);
    int ch = ClientHeight(wnd);
    
    if ((int)p1)    {
        /* ----- scroll one line up ----- */
        if (k->rowoff + ch >= k->numrows)
            return FALSE;
        k->rowoff++;
    }
    else {
        /* ----- scroll one line down ----- */
        if (k->rowoff == 0)
            return FALSE;
        k->rowoff--;
    }
    
    SendMessage(wnd, PAINT, 0, 0);
    SendMessage(wnd, KEYBOARD_CURSOR, k->cx, k->cy);
    return TRUE;
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
            /* Don't call BaseWndProc for PAINT - we handle our own rendering */
            return PaintMsg(wnd, p1, p2);
        case SETTEXT:
            return SetTextMsg(wnd, p1);
        case CLEARTEXT:
            return ClearTextMsg(wnd);
        case SIZE:
            return SizeMsg(wnd, p1, p2);
        case SCROLL:
            return ScrollMsg(wnd, p1);
        case HORIZSCROLL:
            return HorizScrollMsg(wnd, p1);
        case KEYBOARD:
            return KeyboardMsg(wnd, p1, p2);
        case LEFT_BUTTON:
            if (!WindowSizing && LeftButtonMsg(wnd, p1, p2))
                return TRUE;
            break;
        case BUTTON_RELEASED:
            if (WindowSizing || WindowMoving) {
                SendMessage(wnd, PAINT, 0, 0);
                SendMessage(wnd, KEYBOARD_CURSOR, 0, 0);
            }
            break;
        case CLOSE_WINDOW:
            return CloseWindowMsg(wnd, p1, p2);
        default:
            break;
    }
    return BaseWndProc(KILO, wnd, msg, p1, p2);
}
