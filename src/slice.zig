const builtin = @import("builtin");
const TypeInfo = builtin.TypeInfo;
const TypeId = builtin.TypeId;

fn FatPtr(comptime T: type) type {
    return struct {
        data: *const T,
        len: usize,

        const Self = @This();

        fn init(data: *const T, len: usize) Self {
            return Self{ .data = data, .len = len };
        }
    };
}

fn Repr(comptime T: type) type {
    return extern union {
        zig: []const T,
        zig_mut: []T,
        raw: FatPtr(T),

        const Self = @This();

        fn raw(raw_ptr: FatPtr(T)) Self {
            return Self{ .raw = raw_ptr };
        }
    };
}

fn pointee(comptime ptr: type) type {
    switch (@typeInfo(ptr)) {
        TypeId.Pointer => |p| return p.child,
        else => @compileError("Expected pointer type, found `" ++ @typeName(@typeOf(ptr)) ++ "`."),
    }
}

pub fn from_raw_parts(ptr: var, len: usize) []const pointee(@typeOf(ptr)) {
    const BaseType = pointee(@typeOf(ptr));
    var raw = FatPtr(BaseType).init(ptr, len);
    return Repr(BaseType).raw(raw).zig;
}

pub fn from_raw_parts_mut(ptr: var, len: usize) []pointee(@typeOf(ptr)) {
    switch (@typeInfo(@typeOf(ptr))) {
        TypeId.Pointer => |p| {
            if (p.is_const) {
                @compileError("Expected mutable pointer, found constant pointer.");
            }
        },
        else => unreachable,
    }

    const BaseType = pointee(@typeOf(ptr));
    var raw = FatPtr(BaseType).init(ptr, len);
    return Repr(BaseType).raw(raw).zig_mut;
}

test "basic add functionality" {
    var v = usize(10);
    var s = from_raw_parts_mut(&v, 1);

    var n = s.ptr[0];
    @import("std").debug.warn("N = {}\n", n);
}
