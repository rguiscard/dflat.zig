// window.c
WINDOW cCreateWindow(CLASS,const char *,int,int,int,int,void*,WINDOW,
       int (*)(struct window *,enum messages,PARAM,PARAM),int);

// message.c
void c_dispatch_message(MESSAGE ev_event, int ev_mx, int ev_my);
