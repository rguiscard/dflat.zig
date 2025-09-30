const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const textbox = @import("TextBox.zig");

pub var Clipboard:?[]u8 = null;
pub var ClipboardLength:usize = 0;

//pub export fn ContentInClipboard() callconv(.c) df.BOOL {
//    if ((Clipboard == null) or (Clipboard.?.len == 0) or (ClipboardLength == 0)) {
//        return df.FALSE;
//    }
//    return df.TRUE;
//}

// seems not in use
//pub fn CopyTextToClipboard(text:[*c]u8) void {
//    const txt = std.mem.span(text);
//    const ClipboardLength = txt.len;
//    var clipboard = getClipboard();
//    if (clipboard.appendSlice(txt)) {
//    } else |_| {
//        // error
//    }
//}

pub fn CopyToClipboard(win:*Window) void {
    const wnd = win.win;
    if (df.TextBlockMarked(wnd)) {
        const begCol:usize = @intCast(wnd.*.BlkBegCol);
        const endCol:usize = @intCast(wnd.*.BlkEndCol);
        const begLine:usize = @intCast(wnd.*.BlkBegLine);
        const endLine:usize = @intCast(wnd.*.BlkEndLine);
        const bbl = df.TextLine(wnd,begLine)+begCol;
        const bel = df.TextLine(wnd,endLine)+endCol;
        ClipboardLength = bel - bbl;

        var list:std.ArrayList(u8) = undefined;

        if (Clipboard) |c| {
            list = std.ArrayList(u8).fromOwnedSlice(c);
        } else {
            if (std.ArrayList(u8).initCapacity(root.global_allocator, ClipboardLength)) |l| {
                list = l;
            } else |_| {
                // error 
            }
        }

        if (list.resize(root.global_allocator, ClipboardLength)) {
        } else |_| {
        }
   
        @memcpy(list.items, bbl[0..ClipboardLength]);

        if (list.toOwnedSlice(root.global_allocator)) |text| {
            Clipboard = text;
        } else |_| {
        }
    }
}

pub fn ClearClipboard() void {
    if (Clipboard) |c| {
        root.global_allocator.free(c);
        Clipboard = null;
    }
}

pub fn PasteFromClipboard(win: *Window) bool {
    if (Clipboard) |c| {
        return PasteText(win, c, @intCast(c.len));
    }
    return false;
}

pub fn PasteText(win:*Window, SaveTo:[]u8, len:c_uint) bool {
    const wnd = win.win;
//    const src:[*c]u8 = SaveTo.ptr;
    
//    if (SaveTo != null and len > 0)    {
    if (len > 0) {
//        if (win.text) |text| {
//            const plen = text.len + len;
//            if (plen <= wnd.*.MaxTextLength) {
//                if (plen+1 > win.textlen) {
//                    if (root.global_allocator.realloc(text, @intCast(plen+3))) |buf| {
//                        win.text = buf;
//                        wnd.*.text = buf.ptr;
//                        win.textlen = @intCast(plen+1);
//                        wnd.*.textlen = @intCast(plen+1);
//                    } else |_| {
//                    }
//                    // assume win.text exists.
//                }
//                wnd.*.text = @ptrCast(df.DFrealloc(wnd.*.text, plen+3));
//                wnd.*.textlen = @intCast(plen+1);
//            }
        if (win.gapbuf) |buf| {
            const plen = buf.len() + len;
            if (plen <= win.MaxTextLength) {
                const pos = win.currPos();
                buf.moveCursor(pos);
                if (buf.insertSlice(SaveTo)) { } else |_| { }
                wnd.*.text = @constCast(buf.toString().ptr);
                wnd.*.textlen = @intCast(buf.len());
            }

//            const cp:[*c]u8 = df.zCurrChar(wnd);
//            _ = df.memmove(cp+len, cp, df.strlen(cp)+1);
//            _ = df.memmove(cp, src, len);
            textbox.BuildTextPointers(win);
            win.TextChanged = true;
            return true;
        }
    }
    return false;
}
