const std = @import("std");
const posix = std.posix;

pub fn run() !u32 {
    // --- Save old handlers ---
    var save_quit: posix.Sigaction = undefined;
    posix.sigaction(posix.SIG.QUIT, &.{
        .handler = .{ .handler = posix.SIG.IGN },
        .mask = posix.sigemptyset(),
        .flags = 0,
    }, &save_quit);


    var save_int: posix.Sigaction = undefined;
    posix.sigaction(posix.SIG.INT, &.{
        .handler = .{ .handler = posix.SIG.IGN },
        .mask = posix.sigemptyset(),
        .flags = 0,
    }, &save_int);

    // --- Fork ---
    const pid = try posix.fork();

    if (pid == 0) {
        // --- Child ---
        posix.sigaction(posix.SIG.QUIT, &.{
            .handler = .{ .handler = posix.SIG.DFL },
            .mask = posix.sigemptyset(),
            .flags = 0,
        }, null);

        posix.sigaction(posix.SIG.INT, &.{
            .handler = .{ .handler = posix.SIG.DFL },
            .mask = posix.sigemptyset(),
            .flags = 0,
        }, null);

        // execl("/bin/sh", "sh", NULL)
        const path:[:0]const u8 = "/bin/sh";
//        const args = [_:null]?[*:0]u8{.{"sh"}};
        const env = [_:null]?[*:0]u8{};

        posix.execveZ(path, &.{"sh"}, &env) catch posix.exit(127);

        unreachable;
    }

    // --- Parent: ignore signals while waiting ---
    _ = posix.sigaction(posix.SIG.QUIT, &.{
        .handler = .{ .handler = posix.SIG.IGN },
        .mask = posix.sigemptyset(),
        .flags = 0,
    }, null);

    _ = posix.sigaction(posix.SIG.INT, &.{
        .handler = .{ .handler = posix.SIG.IGN },
        .mask = posix.sigemptyset(),
        .flags = 0,
    }, null);

    // --- Wait for child ---
    var status: u32 = 0;
    while (true) {
        const ret = posix.waitpid(pid, 0);
        status = ret.status;
        // FIXME: handle error ?
        if (ret.pid == pid) break;
    }

    // --- Restore previous handlers ---
    _ = posix.sigaction(posix.SIG.QUIT, &save_quit, null);
    _ = posix.sigaction(posix.SIG.INT, &save_int, null);

    return status;
}
