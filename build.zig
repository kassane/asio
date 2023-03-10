//! Requires zig version: 0.11 or higher
//! build: zig build -Doptimize=ReleaseFast -DShared (or -DShared=true/false)

const std = @import("std");
const Path = std.Build.LazyPath;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Options
    const shared = b.option(bool, "Shared", "Build the Shared Library [default: false]") orelse false;
    const ssl = b.option(bool, "Ssl", "Build Asio with OpenSSL support [default: false]") orelse false;
    const tests = b.option(bool, "Tests", "Build tests [default: false]") orelse false;

    const libasio = if (!shared) b.addStaticLibrary(.{
        .name = "asio",
        .target = target,
        .optimize = optimize,
    }) else b.addSharedLibrary(.{
        .name = "asio",
        .target = target,
        .version = .{
            .major = 1,
            .minor = 28,
            .patch = 1,
        },
        .optimize = optimize,
    });
    libasio.defineCMacro("ASIO_STANDALONE", null);
    libasio.defineCMacro("ASIO_SEPARATE_COMPILATION", null);
    if (optimize == .Debug or optimize == .ReleaseSafe)
        libasio.bundle_compiler_rt = true
    else
        libasio.strip = true;
    libasio.addIncludePath(Path.relative("asio/include"));
    libasio.addCSourceFiles(switch (ssl) {
        true => &.{
            "asio/src/asio_ssl.cpp",
        },
        else => &.{
            "asio/src/asio.cpp",
        },
    }, cxxFlags);

    if (target.isWindows()) {
        if (libasio.linkage == .dynamic) {
            // no pkg-config
            libasio.linkSystemLibrary("ws2_32");
            if (ssl) {
                libasio.linkSystemLibraryName("crypto");
                libasio.linkSystemLibraryName("ssl");
            }
            libasio.want_lto = false;
        }
    }
    // TODO: MSVC support libC++ (need: ucrt/msvcrt/vcruntime)
    // https://github.com/ziglang/zig/issues/4785 - drop replacement for MSVC
    if (target.getAbi() == .msvc) {
        libasio.linkLibC();
    } else {
        libasio.linkLibCpp(); // LLVM libc++ (builtin)
    }
    libasio.installHeadersDirectoryOptions(.{
        .source_dir = Path.relative("asio/include"),
        .install_dir = .header,
        .install_subdir = "",
        .exclude_extensions = &.{
            "am",
            "gitignore",
        },
    });
    b.installArtifact(libasio);

    if (tests) {
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/coroutine.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/awaitable.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/async_result.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/associator.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/co_spawn.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/compose.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/connect.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/defer.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/executor.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/error.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/strand.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/thread_pool.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/this_coro.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/socket_base.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/serial_port.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/signal_set.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/post.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/prepend.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/cancellation_type.cpp",
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/as_tuple.cpp",
        });

        if (target.isWindows()) {
            buildTest(b, .{
                .lib = libasio,
                .path = "asio/src/tests/unit/windows/object_handle.cpp",
            });
            buildTest(b, .{
                .lib = libasio,
                .path = "asio/src/tests/unit/windows/overlapped_handle.cpp",
            });
            buildTest(b, .{
                .lib = libasio,
                .path = "asio/src/tests/unit/windows/stream_handle.cpp",
            });
            buildTest(b, .{
                .lib = libasio,
                .path = "asio/src/tests/unit/windows/overlapped_ptr.cpp",
            });
            buildTest(b, .{
                .lib = libasio,
                .path = "asio/src/tests/unit/windows/random_access_handle.cpp",
            });
        }
    }
}

fn buildTest(b: *std.Build, info: BuildInfo) void {
    const test_exe = b.addExecutable(.{
        .name = info.filename(),
        .optimize = info.lib.optimize,
        .target = info.lib.target,
    });
    if (info.lib.optimize == .Debug)
        test_exe.defineCMacro("ASIO_ENABLE_HANDLER_TRACKING", null);
    test_exe.linkLibrary(info.lib);
    for (info.lib.include_dirs.items) |include| {
        test_exe.include_dirs.append(include) catch {};
    }
    test_exe.addIncludePath(Path.relative("asio/src/tests/unit")); // unit_test.hpp
    test_exe.addCSourceFile(.{ .file = .{ .path = info.path }, .flags = cxxFlags });
    if (info.lib.target.isWindows()) {
        test_exe.linkSystemLibrary("ws2_32");
    }
    if (test_exe.target.getAbi() == .msvc)
        test_exe.linkLibC()
    else
        test_exe.linkLibCpp();
    b.installArtifact(test_exe);

    const run_cmd = b.addRunArtifact(test_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(
        b.fmt("{s}", .{info.filename()}),
        b.fmt("Run the {s} test", .{info.filename()}),
    );
    run_step.dependOn(&run_cmd.step);
}

const cxxFlags: []const []const u8 = &.{
    "-Wall",
    "-Wextra",
    "-Wpedantic",
    "-Werror",
    "-Wno-deprecated-declarations",
};

const BuildInfo = struct {
    lib: *std.Build.CompileStep,
    path: []const u8,

    fn filename(self: BuildInfo) []const u8 {
        var split = std.mem.split(u8, std.fs.path.basename(self.path), ".");
        return split.first();
    }
};
