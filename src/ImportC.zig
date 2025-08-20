pub const df = @cImport({
    @cDefine("BUILD_FULL_DFLAT", {});
    @cInclude("dflat.h");
});

// All zig codes which need C should import this file so that the C struct is not import multiple times.
// Each @import creates different types even though underneath C struct is the same.
// @cImport should only be called once in the whole code base.
