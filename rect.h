/* ----------- rect.h ------------ */
#ifndef RECT_H
#define RECT_H

typedef struct    {
    int lf,tp,rt,bt;
} RECT;
#define RectTop(r)        (r.tp)
#define RectBottom(r)     (r.bt)
#define RectLeft(r)       (r.lf)
#define RectRight(r)      (r.rt)

#define RectWidth(r)      (RectRight(r)-RectLeft(r)+1)
#define RectHeight(r)     (RectBottom(r)-RectTop(r)+1)
RECT RelativeWindowRect(void *, RECT);
#endif
