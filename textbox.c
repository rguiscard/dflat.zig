/* ------------- textbox.c ------------ */

#include "dflat.h"

void ComputeWindowTop(WINDOW);
void ComputeWindowLeft(WINDOW);
int ComputeVScrollBox(WINDOW);
int ComputeHScrollBox(WINDOW);
void MoveScrollBox(WINDOW, int);
static char *GetTextLine(WINDOW, int);

BOOL VSliding;
//BOOL HSliding;

/* ------------ ADDTEXT Message -------------- */
BOOL AddTextMsg(WINDOW wnd, char *txt)
{
    /* --- append text to the textbox's buffer --- */
    unsigned adln = strlen(txt);
    if (adln > (unsigned)0xfff0)
        return FALSE;
    if (wnd->text != NULL)    {
        /* ---- appending to existing text ---- */
        unsigned txln = strlen(wnd->text);
        if ((long)txln+adln > (unsigned) 0xfff0)
            return FALSE;
        if (txln+adln > wnd->textlen)    {
            wnd->text = DFrealloc(wnd->text, txln+adln+3);
            wnd->textlen = txln+adln+1;
        }
    }
    else    {
        /* ------ 1st text appended ------ */
        wnd->text = DFcalloc(1, adln+3);
        wnd->textlen = adln+1;
    }
	wnd->TextChanged = TRUE;
    if (wnd->text != NULL)    {
        /* ---- append the text ---- */
        strcat(wnd->text, txt);
        strcat(wnd->text, "\n");
        BuildTextPointers(wnd);
		return TRUE;
    }
	return FALSE;
}

/* ------------ DELETETEXT Message -------------- */
void DeleteTextMsg(WINDOW wnd, int lno)
{
	char *cp1 = TextLine(wnd, lno);
	--wnd->wlines;
	if (lno == wnd->wlines)
		*cp1 = '\0';
	else 	{
		char *cp2 = TextLine(wnd, lno+1);
		memmove(cp1, cp2, strlen(cp2)+1);
	}
    BuildTextPointers(wnd);
}

/* ------------ INSERTTEXT Message -------------- */
void InsertTextMsg(WINDOW wnd, char *txt, int lno)
{
	if (AddTextMsg(wnd, txt))	{
		int len = strlen(txt)+1;
		char *cp2 = TextLine(wnd, lno);
		char *cp1 = cp2+len;
		memmove(cp1, cp2, strlen(cp2)-len);
		strcpy(cp2, txt);
		*(cp2+len-1) = '\n';
	    BuildTextPointers(wnd);
		wnd->TextChanged = TRUE;
	}
}

/* ------------ CLOSE_WINDOW Message -------------- */
void CloseWindowMsg(WINDOW wnd)
{
    SendMessage(wnd, CLEARTEXT, 0, 0);
    if (wnd->TextPointers != NULL)    {
        free(wnd->TextPointers);
        wnd->TextPointers = NULL;
    }
}

/* ------ compute the vertical scroll box position from
                   the text pointers --------- */
int ComputeVScrollBox(WINDOW wnd)
{
    int pagelen = wnd->wlines - ClientHeight(wnd);
    int barlen = ClientHeight(wnd)-2;
    int lines_tick;
    int vscrollbox;

    if (pagelen < 1 || barlen < 1)
        vscrollbox = 1;
    else    {
        if (pagelen > barlen)
            lines_tick = pagelen / barlen;
        else
            lines_tick = barlen / pagelen;
        vscrollbox = 1 + (wnd->wtop / lines_tick);
        if (vscrollbox > ClientHeight(wnd)-2 ||
                wnd->wtop + ClientHeight(wnd) >= wnd->wlines)
            vscrollbox = ClientHeight(wnd)-2;
    }
    return vscrollbox;
}

/* ---- compute top text line from scroll box position ---- */
void ComputeWindowTop(WINDOW wnd)
{
    int pagelen = wnd->wlines - ClientHeight(wnd);
    if (wnd->VScrollBox == 0)
        wnd->wtop = 0;
    else if (wnd->VScrollBox == ClientHeight(wnd)-2)
        wnd->wtop = pagelen;
    else    {
        int barlen = ClientHeight(wnd)-2;
        int lines_tick;

        if (pagelen > barlen)
            lines_tick = barlen ? (pagelen / barlen) : 0;
        else
            lines_tick = pagelen ? (barlen / pagelen) : 0;
        wnd->wtop = (wnd->VScrollBox-1) * lines_tick;
        if (wnd->wtop + ClientHeight(wnd) > wnd->wlines)
            wnd->wtop = pagelen;
    }
    if (wnd->wtop < 0)
        wnd->wtop = 0;
}

/* ------ compute the horizontal scroll box position from
                   the text pointers --------- */
int ComputeHScrollBox(WINDOW wnd)
{
    int pagewidth = wnd->textwidth - ClientWidth(wnd);
    int barlen = ClientWidth(wnd)-2;
    int chars_tick;
    int hscrollbox;

    if (pagewidth < 1 || barlen < 1)
        hscrollbox = 1;
    else     {
        if (pagewidth > barlen)
            chars_tick = barlen ? (pagewidth / barlen) : 0;
        else
            chars_tick = pagewidth ? (barlen / pagewidth) : 0;
        hscrollbox = 1 + (chars_tick ? (wnd->wleft / chars_tick) : 0);
        if (hscrollbox > ClientWidth(wnd)-2 ||
                wnd->wleft + ClientWidth(wnd) >= wnd->textwidth)
            hscrollbox = ClientWidth(wnd)-2;
    }
    return hscrollbox;
}

/* ---- compute left column from scroll box position ---- */
void ComputeWindowLeft(WINDOW wnd)
{
    int pagewidth = wnd->textwidth - ClientWidth(wnd);

    if (wnd->HScrollBox == 0)
        wnd->wleft = 0;
    else if (wnd->HScrollBox == ClientWidth(wnd)-2)
        wnd->wleft = pagewidth;
    else    {
        int barlen = ClientWidth(wnd)-2;
        int chars_tick;

        if (pagewidth > barlen)
            chars_tick = pagewidth / barlen;
        else
            chars_tick = barlen / pagewidth;
        wnd->wleft = (wnd->HScrollBox-1) * chars_tick;
        if (wnd->wleft + ClientWidth(wnd) > wnd->textwidth)
            wnd->wleft = pagewidth;
    }
    if (wnd->wleft < 0)
        wnd->wleft = 0;
}

/* ----- get the text to a specified line ----- */
static char *GetTextLine(WINDOW wnd, int selection)
{
    char *line;
    int len = 0;
    char *cp, *cp1;
    cp = cp1 = TextLine(wnd, selection);
    while (*cp && *cp != '\n')    {
        len++;
        cp++;
    }
    line = DFmalloc(len+7);
    memmove(line, cp1, len);
    line[len] = '\0';
    return line;
}

/* ------- write a line of text to a textbox window ------- */
void WriteTextLine(WINDOW wnd, RECT *rcc, int y, BOOL reverse)
{
    int len = 0;
    int dif = 0;
    RECT rc;
    unsigned char *lp, *svlp;
    int lnlen;
    int i;
    BOOL trunc = FALSE;
    unsigned char line[MAXCOLS];

    /* ------ make sure y is inside the window ----- */
    if (y < wnd->wtop || y >= wnd->wtop+ClientHeight(wnd))
        return;

    /* ---- build the retangle within which can write ---- */
    if (rcc == NULL)    {
        rc = RelativeWindowRect(wnd, WindowRect(wnd));
        if (TestAttribute(wnd, HASBORDER) &&
                RectRight(rc) >= WindowWidth(wnd)-1)
            RectRight(rc) = WindowWidth(wnd)-2;
    }
    else
        rc = *rcc;

    /* ----- make sure rectangle is within window ------ */
    if (RectLeft(rc) >= WindowWidth(wnd)-1)
        return;
    if (RectRight(rc) == 0)
        return;
    rc = AdjustRectangle(wnd, rc);
    if (y-wnd->wtop<RectTop(rc) || y-wnd->wtop>RectBottom(rc))
        return;

    /* --- get the text and length of the text line --- */
    lp = svlp = GetTextLine(wnd, y);
    if (svlp == NULL)
        return;
    lnlen = LineLength(lp);

	if (wnd->protect)	{
		char *pp = lp;
		while (*pp)	{
			if (isprint(*pp))
				*pp = '*';
			pp++;
		}
	}

    /* -------- insert block color change controls ------- */
    if (TextBlockMarked(wnd))    {
        int bbl = wnd->BlkBegLine;
        int bel = wnd->BlkEndLine;
        int bbc = wnd->BlkBegCol;
        int bec = wnd->BlkEndCol;
        int by = y;

        /* ----- put lowest marker first ----- */
        if (bbl > bel)    {
            swap(bbl, bel);
            swap(bbc, bec);
        }
        if (bbl == bel && bbc > bec)
            swap(bbc, bec);

        if (by >= bbl && by <= bel)    {
            /* ------ the block includes this line ----- */
            int blkbeg = 0;
            int blkend = lnlen;
            if (!(by > bbl && by < bel))    {
                /* --- the entire line is not in the block -- */
                if (by == bbl)
                    /* ---- the block begins on this line --- */
                    blkbeg = bbc;
                if (by == bel)
                    /* ---- the block ends on this line ---- */
                    blkend = bec;
            }
			if (blkend == 0 && lnlen == 0)	{
				strcpy(lp, " ");
				blkend++;
			}
            /* ----- insert the reset color token ----- */
            memmove(lp+blkend+1,lp+blkend,strlen(lp+blkend)+1);
            lp[blkend] = RESETCOLOR;
            /* ----- insert the change color token ----- */
            memmove(lp+blkbeg+3,lp+blkbeg,strlen(lp+blkbeg)+1);
            lp[blkbeg] = CHANGECOLOR;
            /* ----- insert the color tokens ----- */
            SetReverseColor(wnd);
            lp[blkbeg+1] = foreground | 0x80;
            lp[blkbeg+2] = background | 0x80;
            lnlen += 4;
        }
    }
    /* - make sure left margin doesn't overlap color change - */
    for (i = 0; i < wnd->wleft+3; i++)    {
        if (*(lp+i) == '\0')
            break;
        if (*(unsigned char *)(lp + i) == RESETCOLOR)
            break;
    }
    if (*(lp+i) && i < wnd->wleft+3)    {
        if (wnd->wleft+4 > lnlen)
            trunc = TRUE;
        else 
            lp += 4;
    }
    else     {
        /* --- it does, shift the color change over --- */
        for (i = 0; i < wnd->wleft; i++)    {
            if (*(lp+i) == '\0')
                break;
            if (*(unsigned char *)(lp + i) == CHANGECOLOR)    {
                *(lp+wnd->wleft+2) = *(lp+i+2);
                *(lp+wnd->wleft+1) = *(lp+i+1);
                *(lp+wnd->wleft) = *(lp+i);
                break;
            }
        }
    }
    /* ------ build the line to display -------- */
    if (!trunc)    {
        if (lnlen < wnd->wleft)
            lnlen = 0;
        else
            lp += wnd->wleft;
        if (lnlen > RectLeft(rc))    {
            /* ---- the line exceeds the rectangle ---- */
            int ct = RectLeft(rc);
            char *initlp = lp;
            /* --- point to end of clipped line --- */
            while (ct)    {
                if (*(unsigned char *)lp == CHANGECOLOR)
                    lp += 3;
                else if (*(unsigned char *)lp == RESETCOLOR)
                    lp++;
                else
                    lp++, --ct;
            }
            if (RectLeft(rc))    {
                char *lpp = lp;
                while (*lpp)    {
                    if (*(unsigned char*)lpp==CHANGECOLOR)
                        break;
                    if (*(unsigned char*)lpp==RESETCOLOR) {
                        lpp = lp;
                        while (lpp >= initlp)    {
                            if (*(unsigned char *)lpp ==
                                            CHANGECOLOR) {
                                lp -= 3;
                                memmove(lp,lpp,3);
                                break;
                            }
                            --lpp;
                        }
                        break;
                    }
                    lpp++;
                }
            }
            lnlen = LineLength(lp);
            len = min(lnlen, RectWidth(rc));
            dif = strlen(lp) - lnlen;
            len += dif;
            if (len > 0)
                strncpy(line, lp, len);
        }
    }
    /* -------- pad the line --------- */
    while (len < RectWidth(rc)+dif)
        line[len++] = ' ';
    line[len] = '\0';
    dif = 0;
    /* ------ establish the line's main color ----- */
    if (reverse)    {
        char *cp = line;
        SetReverseColor(wnd);
        while ((cp = strchr(cp, CHANGECOLOR)) != NULL)    {
            cp += 2;
            *cp++ = background | 0x80;
        }
        if (*(unsigned char *)line == CHANGECOLOR)
            dif = 3;
    }
    else
        SetStandardColor(wnd);
    /* ------- display the line -------- */
    writeline(wnd, line+dif,
                RectLeft(rc)+BorderAdj(wnd),
                    y-wnd->wtop+TopBorderAdj(wnd), FALSE);
    free(svlp);
}

void MarkTextBlock(WINDOW wnd, int BegLine, int BegCol,
                               int EndLine, int EndCol)
{
    wnd->BlkBegLine = BegLine;
    wnd->BlkEndLine = EndLine;
    wnd->BlkBegCol = BegCol;
    wnd->BlkEndCol = EndCol;
}

/* ----- clear and initialize text line pointer array ----- */
void ClearTextPointers(WINDOW wnd)
{
    wnd->TextPointers = DFrealloc(wnd->TextPointers, sizeof(int));
    *(wnd->TextPointers) = 0;
}

#define INITLINES 100

/* ---- build array of pointers to text lines ---- */
void BuildTextPointers(WINDOW wnd)
{
    char *cp = wnd->text, *cp1;
    int incrs = INITLINES;
    unsigned int off;
    wnd->textwidth = wnd->wlines = 0;
    while (*cp)    {
        if (incrs == INITLINES)    {
            incrs = 0;
            wnd->TextPointers = DFrealloc(wnd->TextPointers,
                    (wnd->wlines + INITLINES) * sizeof(int));
        }
        off = (unsigned int) (cp - (char *)wnd->text);
        *((wnd->TextPointers) + wnd->wlines) = off;
        wnd->wlines++;
        incrs++;
        cp1 = cp;
        while (*cp && *cp != '\n')
            cp++;
        wnd->textwidth = max(wnd->textwidth,
                        (unsigned int) (cp - cp1));
        if (*cp)
            cp++;
    }
}

void MoveScrollBox(WINDOW wnd, int vscrollbox)
{
    foreground = FrameForeground(wnd);
    background = FrameBackground(wnd);
    wputch(wnd, SCROLLBARCHAR, WindowWidth(wnd)-1,
            wnd->VScrollBox+1);
    wputch(wnd, SCROLLBOXCHAR, WindowWidth(wnd)-1,
            vscrollbox+1);
    wnd->VScrollBox = vscrollbox;
}

int TextLineNumber(WINDOW wnd, char *lp)
{
    int lineno;
    char *cp;
    for (lineno = 0; lineno < wnd->wlines; lineno++)    {
        cp = wnd->text + *((wnd->TextPointers) + lineno);
        if (cp == lp)
            return lineno;
        if (cp > lp)
            break;
    }
    return lineno-1;
}
