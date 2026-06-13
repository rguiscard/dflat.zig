/* ---------- dfalloc.c ---------- */

#include "dflat.h"

static void AllocationError(void)
{
	WINDOW wnd;
	static BOOL OnceIn = FALSE;
	extern jmp_buf AllocError;
	extern BOOL AllocTesting;
	static char *ErrMsg[] = {
		"旼컴컴컴컴컴컴컴커",
		"� Out of Memory! �",
		"읕컴컴컴컴컴컴컴켸"
	};
	int x, y;
	videocell_t *savbuf = DFmalloc(216 * sizeof(videocell_t));
	RECT rc = {30,11,47,13};

	if (!OnceIn)	{
		OnceIn = TRUE;
		/* ------ close all windows ------ */
		SendMessage(ApplicationWindow, CLOSE_WINDOW, 0, 0);
        getvideo(rc, savbuf);
		for (x = 0; x < 18; x++)	{
			for (y = 0; y < 3; y++)		{
				videocell_t c = (videocell_t)(unsigned char)(*(*(ErrMsg+y)+x)) | 0x70000UL;
				PutVideoChar(x+rc.lf, y+rc.tp, c);
			}
		}
		convert_screen_to_ansi();
		getkey();
        storevideo(rc, savbuf);
		if (AllocTesting)
			longjmp(AllocError, 1);
	}
}

void *DFcalloc(size_t nitems, size_t size)
{
	void *rtn = calloc(nitems, size);
	if (size && rtn == NULL)
		AllocationError();
	return rtn;
}

void *DFmalloc(size_t size)
{
	void *rtn = malloc(size);
	if (size && rtn == NULL)
		AllocationError();
	return rtn;
}

void *DFrealloc(void *block, size_t size)
{
	void *rtn = realloc(block, size);
	if (size && rtn == NULL)
		AllocationError();
	return rtn;
}
