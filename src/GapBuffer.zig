const std = @import("std");

const TopLevelFields = @This();

allocator: std.mem.Allocator,
items: []u8,       // includes trailing '\0'
gap_start: usize,
gap_end: usize,
realloc: bool = false,

pub fn init(allocator: std.mem.Allocator, initial_capacity: usize) !TopLevelFields {
    const buf = try allocator.alloc(u8, initial_capacity + 1);
    @memset(buf, 0);
    return TopLevelFields{
        .allocator = allocator,
        .items = buf,
        .gap_start = 0,
        .gap_end = initial_capacity,
    };
}

pub fn deinit(self: *TopLevelFields) void {
    self.allocator.free(self.items);
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
    self.items[capacity] = 0; // sentinel
}

fn ensureGap(self: *TopLevelFields, need: usize) !void {
    const gap_size = self.gap_end - self.gap_start;
    if (gap_size >= need) return;

    const old_len = self.items.len - 1; // exclude sentinel
    var new_len = old_len * 2;
    if (new_len < old_len + need) new_len = old_len + need;

    const right_len = old_len - self.gap_end;
    const new_gap_end = new_len - right_len;
    if (self.realloc) {
        if (self.allocator.realloc(self.items, new_len + 1)) |new_buf| {
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
    self.items[self.items.len - 1] = 0;
}

pub fn insertSlice(self: *TopLevelFields, slice: []const u8) !void {
    try self.ensureGap(slice.len);
    @memcpy(self.items[self.gap_start .. self.gap_start+slice.len], slice);
    self.gap_start += slice.len;
    self.items[self.items.len - 1] = 0;
}

pub fn moveCursor(self: *TopLevelFields, pos: usize) void {
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

pub fn toString(self: *TopLevelFields) []const u8 {
    const right_len = (self.items.len - 1) - self.gap_end;
    const total = self.gap_start + right_len;
    var out = self.items[0..total];
    @memmove(out[self.gap_start..], self.items[self.gap_end..self.gap_end+right_len]);
    self.items[total] = 0; // sentinel
    self.gap_start = total;
    self.gap_end = self.items.len-1;
    return out;
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

pub fn main() !void {
}
