/* ----------- rect.h ------------ */
#ifndef RECT_H
#define RECT_H

typedef struct    {
    int lf,tp,rt,bt;
} RECT;

#define RectLeft(r)       (r.lf)
#define RectRight(r)      (r.rt)
#define RectWidth(r)      (RectRight(r)-RectLeft(r)+1)

#endif
