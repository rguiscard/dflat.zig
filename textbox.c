/* ------------- textbox.c ------------ */

#include "dflat.h"

static char *GetTextLine(WINDOW, int);

int getBlkBegLine(WINDOW);
int getBlkEndLine(WINDOW);
int getBlkBegCol(WINDOW);
int getBlkEndCol(WINDOW);
BOOL cTextBlockMarked(WINDOW);

/* ----- get the text to a specified line ----- */
#if 0
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
#endif

/* ------- write a line of text to a textbox window ------- */
void cWriteTextLine(WINDOW wnd, RECT rc, int y, char *src, BOOL reverse)
{
    int len = 0;
    int dif = 0;
    unsigned char *lp; //, *svlp;
    int lnlen;
    int i;
    BOOL trunc = FALSE;
    unsigned char line[MAXCOLS];

    /* --- get the text and length of the text line --- */
    //lp = svlp = GetTextLine(wnd, y);
    lp = src;
//    if (svlp == NULL)
//        return;
    lnlen = LineLength(lp);

//    FIXME: protect is not in use now
//	if (wnd->protect)	{
//		char *pp = lp;
//		while (*pp)	{
//			if (isprint(*pp))
//				*pp = '*';
//			pp++;
//		}
//	}

    /* -------- insert block color change controls ------- */
    if (cTextBlockMarked(wnd))    {
        int bbl = getBlkBegLine(wnd);
        int bel = getBlkEndLine(wnd);
        int bbc = getBlkBegCol(wnd);
        int bec = getBlkEndCol(wnd);
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
                RectLeft(rc)+c_BorderAdj(wnd),
                    y-wnd->wtop+c_TopBorderAdj(wnd), FALSE);
//    free(svlp);
}
