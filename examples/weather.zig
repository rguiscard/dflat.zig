pub const DFlatApplication = "memopad";

var textbox:?*mp.Window = null;

pub fn main() !void {
//    const argv = std.os.argv.ptr; // already C-compatible

    if (mp.q.init_messages() == false) {
        return;
    }

//    df.Argv = @ptrCast(argv);

    const win = mp.Window.create(mp.CLASS.APPLICATION,
                        "Weather",
                        0, 0, 0, 0,
                        null, // main menu
                        null,
                        WeatherProc,
                        df.CONTROLBOX |
                        df.HASBORDER,
                        mp.Window.CENTER_SIZE);

    textbox = mp.Window.create(mp.CLASS.TEXTBOX,
                    "Weather",
                    25, 2, @intCast(df.SCREENHEIGHT-14), @intCast(df.SCREENWIDTH-28),
                    null, win, textBoxProc,
                df.SHADOW     |
                df.HASBORDER  |
                df.MULTILINE,
                    .{});
    if (textbox) |box| {
        const txt =
            \\
            \\ Choose location on the right for weather information
            ;
        _ = box.sendTextMessage(df.SETTEXT, txt);
        _ = box.sendMessage(df.SHOW_WINDOW, mp.q.none);
    }

    const usageBox = mp.Window.create(mp.CLASS.TEXT,
                    "Usage",
                    2, 18, 9, @intCast(df.SCREENWIDTH-4),
                    null, win, usageBoxProc,
                df.SHADOW     |
                df.HASBORDER  |
                df.MULTILINE,
                    .{});
    const text =
        \\
        \\ Ctrl+C to quit, or double-click top-left corner to close.
        \\
        \\ Please wait a few seconds for retriving information through internet.
        \\ Network activity blocks user interface in this single-thread application.
        \\
        \\ Data from wttr.in
        ;
    _ = usageBox.sendTextMessage(df.SETTEXT, text);
    _ = usageBox.sendMessage(df.SHOW_WINDOW, mp.q.none);

    const listbox = mp.Window.create(mp.CLASS.LISTBOX,
                    "Locations",
                    2, 2, @intCast(df.SCREENHEIGHT-14), 21,
                    null, win, listBoxProc,
                df.SHADOW     |
                df.HASBORDER,
                    .{});
    _ = listbox.sendTextMessage(df.ADDTEXT, "Current Place");
    _ = listbox.sendTextMessage(df.ADDTEXT, "New_York");
    _ = listbox.sendTextMessage(df.ADDTEXT, "San_Francisco");
    _ = listbox.sendTextMessage(df.ADDTEXT, "Tokyo");
    _ = listbox.sendTextMessage(df.ADDTEXT, "Singapore");
    _ = listbox.sendTextMessage(df.ADDTEXT, "Dubai");
    _ = listbox.sendTextMessage(df.ADDTEXT, "Cairo");
    _ = listbox.sendTextMessage(df.ADDTEXT, "Paris");
    _ = listbox.sendMessage(df.LB_SETSELECTION, .{.select =.{0, 0}});
    _ = listbox.sendMessage(df.SHOW_WINDOW, mp.q.none);

    while (mp.q.dispatch_message()) {
    }
}

fn WeatherProc(win:*mp.Window, msg: df.MESSAGE, params:mp.q.Params) bool {
    switch(msg) {
        else => {
        }
    }
    return mp.DefaultWndProc(win, msg, params);
}

fn textBoxProc(win:*mp.Window, msg: df.MESSAGE, params:mp.q.Params) bool {
    switch (msg) {
        else => {
        }
    }
    return mp.DefaultWndProc(win, msg, params);
}

fn showWeather(location:?[]const u8) void {
    if (textbox) |win| {
        if (getWeather(location)) |output| {
            _ = win.sendTextMessage(df.SETTEXT, output);
            _ = win.sendMessage(df.SHOW_WINDOW, mp.q.none);
        } else |_| {
        }
    }
}

fn listBoxProc(win:*mp.Window, msg: df.MESSAGE, params:mp.q.Params) bool {
    switch (msg) {
        df.LB_SELECTION => {
            const rtn = mp.DefaultWndProc(win, msg, params);
            var sel:?usize = null;
            var buf = [_]u8{0}**64;
            _ = win.sendMessage(df.LB_CURRENTSELECTION, .{.usize_addr=&sel});
            if (sel) |s| {
                if (s == 0) {
                    showWeather(null);
                } else {
                    _ = win.sendMessage(df.LB_GETTEXT, .{.get_text=.{&buf, s}});
                    if (std.mem.indexOfScalar(u8, &buf, 0)) |pos| {
                        showWeather(buf[0..pos]);
                    } else {
                    }
                }
            }
            return rtn;
        },
        else => {
        }
    }
    return mp.DefaultWndProc(win, msg, params);
}

fn usageBoxProc(win:*mp.Window, msg: df.MESSAGE, params:mp.q.Params) bool {
    switch (msg) {
        else => {
        }
    }
    return mp.DefaultWndProc(win, msg, params);
}

fn getWeather(location:?[]const u8) ![:0]const u8 {
    var redirect_buffer: [8 * 1024]u8 = undefined;
    var transfer_buffer: [8 * 1024]u8 = undefined;
    var reader_buffer: [8 * 1024]u8 = undefined;

    const allocator = mp.global_allocator;

    var uri = try std.Uri.parse("http://wttr.in/?0AdT");
    if (location) |loc| {
        var buf = [_]u8{0}**80;
        const s = try std.fmt.bufPrint(&buf, "http://wttr.in/{s}?0AdT", .{loc});
        uri = try std.Uri.parse(s);
    } else {
    }

    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    var request = try client.request(.GET, uri, .{});
    defer request.deinit();

    try request.sendBodiless();
    const response = try request.receiveHead(&redirect_buffer);

    var a = std.Io.Writer.Allocating.init(allocator);
    defer a.deinit();
    var writer = &a.writer;

//    _ = try writer.write(response.head.bytes);

    const content_length = response.head.content_length;
    const reader = request.reader.bodyReader(&transfer_buffer, .none, content_length);

    var done = false;
    var bytes_read: usize = 0;

    while (!done) {
        const size = try reader.readSliceShort(&reader_buffer);

        if (size > 0) {
            bytes_read += size;
            _ = try writer.write(reader_buffer[0..size]);
        }

        if (content_length) |c_len| {
            if (bytes_read >= c_len) {
                done = true;
            }
        }

        if (size < reader_buffer.len) {
            done = true;
        }
    }

    try writer.flush(); // not necessary

    if (a.toOwnedSliceSentinel(0)) |txt| {
        for (txt, 0..) |chr, idx| {
            if (chr > 127) {
                txt[idx] = '.'; // remove unprintable character
            }
        }
        return txt;
    } else |_| {
    }
    return "Not Found";
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
const df = mp.df;
