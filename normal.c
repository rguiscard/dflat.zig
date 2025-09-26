/* ------------- normal.c ------------ */

#include "dflat.h"

#if 0
BOOL isVisible(WINDOW wnd)
{
    while (wnd != NULL)    {
        if (isHidden(wnd))
            return FALSE;
        wnd = GetParent(wnd);
    }
    return TRUE;
}
#endif
