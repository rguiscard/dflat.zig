/* ------------- rect.c --------------- */

#include "dflat.h"

/* ------- return the client rectangle of a window ------ */
#if 0
RECT ClientRect(void *wnd)
{
    RECT rc;

    RectLeft(rc) = c_GetClientLeft((WINDOW)wnd);
    RectTop(rc) = c_GetClientTop((WINDOW)wnd);
    RectRight(rc) = c_GetClientRight((WINDOW)wnd);
    RectBottom(rc) = c_GetClientBottom((WINDOW)wnd);
    return rc;
}
#endif

/* ----- return the rectangle relative to
            its window's screen position -------- */
#if 0
RECT RelativeWindowRect(void *wnd, RECT rc)
{
    RectLeft(rc) -= GetLeft((WINDOW)wnd);
    RectRight(rc) -= GetLeft((WINDOW)wnd);
    RectTop(rc) -= GetTop((WINDOW)wnd);
    RectBottom(rc) -= GetTop((WINDOW)wnd);
    return rc;
}
#endif
