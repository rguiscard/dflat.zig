const std = @import("std");

// Rewrite from https://research.swtch.com/glob

pub fn matchExp(pattern: []const u8, name: []const u8) bool {
    var px: usize = 0;
    var nx: usize = 0;

    while (px < pattern.len or nx < name.len) {
        if (px < pattern.len) {
            const chr = pattern[px];
            switch (chr) {
                '?' => { // single-character wildcard
                    if (nx < name.len) {
                        px += 1;
                        nx += 1;
                        continue;
                    }
                },
                '*' => { // zero-or-more-character wildcard
                    var i = nx;
                    while (i <= name.len) : (i += 1) {
                        if (matchExp(pattern[(px + 1)..], name[i..])) {
                            return true;
                        }
                    }
                },
                else => { // ordinary character
                    if (nx < name.len and name[nx] == chr) {
                        px += 1;
                        nx += 1;
                        continue;
                    }
                },
            }
        }
        return false; // mismatch
    }
    return true; // full match
}

pub fn matchLinear(pattern: []const u8, name: []const u8) bool {
    var px: usize = 0;
    var nx: usize = 0;
    var nextPx: usize = 0;
    var nextNx: usize = 0;

    while (px < pattern.len or nx < name.len) {
        if (px < pattern.len) {
            const chr = pattern[px];
            switch (chr) {
                '?' => {
                    if (nx < name.len) {
                        px += 1;
                        nx += 1;
                        continue;
                    }
                },
                '*' => {
                    nextPx = px;
                    nextNx = nx + 1;
                    px += 1;
                    continue;
                },
                else => {
                    if (nx < name.len and name[nx] == chr) {
                        px += 1;
                        nx += 1;
                        continue;
                    }
                },
            }
        }

        if (nextNx > 0 and nextNx <= name.len) {
            px = nextPx;
            nx = nextNx;
            continue;
        }
        return false;
    }
    return true;
}

test "simple match" {
   try std.testing.expect(matchExp("", ""));
   try std.testing.expect(matchLinear("", ""));
   try std.testing.expect(matchExp("", "x") == false);
   try std.testing.expect(matchLinear("", "x") == false);
   try std.testing.expect(matchExp("x", "") == false);
   try std.testing.expect(matchLinear("x", "") == false);
}

test "star match" {
   try std.testing.expect(matchExp("abc", "abc"));
   try std.testing.expect(matchLinear("abc", "abc"));
   try std.testing.expect(matchExp("*", "abc"));
   try std.testing.expect(matchLinear("*", "abc"));
   try std.testing.expect(matchExp("*c", "abc"));
   try std.testing.expect(matchLinear("*c", "abc"));
   try std.testing.expect(matchExp("*b", "abc") == false);
   try std.testing.expect(matchLinear("*b", "abc") == false);
   try std.testing.expect(matchExp("a*", "abc"));
   try std.testing.expect(matchLinear("a*", "abc"));
   try std.testing.expect(matchExp("b*", "abc") == false);
   try std.testing.expect(matchLinear("b*", "abc") == false);
   try std.testing.expect(matchExp("a*", "a"));
   try std.testing.expect(matchLinear("a*", "a"));
   try std.testing.expect(matchExp("*a", "a"));
   try std.testing.expect(matchLinear("*a", "a"));
}

test "complex match" {
   try std.testing.expect(matchExp("a*b*c*d*e*", "axbxcxdxe"));
   try std.testing.expect(matchLinear("a*b*c*d*e*", "axbxcxdxe"));
   try std.testing.expect(matchExp("a*b*c*d*e*", "axbxcxdxexxx"));
   try std.testing.expect(matchLinear("a*b*c*d*e*", "axbxcxdxexxx"));
   try std.testing.expect(matchExp("a*b?c*x", "abxbbxdbxebxczzx"));
   try std.testing.expect(matchLinear("a*b?c*x", "abxbbxdbxebxczzx"));
   try std.testing.expect(matchExp("a*b?c*x", "abxbbxdbxebxczzy") == false);
   try std.testing.expect(matchLinear("a*b?c*x", "abxbbxdbxebxczzy") == false);
   try std.testing.expect(matchExp("a*a*a*a*b", "a"**100) == false);
   try std.testing.expect(matchLinear("a*a*a*a*b", "a"**100) == false);
   try std.testing.expect(matchExp("*x", "xxx"));
   try std.testing.expect(matchLinear("*x", "xxx"));
} 
