/* ------------- config.c ------------- */

#include "dflat.h"

char DFlatApplication[] = "memopad";
char **Argv;

/* ------ default configuration values ------- */
CONFIG cfg = {
    VERSION,
    0,               /* Color                       */
    TRUE,            /* Editor Insert Mode          */
    4,               /* Editor tab stops            */
    TRUE,            /* Editor word wrap            */
    TRUE,            /* Application Border          */
    TRUE,            /* Application Title           */
    TRUE,            /* Status Bar                  */
    TRUE,            /* Textured application window */
    25,              /* Number of screen lines      */
};

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

FILE *OpenConfig(char *mode)
{
	char path[MAXPATH];
	BuildFileName(path, DFlatApplication, ".cfg");
	return fopen(path, mode);
}

/* ------ load a configuration file from disk ------- */
BOOL LoadConfig(void)
{
	static BOOL ConfigLoaded = FALSE;
	if (ConfigLoaded == FALSE)	{
	    FILE *fp = OpenConfig("rb");
    	if (fp != NULL)    {
        	fread(cfg.version, sizeof cfg.version+1, 1, fp);
        	if (strcmp(cfg.version, VERSION) == 0)    {
            	fseek(fp, 0L, SEEK_SET);
            	fread(&cfg, sizeof(CONFIG), 1, fp);
 		       	fclose(fp);
        	}
        	else	{
				char path[64];
				BuildFileName(path, DFlatApplication, ".cfg");
	        	fclose(fp);
				unlink(path);
            	strcpy(cfg.version, VERSION);
			}
			ConfigLoaded = TRUE;
    	}
	}
    return ConfigLoaded;
}

/* ------ save a configuration file to disk ------- */
void SaveConfig(void)
{
    FILE *fp = OpenConfig("wb");
    if (fp != NULL)    {
        fwrite((char *)&cfg, sizeof(CONFIG), 1, fp);
        fclose(fp);
    }
}

/* --------- set window colors --------- */
void SetStandardColor(WINDOW wnd)
{
    foreground = WndForeground(wnd);
    background = WndBackground(wnd);
}

void SetReverseColor(WINDOW wnd)
{
    foreground = SelectForeground(wnd);
    background = SelectBackground(wnd);
}
