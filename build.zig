//! Requires zig version: 0.13 or higher
//! build: zig build -Doptimize=ReleaseFast -DShared (or -DShared=true/false)

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Options
    const shared = b.option(bool, "Shared", "Build the Shared Library (default: false)") orelse false;
    const ssl = b.option(bool, "SSL", "Build Asio with OpenSSL support (default: false)") orelse false;
    const tests = b.option(bool, "Tests", "Build tests (default: false)") orelse false;

    const libasio = if (!shared) b.addStaticLibrary(.{
        .name = "asio",
        .target = target,
        .optimize = optimize,
    }) else b.addSharedLibrary(.{
        .name = "asio",
        .target = target,
        .version = .{
            .major = 1,
            .minor = 32,
            .patch = 0,
        },
        .optimize = optimize,
    });
    libasio.root_module.addCMacro("ASIO_STANDALONE", "1");
    libasio.root_module.addCMacro("ASIO_SEPARATE_COMPILATION", "1");
    if (optimize == .Debug or optimize == .ReleaseSafe)
        libasio.bundle_compiler_rt = true
    else
        libasio.root_module.strip = true;
    libasio.root_module.addIncludePath(b.path("asio/include"));
    libasio.root_module.addCSourceFiles(.{
        .files = switch (ssl) {
            true => &.{
                "asio/src/asio_ssl.cpp",
            },
            else => &.{
                "asio/src/asio.cpp",
            },
        },
        .flags = cxxFlags,
    });

    if (libasio.rootModuleTarget().os.tag == .windows) {
        if (libasio.linkage == .dynamic) {
            libasio.root_module.linkSystemLibrary("ws2_32", .{});
            if (ssl) {
                libasio.root_module.linkSystemLibrary("crypto", .{});
                libasio.root_module.linkSystemLibrary("ssl", .{});
            }
            libasio.want_lto = false;
        }
    }
    // TODO: MSVC support libC++ (need: ucrt/msvcrt/vcruntime)
    // https://github.com/ziglang/zig/issues/4785 - drop replacement for MSVC
    if (libasio.rootModuleTarget().abi == .msvc) {
        libasio.linkLibC();
    } else {
        libasio.linkLibCpp(); // LLVM libc++ (builtin)
    }
    libasio.installHeadersDirectory(b.path("asio/include"), "", .{
        .include_extensions = &.{ ".hpp", ".h", ".ipp" },
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
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/awaitable.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/async_result.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/associator.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/co_spawn.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/compose.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/connect.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/defer.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/executor.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/error.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/strand.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/thread_pool.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/this_coro.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/socket_base.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/serial_port.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/signal_set.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/post.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/prepend.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/cancellation_type.cpp",
            .optimize = optimize,
            .target = target,
        });
        buildTest(b, .{
            .lib = libasio,
            .path = "asio/src/tests/unit/as_tuple.cpp",
            .optimize = optimize,
            .target = target,
        });

        if (target.result.os.tag == .windows) {
            buildTest(b, .{
                .lib = libasio,
                .path = "asio/src/tests/unit/windows/object_handle.cpp",
                .optimize = optimize,
                .target = target,
            });
            buildTest(b, .{
                .lib = libasio,
                .path = "asio/src/tests/unit/windows/overlapped_handle.cpp",
                .optimize = optimize,
                .target = target,
            });
            buildTest(b, .{
                .lib = libasio,
                .path = "asio/src/tests/unit/windows/stream_handle.cpp",
                .optimize = optimize,
                .target = target,
            });
            buildTest(b, .{
                .lib = libasio,
                .path = "asio/src/tests/unit/windows/overlapped_ptr.cpp",
                .optimize = optimize,
                .target = target,
            });
            buildTest(b, .{
                .lib = libasio,
                .path = "asio/src/tests/unit/windows/random_access_handle.cpp",
                .optimize = optimize,
                .target = target,
            });
        }
    }
}

fn buildTest(b: *std.Build, info: BuildInfo) void {
    const test_exe = b.addExecutable(.{
        .name = info.filename(),
        .optimize = info.optimize,
        .target = info.target,
    });
    if (test_exe.root_module.optimize.? == .Debug)
        test_exe.root_module.addCMacro("ASIO_ENABLE_HANDLER_TRACKING", "1");
    test_exe.root_module.linkLibrary(info.lib);
    for (info.lib.root_module.include_dirs.items) |include| {
        test_exe.root_module.include_dirs.append(b.allocator, include) catch {};
    }
    test_exe.root_module.addIncludePath(b.path("asio/src/tests/unit")); // unit_test.hpp
    test_exe.root_module.addCSourceFile(.{
        .file = b.path(info.path),
        .flags = cxxFlags,
    });
    if (test_exe.rootModuleTarget().os.tag == .windows) {
        test_exe.root_module.linkSystemLibrary("ws2_32", .{});
    }
    if (test_exe.rootModuleTarget().abi == .msvc)
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
    "-Wno-deprecated-declarations",
};

const BuildInfo = struct {
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
    lib: *std.Build.Step.Compile,
    path: []const u8,

    fn filename(self: BuildInfo) []const u8 {
        var split = std.mem.splitSequence(u8, std.fs.path.basename(self.path), ".");
        return split.first();
    }
};
