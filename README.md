## Asio Standalone for Zig Package Manager (MVP)

* Original source: https://github.com/chriskohlhoff/asio

### How to use

* Download [Zig v0.13 or higher](https://ziglang.org/download)
* Make on your project `build.zig` & `build.zig.zon` file

e.g:

* **build.zig**
```zig
    const asio_dep = b.dependency("asio", .{ // <== as declared in build.zig.zon
        .target = target, // the same as passing `-Dtarget=<...>` to the library's build.zig script
        .optimize = optimize, // ditto for `-Doptimize=<...>`
    });
    const libasio = asio_dep.artifact("asio"); // <== has the location of the dependency files (asio)
    /// your executable config
    exe.linkLibrary(libasio); // <== link libasio
    exe.installLibraryHeaders(libasio); // <== get copy asio headers to zig-out/include 
```
* **build.zig.zon**

```bash
# '--save=asio': (over)write latest git commit (no need manually update)
$ zig fetch --save=asio git+https://github.com/kassane/asio
```
or add manually to your `build.zig.zon` file:

```zig
.{
    .name = "example",
    .version = "0.1.0",
    .paths = .{""},
    .dependencies = .{
        .asio = .{
            .url = "https://github.com/kassane/asio/archive/[tag/commit-hash].tar.gz",
            // or
            .url = "git+https://https://github.com/kassane/asio#commit-hash",
            .hash = "[multihash - sha256-2]",
        },
    },
}
```

```bash
# zig project helper
Project-Specific Options:
  -Dtarget=[string]            The CPU architecture, OS, and ABI to build for
  -Dcpu=[string]               Target CPU features to add or subtract
  -Ddynamic-linker=[string]    Path to interpreter on the target system
  -Doptimize=[enum]            Prioritize performance, safety, or binary size
                                 Supported Values:
                                   Debug
                                   ReleaseSafe
                                   ReleaseFast
                                   ReleaseSmall
  -DShared=[bool]              Build the Shared Library (default: false)
  -DSSL=[bool]                 Build Asio with OpenSSL support (default: false)
  -DTests=[bool]               Build tests (default: false)
```

### More info about zig-pkg
- https://github.com/ziglang/zig/pull/14265
- https://github.com/ziglang/zig/issues/14307
