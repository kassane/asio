## Asio Standalone for Zig Package Manager (MVP)

* Original source: https://github.com/chriskohlhoff/asio

### How to use

* Download [Zig v0.12 or higher](https://ziglang.org/download)
* Make on your project `build.zig` & `build.zig.zon` file

e.g:

* **build.zig**
```zig
    const asio_dep = b.dependency("libasio", .{ // <== as declared in build.zig.zon
        .target = target, // the same as passing `-Dtarget=<...>` to the library's build.zig script
        .optimize = optimize, // ditto for `-Doptimize=<...>`
    });
    const libasio = asio_dep.artifact("asio"); // <== has the location of the dependency files (asio)
    /// your executable config
    exe.linkLibrary(libasio); // <== link libasio
    exe.installLibraryHeaders(libasio); // <== get copy asio headers to zig-out/include 
```
* **build.zig.zon**
```zig
.{
    .name = "example",
    .version = "0.1.0",
    .paths = .{""},
    .dependencies = .{
        .libasio = .{
            .url = "https://github.com/kassane/asio/archive/[tag/commit-hash].tar.gz",
            // or
            .url = "git+https://https://github.com/kassane/asio#commit-hash",
            .hash = "[multihash - sha256-2]",
        },
    },
}
```

### More info about zig-pkg
- https://github.com/ziglang/zig/pull/14265
- https://github.com/ziglang/zig/issues/14307
