const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "glsl_analyzer",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();

    {
        exe.addAnonymousModule("glsl_spec.json", .{ .source_file = compileGlslSpec(b) });

        const options = b.addOptions();
        const build_root_path = try std.fs.path.resolve(b.allocator, &.{b.build_root.path orelse "."});
        options.addOption([]const u8, "build_root", build_root_path);
        exe.addOptions("build_options", options);
    }

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

fn compileGlslSpec(b: *std.Build) std.Build.LazyPath {
    const gen = std.Build.RunStep.create(b, "compile GLSL spec");
    gen.addArg("python3");
    gen.addFileArg(.{ .path = b.pathFromRoot("./spec/gen_spec.py") });
    return gen.addOutputFileArg("glsl_spec.json");
}
