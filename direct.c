/* ---------- direct.c --------- */

#include "dflat.h"
#include <dirent.h>
#include <sys/stat.h>

/* Check if fspec is a directory, if so chdir and return TRUE */
int CheckAndChangeDir(char *fspec)
{
    char *cp;
    char path[MAXPATH];

    if (chdir(fspec) == 0)
        return TRUE;
    strcpy(path, fspec);
    cp = strrchr(path, '/');
    if (cp) {
        if (cp != path)
            *cp = '\0';
        if (chdir(path) == 0)
            return TRUE;
    }
    return FALSE;
}

/*
 * Routine to see if a text string is matched by a wildcard pattern.
 * Returns TRUE if the text is matched, or FALSE if it is not matched
 * or if the pattern is invalid.
 *  *		matches zero or more characters
 *  ?		matches a single character
 *  [abc]	matches 'a', 'b' or 'c'
 *  \c		quotes character c
 *
 * Adapted from code written by Ingo Wilken.
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 */
static int match(char *text, char *pattern)
{
	char	*retrypat;
	char	*retrytxt;
	int	ch;
	int	found;

	if (pattern[0] == '\0')
		return TRUE;

	retrypat = NULL;
	retrytxt = NULL;

	while (*text || *pattern) {
		ch = *pattern++;

		switch (ch) {
			case '*':
				retrypat = pattern;
				retrytxt = text;
				break;

			case '[':
				found = FALSE;
				while ((ch = *pattern++) != ']') {
					if (ch == '\\')
						ch = *pattern++;
					if (ch == '\0')
						return FALSE;
					if (*text == ch)
						found = TRUE;
				}
				if (!found) {
					pattern = retrypat;
					text = ++retrytxt;
				}
				/* fall into next case */

			case '?':
				if (*text++ == '\0')
					return FALSE;
				break;

			case '\\':
				ch = *pattern++;
				if (ch == '\0')
					return FALSE;
				/* fall into next case */

			default:
				if (*text == ch) {
					if (*text)
						text++;
					break;
				}
				if (*text) {
					pattern = retrypat;
					text = ++retrytxt;
					break;
				}
				return FALSE;
		}

		if (pattern == NULL)
			return FALSE;
	}
	return TRUE;
}
static int dircmp(const void *c1, const void *c2)
{
    return strcasecmp(*(char **)c1, *(char **)c2);
}

void cBuildList(WINDOW lwnd, char *fspec, BOOL dirs)
{
	// ct always exists. it is checked on zig side.
	// make this function private after porting.
        char **dirlist = NULL;
        DIR *dirp;
        int i = 0, j;
        struct dirent *dp;
        struct stat sb;

//        SendMessage(lwnd, CLEARTEXT, 0, 0);

        dirp = opendir(".");
        if (dirp) {
            while ((dp = readdir(dirp)) != NULL) {
                if (dp->d_name[0] == '.' && dp->d_name[1] != '.')
                    continue;
                if (stat(dp->d_name, &sb) < 0)
                    continue;
                if (S_ISDIR(sb.st_mode) == dirs) {
                    if (match(dp->d_name, fspec)) {
                        dirlist = DFrealloc(dirlist, sizeof(char *)*(i+1));
                        dirlist[i] = DFmalloc(strlen(dp->d_name)+1);
                        strcpy(dirlist[i++], dp->d_name);
                    }
                }
            }
            closedir(dirp);
        }
        if (dirlist != NULL)    {
            int j;
            /* -- sort file or directory list box data -- */
            qsort(dirlist, i, sizeof(void *), dircmp);
            /* ---- send sorted list to list box ---- */
            for (j = 0; j < i; j++)    {
                SendMessage(lwnd,ADDTEXT,(PARAM)dirlist[j],0);
                free(dirlist[j]);
            }
            free(dirlist);
		}
//        SendMessage(lwnd, SHOW_WINDOW, 0, 0);
}
