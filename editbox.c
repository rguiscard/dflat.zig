/* ------------- editbox.c ------------ */
#include "dflat.h"

#define EditBufLen(wnd) (isMultiLine(wnd) ? EDITLEN : ENTRYLEN)
#define SetLinePointer(wnd, ln) (wnd->CurrLine = ln)
#define Ch(c) ((c)&0x7f)
#define isWhite(c) (Ch(c)==' '||Ch(c)=='\n'||Ch(c)=='\f'||Ch(c)=='\t')
/* ---------- local prototypes ----------- */
static void Forward(WINDOW);
static void Backward(WINDOW);
static void End(WINDOW);
static void Home(WINDOW);
static void Downward(WINDOW);
static void Upward(WINDOW);
void StickEnd(WINDOW);
static void NextWord(WINDOW);
static void PrevWord(WINDOW);
static void ModTextPointers(WINDOW, int, int);
void SetAnchor(WINDOW, int, int);
void ExtendBlock(WINDOW, int, int);

extern int ID_DELETETEXT; // from zig side

/* ----------- GETTEXT Message ---------- */
int GetTextMsg(WINDOW wnd, PARAM p1, PARAM p2)
{
    char *cp1 = (char *)p1;
    char *cp2 = wnd->text;
    if (cp2 != NULL)    {
        while (p2-- && *cp2 && *cp2 != '\n')
            *cp1++ = *cp2++;
        *cp1 = '\0';
        return TRUE;
    }
    return FALSE;
}

/* ----- Extend the marked block to the new x,y position ---- */
void ExtendBlock(WINDOW wnd, int x, int y)
{
    int bbl, bel;
    int ptop = min(wnd->BlkBegLine, wnd->BlkEndLine);
    int pbot = max(wnd->BlkBegLine, wnd->BlkEndLine);
    char *lp = TextLine(wnd, wnd->wtop+y);
    int len = (int) (strchr(lp, '\n') - lp);
    x = max(0, min(x, len));
	y = max(0, y);
    wnd->BlkEndCol = min(len, x+wnd->wleft);
    wnd->BlkEndLine = y+wnd->wtop;
    bbl = min(wnd->BlkBegLine, wnd->BlkEndLine);
    bel = max(wnd->BlkBegLine, wnd->BlkEndLine);
    while (ptop < bbl)    {
        WriteTextLine(wnd, NULL, ptop, FALSE);
        ptop++;
    }
    for (y = bbl; y <= bel; y++)
        WriteTextLine(wnd, NULL, y, FALSE);
    while (pbot > bel)    {
        WriteTextLine(wnd, NULL, pbot, FALSE);
        --pbot;
    }
}

/* ---------- page/scroll keys ----------- */
int ScrollingKey(WINDOW wnd, int c, PARAM p2)
{
    switch (c)    {
        case PGUP:
        case PGDN:
            if (isMultiLine(wnd))
                BaseWndProc(EDITBOX, wnd, KEYBOARD, c, p2);
            break;
        case CTRL_PGUP:
        case CTRL_PGDN:
            BaseWndProc(EDITBOX, wnd, KEYBOARD, c, p2);
            break;
        case HOME:
            Home(wnd);
            break;
        case END:
            End(wnd);
            break;
        case CTRL_FWD:
            NextWord(wnd);
            break;
        case CTRL_BS:
            PrevWord(wnd);
            break;
        case CTRL_HOME:
            if (isMultiLine(wnd))    {
                SendMessage(wnd, SCROLLDOC, TRUE, 0);
                wnd->CurrLine = 0;
                wnd->WndRow = 0;
            }
            Home(wnd);
            break;
        case CTRL_END:
			if (isMultiLine(wnd) &&
					wnd->WndRow+wnd->wtop+1 < wnd->wlines
						&& wnd->wlines > 0) {
                SendMessage(wnd, SCROLLDOC, FALSE, 0);
                SetLinePointer(wnd, wnd->wlines-1);
                wnd->WndRow =
                    min(ClientHeight(wnd)-1, wnd->wlines-1);
                Home(wnd);
            }
            End(wnd);
            break;
        case UP:
            if (isMultiLine(wnd))
                Upward(wnd);
            break;
        case DN:
            if (isMultiLine(wnd))
                Downward(wnd);
            break;
        case FWD:
            Forward(wnd);
            break;
        case BS:
            Backward(wnd);
            break;
        default:
            return FALSE;
    }

    return TRUE;
}
/* -------------- Del key ---------------- */
static void DelKey(WINDOW wnd)
{
    char *currchar = CurrChar;
    int repaint = *currchar == '\n';
    if (TextBlockMarked(wnd))    {
        SendMessage(wnd, COMMAND, ID_DELETETEXT, 0);
        SendMessage(wnd, PAINT, 0, 0);
        return;
    }
    if (isMultiLine(wnd) && *currchar == '\n' && *(currchar+1) == '\0')
        return;
    memmove(currchar, currchar+1, strlen(currchar+1));
    if (repaint)    {
        BuildTextPointers(wnd);
        SendMessage(wnd, PAINT, 0, 0);
    }
    else    {
        ModTextPointers(wnd, wnd->CurrLine+1, -1);
        WriteTextLine(wnd, NULL, wnd->WndRow+wnd->wtop, FALSE);
    }
    wnd->TextChanged = TRUE;
}
/* ------------ Tab key ------------ */
static void TabKey(WINDOW wnd, PARAM p2)
{
    if (isMultiLine(wnd))    {
        int insmd = wnd->InsertMode;
        do  {
            char *cc = CurrChar+1;
            if (!insmd && *cc == '\0')
                break;
            if (wnd->textlen == wnd->MaxTextLength)
                break;
            SendMessage(wnd,KEYBOARD,insmd ? ' ' : FWD,0);
        } while (wnd->CurrCol % cfg.Tabs);
    }
	else
	    PostMessage(GetParent(wnd), KEYBOARD, '\t', p2);
}
/* ------------ Shift+Tab key ------------ */
static void ShiftTabKey(WINDOW wnd, PARAM p2)
{
    if (isMultiLine(wnd))    {
        do  {
            if (CurrChar == GetText(wnd))
                break;
            SendMessage(wnd,KEYBOARD,BS,0);
        } while (wnd->CurrCol % cfg.Tabs);
    }
	else
	    PostMessage(GetParent(wnd), KEYBOARD, SHIFT_HT, p2);
}
/* --------- All displayable typed keys ------------- */
static void KeyTyped(WINDOW wnd, int c)
{
    char *currchar = CurrChar;
    if ((c != '\n' && c < ' ') || (c & 0x1000))
        /* ---- not recognized by editor --- */
        return;
    if (!isMultiLine(wnd) && TextBlockMarked(wnd))    {
		SendMessage(wnd, CLEARTEXT, 0, 0);
        currchar = CurrChar;
    }
    /* ---- test typing at end of text ---- */
    if (currchar == (char *)wnd->text+wnd->MaxTextLength)    {
        /* ---- typing at the end of maximum buffer ---- */
        beep();
        return;
    }
    if (*currchar == '\0')    {
        /* --- insert a newline at end of text --- */
        *currchar = '\n';
        *(currchar+1) = '\0';
        BuildTextPointers(wnd);
    }
    /* --- displayable char or newline --- */
    if (c == '\n' || wnd->InsertMode || *currchar == '\n') {
        /* ------ inserting the keyed character ------ */
        if (wnd->textlen == 0 || wnd->text[wnd->textlen-1] != '\0')    {
            /* --- the current text buffer is full --- */
            if (wnd->textlen == wnd->MaxTextLength)    {
                /* --- text buffer is at maximum size --- */
                beep();
                return;
            }
            /* ---- increase the text buffer size ---- */
            wnd->textlen += GROWLENGTH;
            /* --- but not above maximum size --- */
            if (wnd->textlen > wnd->MaxTextLength)
                wnd->textlen = wnd->MaxTextLength;
            wnd->text = DFrealloc(wnd->text, wnd->textlen+2);
            wnd->text[wnd->textlen-1] = '\0';
            currchar = CurrChar;
        }
        memmove(currchar+1, currchar, strlen(currchar)+1);
        ModTextPointers(wnd, wnd->CurrLine+1, 1);
        if (isMultiLine(wnd) && wnd->wlines > 1)
            wnd->textwidth = max(wnd->textwidth,
                (int) (TextLine(wnd, wnd->CurrLine+1)-
                TextLine(wnd, wnd->CurrLine)));
        else
            wnd->textwidth = max(wnd->textwidth,
                strlen(wnd->text));
        WriteTextLine(wnd, NULL,
            wnd->wtop+wnd->WndRow, FALSE);
    }
    /* ----- put the char in the buffer ----- */
    *currchar = c;
    wnd->TextChanged = TRUE;
    if (c == '\n')    {
        wnd->wleft = 0;
        BuildTextPointers(wnd);
        End(wnd);
        Forward(wnd);
        SendMessage(wnd, PAINT, 0, 0);
        return;
    }
    /* ---------- test end of window --------- */
    if (WndCol == ClientWidth(wnd)-1)    {
        if (!isMultiLine(wnd))	{
			if (!(currchar == (char *)wnd->text+wnd->MaxTextLength-2))
            SendMessage(wnd, HORIZSCROLL, TRUE, 0);
		}
		else	{
			char *cp = currchar;
	        while (*cp != ' ' && cp != (char *)TextLine(wnd, wnd->CurrLine))
	            --cp;
	        if (cp == (char *)TextLine(wnd, wnd->CurrLine) ||
	                !wnd->WordWrapMode)
	            SendMessage(wnd, HORIZSCROLL, TRUE, 0);
	        else    {
	            int dif = 0;
	            if (c != ' ')    {
	                dif = (int) (currchar - cp);
	                wnd->CurrCol -= dif;
	                SendMessage(wnd, KEYBOARD, DEL, 0);
	                --dif;
	            }
	            SendMessage(wnd, KEYBOARD, '\n', 0);
	            currchar = CurrChar;
	            wnd->CurrCol = dif;
	            if (c == ' ')
	                return;
	        }
	    }
	}
    /* ------ display the character ------ */
    SetStandardColor(wnd);
	if (wnd->protect)
		c = '*';
    PutWindowChar(wnd, c, WndCol, wnd->WndRow);
    /* ----- advance the pointers ------ */
    wnd->CurrCol++;
}

/* ------------ screen changing key strokes ------------- */
void DoKeyStroke(WINDOW wnd, int c, PARAM p2)
{
    switch (c)    {
        case RUBOUT:
			if (wnd->CurrCol == 0 && wnd->CurrLine == 0)
				break;
			SendMessage(wnd, KEYBOARD, BS, 0);
			SendMessage(wnd, KEYBOARD, DEL, 0);
			break;
        case DEL:
            DelKey(wnd);
            break;
        case SHIFT_HT:
            ShiftTabKey(wnd, p2);
            break;
        case '\t':
            TabKey(wnd, p2);
            break;
        case '\r':
            if (!isMultiLine(wnd))    {
                PostMessage(GetParent(wnd), KEYBOARD, c, p2);
                break;
            }
            c = '\n';
        default:
            if (TextBlockMarked(wnd))    {
                SendMessage(wnd, COMMAND, ID_DELETETEXT, 0);
                SendMessage(wnd, PAINT, 0, 0);
            }
            KeyTyped(wnd, c);
            break;
    }
}

// ------ change all text lines in block to \n -----
void TextBlockToN(char *bbl, char *bel) {
        while (bbl < bel)    {
            char *cp = strchr(bbl, '\n');
            if (cp > bel)
                cp = bel;
            strcpy(bbl, cp);
            bel -= (int) (cp - bbl);
            bbl++;
        }
}

/* ----------- ID_PARAGRAPH Command ---------- */
// Rewrite to be called from  zig size
void ParagraphCmd(WINDOW wnd)
{
    int bc, fl;
    char *bl, *bbl, *bel, *bb;

    /* ---- forming paragraph from cursor position --- */
    fl = wnd->wtop + wnd->WndRow;
    bbl = bel = bl = TextLine(wnd, wnd->CurrLine);
    if ((bc = wnd->CurrCol) >= ClientWidth(wnd))
        bc = 0;
    Home(wnd);
    /* ---- locate the end of the paragraph ---- */
    while (*bel)    {
        int blank = TRUE;
        char *bll = bel;
        /* --- blank line marks end of paragraph --- */
        while (*bel && *bel != '\n')    {
            if (*bel != ' ')
                blank = FALSE;
            bel++;
        }
        if (blank)    {
            bel = bll;
            break;
        }
        if (*bel)
            bel++;
    }
    if (bel == bbl)    {
        SendMessage(wnd, KEYBOARD, DN, 0);
        return;
    }
    if (*bel == '\0')
        --bel;
    if (*bel == '\n')
        --bel;
    /* --- change all newlines in block to spaces --- */
    while ((char *)CurrChar < bel)    {
        if (*CurrChar == '\n')    {
            *CurrChar = ' ';
            wnd->CurrLine++;
            wnd->CurrCol = 0;
        }
        else
            wnd->CurrCol++;
    }
    /* ---- insert newlines at new margin boundaries ---- */
    bb = bbl;
    while (bbl < bel)    {
        bbl++;
        if ((int)(bbl - bb) == ClientWidth(wnd)-1)    {
            while (*bbl != ' ' && bbl > bb)
                --bbl;
            if (*bbl != ' ')    {
                bbl = strchr(bbl, ' ');
                if (bbl == NULL || bbl >= bel)
                    break;
            }
            *bbl = '\n';
            bb = bbl+1;
        }
    }
    BuildTextPointers(wnd);
    /* --- put cursor back at beginning --- */
    wnd->CurrLine = TextLineNumber(wnd, bl);
    wnd->CurrCol = bc;
    if (fl < wnd->wtop)
        wnd->wtop = fl;
    wnd->WndRow = fl - wnd->wtop;
}

/* ---- cursor right key: right one character position ---- */
static void Forward(WINDOW wnd)
{
    char *cc = CurrChar+1;
    if (*cc == '\0')
        return;
    if (*CurrChar == '\n')    {
        Home(wnd);
        Downward(wnd);
    }
    else    {
        wnd->CurrCol++;
        if (WndCol == ClientWidth(wnd))
            SendMessage(wnd, HORIZSCROLL, TRUE, 0);
    }
}
/* ----- stick the moving cursor to the end of the line ---- */
void StickEnd(WINDOW wnd)
{
    char *cp = TextLine(wnd, wnd->CurrLine);
    char *cp1 = strchr(cp, '\n');
    int len = cp1 ? (int) (cp1 - cp) : 0;
    wnd->CurrCol = min(len, wnd->CurrCol);
    if (wnd->wleft > wnd->CurrCol)    {
        wnd->wleft = max(0, wnd->CurrCol - 4);
        SendMessage(wnd, PAINT, 0, 0);
    }
    else if (wnd->CurrCol-wnd->wleft >= ClientWidth(wnd))    {
        wnd->wleft = wnd->CurrCol - (ClientWidth(wnd)-1);
        SendMessage(wnd, PAINT, 0, 0);
    }
}
/* --------- cursor down key: down one line --------- */
static void Downward(WINDOW wnd)
{
    if (isMultiLine(wnd) &&
            wnd->WndRow+wnd->wtop+1 < wnd->wlines)  {
        wnd->CurrLine++;
        if (wnd->WndRow == ClientHeight(wnd)-1)
			SendMessage(wnd, SCROLL, TRUE, 0);
        wnd->WndRow++;
        StickEnd(wnd);
    }
}
/* -------- cursor up key: up one line ------------ */
static void Upward(WINDOW wnd)
{
    if (isMultiLine(wnd) && wnd->CurrLine != 0)    {
        --wnd->CurrLine;
        if (wnd->WndRow == 0)
			SendMessage(wnd, SCROLL, FALSE, 0);
        --wnd->WndRow;
        StickEnd(wnd);
    }
}
/* ---- cursor left key: left one character position ---- */
static void Backward(WINDOW wnd)
{
    if (wnd->CurrCol)    {
        --wnd->CurrCol;
        if (wnd->CurrCol < wnd->wleft)
            SendMessage(wnd, HORIZSCROLL, FALSE, 0);
    }
    else if (isMultiLine(wnd) && wnd->CurrLine != 0)    {
        Upward(wnd);
        End(wnd);
    }
}
/* -------- End key: to end of line ------- */
static void End(WINDOW wnd)
{
    while (*CurrChar && *CurrChar != '\n')
        ++wnd->CurrCol;
    if (WndCol >= ClientWidth(wnd))    {
        wnd->wleft = wnd->CurrCol - (ClientWidth(wnd)-1);
        SendMessage(wnd, PAINT, 0, 0);
    }
}
/* -------- Home key: to beginning of line ------- */
static void Home(WINDOW wnd)
{
    wnd->CurrCol = 0;
    if (wnd->wleft != 0)    {
        wnd->wleft = 0;
        SendMessage(wnd, PAINT, 0, 0);
    }
}
/* -- Ctrl+cursor right key: to beginning of next word -- */
static void NextWord(WINDOW wnd)
{
    int savetop = wnd->wtop;
    int saveleft = wnd->wleft;
    ClearVisible(wnd);
    while (!isWhite(*CurrChar))    {
        char *cc = CurrChar+1;
        if (*cc == '\0')
            break;
        Forward(wnd);
    }
    while (isWhite(*CurrChar))    {
        char *cc = CurrChar+1;
        if (*cc == '\0')
            break;
        Forward(wnd);
    }
    SetVisible(wnd);
    SendMessage(wnd, KEYBOARD_CURSOR, WndCol, wnd->WndRow);
    if (wnd->wtop != savetop || wnd->wleft != saveleft)
        SendMessage(wnd, PAINT, 0, 0);
}
/* -- Ctrl+cursor left key: to beginning of previous word -- */
static void PrevWord(WINDOW wnd)
{
    int savetop = wnd->wtop;
    int saveleft = wnd->wleft;
    ClearVisible(wnd);
    Backward(wnd);
    while (isWhite(*CurrChar))    {
        if (wnd->CurrLine == 0 && wnd->CurrCol == 0)
            break;
        Backward(wnd);
    }
    while (wnd->CurrCol != 0 && !isWhite(*CurrChar))
        Backward(wnd);
    if (isWhite(*CurrChar))
        Forward(wnd);
    SetVisible(wnd);
    if (wnd->wleft != saveleft)
        if (wnd->CurrCol >= saveleft)
            if (wnd->CurrCol - saveleft < ClientWidth(wnd))
                wnd->wleft = saveleft;
    SendMessage(wnd, KEYBOARD_CURSOR, WndCol, wnd->WndRow);
    if (wnd->wtop != savetop || wnd->wleft != saveleft)
        SendMessage(wnd, PAINT, 0, 0);
}
/* ----- modify text pointers from a specified position
                by a specified plus or minus amount ----- */
static void ModTextPointers(WINDOW wnd, int lineno, int var)
{
    while (lineno < wnd->wlines)
        *((wnd->TextPointers) + lineno++) += var;
}
/* ----- set anchor point for marking text block ----- */
void SetAnchor(WINDOW wnd, int mx, int my)
{
    ClearTextBlock(wnd);
    /* ------ set the anchor ------ */
    wnd->BlkBegLine = wnd->BlkEndLine = my;
    wnd->BlkBegCol = wnd->BlkEndCol = mx;
    SendMessage(wnd, PAINT, 0, 0);
}
