const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const colors = @import("Colors.zig");

const CLASSCOUNT = 23;

// ----------- configuration parameters -----------
const Config = struct {
    version:[]const u8 = "0.3 pre-release",
    mono:usize = 0,           // 0=color, 1=mono, 2=reverse mono
    InsertMode:bool = true,   // Editor insert mode
    Tabs:usize = 4,           // Editor tab stops
    WordWrap:bool = true,     // True to word wrap editor
    Border:bool = true,       // True for application window border
    Title:bool = true,        // True for application window title
    StatusBar:bool = true,    // True for appl'n window status bar
    Texture:bool = true,      // True for textured appl window
    ScreenLines:usize = 25,   // Number of screen lines (25/43/50)
    clr:[CLASSCOUNT][4][2]u8 = colors.color, // Colors
};

pub var config:Config = .{};
var ConfigLoaded:bool = false;

//void BuildFileName(char *path, const char *fn, const char *ext)
//{
//    char *cp;
//
//    strcpy(path, Argv[0]);
//    cp = strrchr(path, '\\');
//    if (cp == NULL)
//        cp = path;
//    else 
//        cp++;
//    strcpy(cp, fn);
//    strcat(cp, ext);
//    }

//FILE *OpenConfig(char *mode)
//{
//    char path[MAXPATH];
//    BuildFileName(path, DFlatApplication, ".cfg");
//    return fopen(path, mode);
//}

// ------ load a configuration file from disk -------
pub fn Load() bool {
    if (ConfigLoaded == false) {
//            FILE *fp = OpenConfig("rb");
//        fp != NULL) {
//            fread(cfg.version, sizeof cfg.version+1, 1, fp);
//            if (strcmp(cfg.version, VERSION) == 0) {
//               fseek(fp, 0L, SEEK_SET);
//                fread(&cfg, sizeof(CONFIG), 1, fp);
//                fclose(fp);
//            }
//            else {
//                 char path[64];
//                 BuildFileName(path, DFlatApplication, ".cfg");
//                 fclose(fp);
//                 unlink(path);
//                 strcpy(cfg.version, VERSION);
//              }
//            ConfigLoaded = TRUE;
//     }
    }
    return ConfigLoaded;
}

// ------ save a configuration file to disk -------
pub fn Save() void {
//    FILE *fp = OpenConfig("wb");
//    if (fp != NULL)    {
//        fwrite((char *)&cfg, sizeof(CONFIG), 1, fp);
//        fclose(fp);
//    }
}

// Accessories, for porting
pub export fn cfgTabs() c_int {
    return @intCast(config.Tabs);
}
