/* ---------- direct.c --------- */

#include "dflat.h"
#include <dirent.h>
#include <sys/stat.h>

static char path[MAXPATH];
#if MSDOS
static char drive[MAXDRIVE] = " :";
static char dir[MAXDIR];
static char name[MAXFILE];
static char ext[MAXEXT];
#endif

/* ----- Create unambiguous path from file spec, filling in the
     drive and directory if incomplete. Optionally change to
     the new drive and subdirectory ------ */
void CreatePath(char *spath,char *fspec,int InclName,int Change)
{
#if UNIX
    strcpy(spath, fspec);
#else
    int cm = 0;
    unsigned currdrive;
    char currdir[MAXPATH+1];
    char *cp;

    if (!Change)    {
        /* ---- save the current drive and subdirectory ---- */
        currdrive = getdisk();
        getcwd(currdir, sizeof currdir);
        memmove(currdir, currdir+2, strlen(currdir+1));
        cp = currdir+strlen(currdir)-1;
        if (*cp == '\\')
            *cp = '\0';
    }
    *drive = *dir = *name = *ext = '\0';
    fnsplit(fspec, drive, dir, name, ext);
    if (!InclName)
        *name = *ext = '\0';
    *drive = toupper(*drive);
    if (*ext)
        cm |= EXTENSION;
    if (InclName && *name)
        cm |= FILENAME;
    if (*dir)
        cm |= DIRECTORY;
    if (*drive)
        cm |= DRIVE;
    if (cm & DRIVE)
        setdisk(*drive - 'A');
    else     {
        *drive = getdisk();
        *drive += 'A';
    }
    if (cm & DIRECTORY)    {
        cp = dir+strlen(dir)-1;
        if (*cp == '\\')
            *cp = '\0';
        chdir(dir);
    }
    getcwd(dir, sizeof dir);
    memmove(dir, dir+2, strlen(dir+1));
    if (InclName)    {
        if (!(cm & FILENAME))
            strcpy(name, "*");
        if (!(cm & EXTENSION) && strchr(fspec, '.') != NULL)
            strcpy(ext, ".*");
    }
    else
        *name = *ext = '\0';
    if (dir[strlen(dir)-1] != '\\')
        strcat(dir, "\\");
	if (spath != NULL)
    	fnmerge(spath, drive, dir, name, ext);
    if (!Change)    {
        setdisk(currdrive);
        chdir(currdir);
    }
#endif
}

static int dircmp(const void *c1, const void *c2)
{
    return strcasecmp(*(char **)c1, *(char **)c2);
}

static BOOL BuildList(WINDOW wnd, char *fspec, BOOL dirs)
{
    CTLWINDOW *ct = FindCommand(wnd->extension,
                            dirs ? ID_DIRECTORY : ID_FILES,LISTBOX);
    WINDOW lwnd;
    char **dirlist = NULL;

    if (ct != NULL)    {
        DIR *dirp;
        int i = 0, j;
        struct dirent *dp;
        struct stat sb;

        lwnd = ct->wnd;
        SendMessage(lwnd, CLEARTEXT, 0, 0);

        dirp = opendir(".");
        if (dirp) {
            while ((dp = readdir(dirp)) != NULL) {
                if (dp->d_name[0] == '.' && dp->d_name[1] != '.')
                    continue;
                if (stat(dp->d_name, &sb) < 0)
                    continue;
                if (S_ISDIR(sb.st_mode) == dirs) {
                    dirlist = DFrealloc(dirlist, sizeof(char *)*(i+1));
                    dirlist[i] = DFmalloc(strlen(dp->d_name)+1);
                    strcpy(dirlist[i++], dp->d_name);
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
        SendMessage(lwnd, SHOW_WINDOW, 0, 0);
    }
	return TRUE;
}

BOOL BuildFileList(WINDOW wnd, char *fspec)
{
	return BuildList(wnd, fspec, FALSE);
}

void BuildDirectoryList(WINDOW wnd)
{
	BuildList(wnd, "*.*", TRUE);
}

void BuildPathDisplay(WINDOW wnd)
{
    CTLWINDOW *ct = FindCommand(wnd->extension, ID_PATH,TEXT);
	if (ct != NULL)	{
		int len;
	    WINDOW lwnd = ct->wnd;
		CreatePath(path, "*.*", FALSE, FALSE);
		len = strlen(path);
		if (len > 3)
			path[len-1] = '\0';
       	SendMessage(lwnd,SETTEXT,(PARAM)path,0);
        SendMessage(lwnd, PAINT, 0, 0);
	}
}
