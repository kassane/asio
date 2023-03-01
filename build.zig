//! Requires zig version: 0.11 or higher
//! build: zig build -Doptimize=ReleaseFast -Dshared (or -Dshared=true/false)

const std = @import("std");
const Builder = std.Build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Options
    const shared = b.option(bool, "shared", "Build the Shared Library [default: false]") orelse false;
    const ssl = b.option(bool, "openssl", "Build Asio with OpenSSL support [default: false]") orelse false;
    const examples = b.option(bool, "Examples", "Build some examples [default: off]") orelse false;

    const libasio = if (!shared) b.addStaticLibrary(.{
        .name = "asio",
        .target = target,
        .optimize = optimize,
    }) else b.addSharedLibrary(.{
        .name = "asio",
        .target = target,
        .version = .{
            .major = 1,
            .minor = 26,
            .patch = 0,
        },
        .optimize = optimize,
    });
    if (optimize == .Debug or optimize == .ReleaseSafe)
        libasio.bundle_compiler_rt = true;

    libasio.strip = true;
    libasio.addIncludePath("asio/include");
    libasio.addCSourceFiles(switch (ssl) {
        true => source ++ [_][]const u8{
            "asio/src/asio_ssl.cpp",
        },
        else => source,
    }, cxxFlags);

    if (target.isWindows()) {
        // no pkg-config
        libasio.linkSystemLibraryName("ws2_32");
        libasio.linkSystemLibraryName("rpcrt4");
        libasio.linkSystemLibraryName("iphlpapi");
        if (ssl) {
            libasio.linkSystemLibraryName("crypto");
            libasio.linkSystemLibraryName("ssl");
        }
    } else if (target.isDarwin()) {
        // TODO
        //libasio.linkFramework("");
    } else {
        // Linux
        libasio.linkSystemLibrary("rt");
        libasio.linkSystemLibrary("dl");
    }
    // TODO: MSVC support libC++ (need: ucrt/msvcrt/vcruntime)
    // https://github.com/ziglang/zig/issues/4785 - drop replacement for MSVC
    libasio.linkLibCpp(); // LLVM libc++ (builtin)
    libasio.install();
    b.installDirectory(.{
        .source_dir = "asio/include",
        .install_dir = .header,
        .install_subdir = "",
        .exclude_extensions = &.{ "am", "gitignore" },
    });

    if (examples) {
        buildSample(b, libasio, "timeout_cpp20", "asio/src/examples/cpp20/coroutines/timeout.cpp");
        buildSample(b, libasio, "c_callback_wrapper_cpp20", "asio/src/examples/cpp20/operations/c_callback_wrapper.cpp");
        buildSample(b, libasio, "parallel_sort_cpp14", "asio/src/examples/cpp14/parallel_group/parallel_sort.cpp");
    }
}

fn buildSample(b: *std.Build.Builder, lib: *std.Build.CompileStep, name: []const u8, file: []const u8) void {
    const test_exe = b.addExecutable(.{
        .name = name,
        .optimize = lib.optimize,
        .target = lib.target,
    });
    test_exe.linkLibrary(lib);
    test_exe.addSystemIncludePath("asio/include");
    test_exe.addCSourceFile(file, cxxFlags);
    if (lib.target.isWindows())
        test_exe.linkSystemLibraryName("ws2_32");
    test_exe.linkLibCpp();
    test_exe.install();

    const run_cmd = test_exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(b.fmt("{s}", .{name}), b.fmt("Run the {s}", .{name}));
    run_step.dependOn(&run_cmd.step);
}

const cxxFlags: []const []const u8 = &.{
    "-std=c++20",
    "-O3",
    "-Wall",
    "-pedantic",
    "-fcoroutines-ts",
};
const source: []const []const u8 = &.{
    "asio/src/asio.cpp",
};
