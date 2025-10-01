const std = @import("std");

const TopLevelFields = @This();

allocator: std.mem.Allocator,
items: []u8,       // includes trailing '\0'
gap_start: usize,
gap_end: usize,
realloc: bool = false,

pub fn init(allocator: std.mem.Allocator, initial_capacity: usize) !*TopLevelFields {
    var self:*TopLevelFields = undefined;
    if (allocator.create(TopLevelFields)) |s| {
       self = s;
    } else |err| {
        return err;
    }

    const buf = try allocator.alloc(u8, initial_capacity + 1);
    @memset(buf, 0);

    self.* = .{
        .allocator = allocator,
        .items = buf,
        .gap_start = 0,
        .gap_end = initial_capacity,
    };

    return self;
}

pub fn deinit(self: *TopLevelFields) void {
    const allocator = self.allocator;
    allocator.free(self.items);
    allocator.destroy(self);
}

// use realloc or alloc
pub fn setRealloc(self: *TopLevelFields, realloc: bool) void {
    self.realloc = realloc;
}

/// Clear all content but keep capacity
pub fn clear(self: *TopLevelFields) void {
    const capacity = self.items.len - 1; // exclude sentinel
    self.gap_start = 0;
    self.gap_end = capacity;
    @memset(self.items, 0);
//    self.items[capacity] = 0; // sentinel
}

fn ensureGap(self: *TopLevelFields, need: usize) !void {
    const gap_size = self.gap_end - self.gap_start;
    if (gap_size >= need) return;

    const old_len = self.items.len - 1; // exclude sentinel
    const new_len = @max(old_len * 2, old_len-gap_size+need);


    const right_len = old_len - self.gap_end;
    const new_gap_end = new_len - right_len;
    if (self.realloc) {
        if (self.allocator.realloc(self.items, new_len + 1)) |new_buf| {
            // need to move right part to enlarge gap
            @memcpy(
                new_buf[new_gap_end..new_gap_end+right_len],
                self.items[self.gap_end..self.gap_end+right_len],
            );
            self.items = new_buf;
        } else |err| {
            return err;
        }
    } else {
        if (self.allocator.alloc(u8, new_len + 1)) |new_buf| {
            @memset(new_buf, 0);
            @memcpy(new_buf[0..self.gap_start], self.items[0..self.gap_start]);
            @memcpy(
                new_buf[new_gap_end..new_gap_end+right_len],
                self.items[self.gap_end..self.gap_end+right_len],
            );
            self.allocator.free(self.items);
            self.items = new_buf;
        } else |err| {
            return err;
        }
    }
    self.gap_end = new_gap_end;
    self.items[self.items.len - 1] = 0;
}

pub fn insert(self: *TopLevelFields, c: u8) !void {
    try self.ensureGap(1);
    self.items[self.gap_start] = c;
    self.gap_start += 1;
//    self.items[self.items.len - 1] = 0;
}

pub fn insertSlice(self: *TopLevelFields, slice: []const u8) !void {
    try self.ensureGap(slice.len);
    // use @memmove in case copy and paste from itself ?
    @memcpy(self.items[self.gap_start .. self.gap_start+slice.len], slice);
    self.gap_start += slice.len;
//    self.items[self.items.len - 1] = 0;
}

pub fn moveCursor(self: *TopLevelFields, pos: usize) void {
    const l = self.len();
    if (pos > l) {
        return;
    }

    if (pos < self.gap_start) {
        const left_move = self.gap_start - pos;
        @memmove(
            self.items[self.gap_end - left_move .. self.gap_end],
            self.items[pos..self.gap_start],
        );
        self.gap_end -= left_move;
        self.gap_start = pos;
    } else if (pos > self.gap_start) {
        const right_move = pos - self.gap_start;
        @memmove(
            self.items[self.gap_start..self.gap_start+right_move],
            self.items[self.gap_end..self.gap_end+right_move],
        );
        self.gap_end += right_move;
        self.gap_start = pos;
    }
}

pub fn delete(self: *TopLevelFields) void {
    if (self.gap_end < self.items.len - 1) {
        self.gap_end += 1;
    }
}

pub fn backspace(self: *TopLevelFields) void {
    if (self.gap_start > 0) {
        self.gap_start -= 1;
    }
}

// Remove all text in [begin (included), end (not-included)]
pub fn removeRange(self: *TopLevelFields, begin: usize, end: usize) void {
    const l = self.len();
    if (begin > end or end > l) {
        return;
        // @panic("removeRange: invalid range");
    }

    // Move cursor to begin (gap at begin)
    self.moveCursor(begin);

    // Skip over `end - begin` characters
    self.gap_end += (end - begin);
}

pub fn compact(self: *TopLevelFields) void {
    const right_len = (self.items.len - 1) - self.gap_end;
    const total = self.gap_start + right_len;
    var out = self.items[0..total];
    @memmove(out[self.gap_start..], self.items[self.gap_end..self.gap_end+right_len]);
    self.items[total] = 0; // sentinel
    self.gap_start = total;
    self.gap_end = self.items.len-1;
}

pub fn trancate(self: *TopLevelFields, pos: usize) void {
    const l = self.len();
    if (pos > l) {
        return;
    }
    self.moveCursor(pos);
    self.gap_end = self.items.len - 1; // everything after pos is discarded


}

pub fn setChar(self: *TopLevelFields, pos: usize, c: u8) void {
    const l = self.len();
    if (pos >= l)
        return;

    if (pos < self.gap_start) {
        self.items[pos] = c;
    } else {
        const after_index = self.gap_end + (pos - self.gap_start);
        self.items[after_index] = c;
    }
}

pub fn getChar(self: *TopLevelFields, pos: usize) ?u8 {
    const l = self.len();
    if (pos >= l)
        return null;

    var idx = pos;
    if (pos >= self.gap_start) {
        idx = pos + (self.gap_end - self.gap_start);
    }
    return self.items[idx];
}

pub fn len(self: *TopLevelFields) usize {
    return (self.items.len - 1) - (self.gap_end - self.gap_start);
}

pub fn toString(self: *TopLevelFields) [:0]const u8 {
    self.compact();
    return self.items[0..self.gap_start:0];
}

// Accessories
pub fn indexOfLine(self: *TopLevelFields, lno:usize, move: bool) usize {
    var pos:usize = 0;
    if (lno == 0) {
        if (move)
            self.moveCursor(0);
    } else {
        pos = 0;
        var lc:usize = 0;
        while(std.mem.indexOfScalarPos(u8, self.items, pos, '\n')) |idx| {
            pos = idx+1;
            lc += 1;
            if (lc == lno) {
                break;
            }
        }
        if (pos > self.gap_end) {
            pos -= self.gap_end-self.gap_start;
        }
        if (move)
            self.moveCursor(pos);
    }
    return pos; 
}

test "gap remove range" {
    const gpa = std.testing.allocator;
    for (0..2) |idx| {
        var buf = try TopLevelFields.init(gpa, 40);
        defer buf.deinit();
        if (idx > 0) {
           buf.setRealloc(true);
        }
        try buf.insertSlice("01234567890123456789012345678901234567890");
        buf.removeRange(5, 10);
        try std.testing.expectEqualStrings("012340123456789012345678901234567890", buf.toString());
        buf.removeRange(2, 10);
        try std.testing.expectEqualStrings("0156789012345678901234567890", buf.toString());
        buf.removeRange(10, 15);
        try std.testing.expectEqualStrings("01567890128901234567890", buf.toString());
    }
}

test "gap buffer get and set char" {
    const gpa = std.testing.allocator;
    for (0..2) |idx| {
        var buf = try TopLevelFields.init(gpa, 40);
        defer buf.deinit();
        if (idx > 0) {
           buf.setRealloc(true);
        }
        try buf.insertSlice("012345678901234567890");
        if (buf.getChar(1)) |chr| {
            try std.testing.expectEqual('1', chr);
        } else {
            try std.testing.expect(false);
        }
        buf.moveCursor(10);
        for(0..5) |_| {
            buf.backspace();
        }
        if (buf.getChar(7)) |chr| {
            try std.testing.expectEqual('2', chr);
        } else {
            try std.testing.expect(false);
        }
        try std.testing.expectEqualStrings("0123401234567890", buf.toString());
    }
}

test "gap buffer line position" {
    const gpa = std.testing.allocator;
    for (0..2) |idx| {
        var buf = try TopLevelFields.init(gpa, 40);
        defer buf.deinit();
        if (idx > 0) {
           buf.setRealloc(true);
        }
        try buf.insertSlice("1xxxx\n2xxxxyyyyy\n3xxxxx\n4");
        var pos = buf.indexOfLine(0, false);
        try std.testing.expectEqual(0, pos);
        pos = buf.indexOfLine(1, false);
        try std.testing.expectEqual(6, pos);
        pos = buf.indexOfLine(2, false);
        try std.testing.expectEqual(17, pos);
        pos = buf.indexOfLine(3, true);
        try std.testing.expectEqual(24, pos);
        try std.testing.expectEqual(24, buf.gap_start);


        for (0..7) |_| {
            buf.backspace();
        }
        pos = buf.indexOfLine(2, false);
        try std.testing.expectEqual(17, pos);
        try std.testing.expectEqualStrings("1xxxx\n2xxxxyyyyy\n4", buf.toString());
    }
}

test "gap buffer out of bound 1" {
    const gpa = std.testing.allocator;
    for (0..2) |idx| {
        var buf = try TopLevelFields.init(gpa, 40);
        defer buf.deinit();
        if (idx > 0) {
           buf.setRealloc(true);
        }
        try buf.insertSlice("Hello");
        buf.moveCursor(20);
        try std.testing.expectEqualStrings("Hello", buf.toString());
        buf.trancate(20);
        try std.testing.expectEqualStrings("Hello", buf.toString());

        buf.clear();
        try buf.insertSlice("0123456789");
        buf.moveCursor(8);
        for(0..6) |_| {
            buf.backspace();
        }
        try std.testing.expectEqualStrings("0189", buf.toString());

        buf.trancate(3); // middle of gap
        try std.testing.expectEqualStrings("018", buf.toString());
    }
}

test "gap buffer trancate" {
    const gpa = std.testing.allocator;
    for (0..2) |idx| {
        var buf = try TopLevelFields.init(gpa, 40);
        defer buf.deinit();
        if (idx > 0) {
           buf.setRealloc(true);
        }
        try buf.insertSlice("Hello\n");
        try std.testing.expectEqualStrings("Hello\n", buf.toString());
        buf.trancate(2);
        try std.testing.expectEqualStrings("He", buf.toString());
        if (std.mem.indexOfScalar(u8, buf.items, 0)) |pos| {
            try std.testing.expectEqual(2, pos);
        } else {
            try std.testing.expect(false);
        }
        try std.testing.expect(buf.items.len >= 3);

        buf.moveCursor(2);
        try buf.insertSlice("llo");
        try std.testing.expectEqualStrings("Hello", buf.toString());
        if (std.mem.indexOfScalar(u8, buf.items, 'o')) |pos| {
            buf.trancate(pos);
            try std.testing.expectEqualStrings("Hell", buf.toString());
        }
    }
}

test "gap buffer toString" {
    const gpa = std.testing.allocator;
    for (0..2) |idx| {
        var buf = try TopLevelFields.init(gpa, 4);
        defer buf.deinit();
        if (idx > 0) {
           buf.setRealloc(true);
        }
        try buf.insertSlice("Hello");
        try std.testing.expectEqualStrings("Hello", buf.toString());
        buf.moveCursor(2);
        try std.testing.expectEqual(2, buf.gap_start);
        try buf.insertSlice("L");
        try std.testing.expectEqualStrings("HeLllo", buf.toString());
        if (std.mem.indexOfScalar(u8, buf.items, 0)) |pos| {
            try std.testing.expectEqual(6, pos);
        } else {
            try std.testing.expect(false);
        }
    }
}

test "gap buffer delete" {
    const gpa = std.testing.allocator;
    for (0..2) |idx| {
        var buf = try TopLevelFields.init(gpa, 4);
        defer buf.deinit();
        if (idx > 0) {
           buf.setRealloc(true);
        }
        try buf.insertSlice("Hello");
        buf.moveCursor(2);
        buf.delete();
        buf.delete();
        try std.testing.expectEqualStrings("Heo", buf.toString());
        try std.testing.expectEqual(3, buf.gap_start);
        if (std.mem.indexOfScalar(u8, buf.items, 0)) |pos| {
            try std.testing.expectEqual(3, pos);
        } else {
            try std.testing.expect(false);
        }
    }
}

test "gap buffer clear" {
    const gpa = std.testing.allocator;

    for (0..2) |idx| {
        var buf = try TopLevelFields.init(gpa, 4);
        defer buf.deinit();
        if (idx > 0) {
           buf.setRealloc(true);
        }
        try buf.insertSlice("Hello");
        buf.clear();
        try std.testing.expectEqualStrings("", buf.toString());
        try buf.insertSlice("World");
        try std.testing.expectEqualStrings("World", buf.toString());
    }
}

test "zero length" {
    const gpa = std.testing.allocator;

    for (0..1) |idx| {
        var buf = try TopLevelFields.init(gpa, 0);
        defer buf.deinit();
        if (idx > 0) {
           buf.setRealloc(true);
        }
        try buf.insertSlice("Hello");
        try std.testing.expectEqualStrings("Hello", buf.toString());
    }
}

pub fn main() !void {
}
