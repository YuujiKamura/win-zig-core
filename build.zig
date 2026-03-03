const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const runtime_mod = b.addModule("win_zig_core_runtime", .{
        .root_source_file = b.path("src/runtime/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    _ = runtime_mod;

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/runtime/lib.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run runtime tests");
    test_step.dependOn(&run_tests.step);
}

