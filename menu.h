/* ------------ menu.h ------------- */

#ifndef MENU_H
#define MENU_H

/* ----------- popdown menu selection structure
       one for each selection on a popdown menu --------- */
struct PopDown {
    unsigned char *SelectionTitle; /* title of the selection */
    int ActionId;          /* the command executed        */
    int Accelerator;       /* the accelerator key         */
    int Attrib;  /* INACTIVE | CHECKED | TOGGLE | CASCADED*/
    char *help;            /* Help mnemonic               */
};

/* -------- menu selection attributes -------- */
#define INACTIVE    1
#define CHECKED     2
#define TOGGLE      4
#define CASCADED    8    

//int MenuHeight(struct PopDown *);
//int MenuWidth(struct PopDown *);

#endif
