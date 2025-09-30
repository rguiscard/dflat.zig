/* ------------- config.c ------------- */

#include "dflat.h"

char DFlatApplication[] = "memopad";
char **Argv;

void BuildFileName(char *path, const char *fn, const char *ext)
{
    char *cp;

	strcpy(path, Argv[0]);
	cp = strrchr(path, '\\');
	if (cp == NULL)
		cp = path;
	else 
		cp++;
	strcpy(cp, fn);
	strcat(cp, ext);
}
