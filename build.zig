const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    main_mod.addImport("raylib", raylib_dep.module("raylib"));
    main_mod.linkLibrary(raylib_dep.artifact("raylib"));

    // ─── Icon Generation (SVG → PNG at multiple sizes) ────────
    const svg_path = b.path("logo/calctron-logo.svg");
    const icon_script = b.path("scripts/generate_icons.sh");
    const gen = b.addSystemCommand(&.{"bash"});
    gen.addFileArg(icon_script);
    gen.addFileArg(svg_path);
    const icon_dir = gen.addOutputFileArg(".");
    gen.has_side_effects = true;

    const exe = b.addExecutable(.{
        .name = "calctron",
        .root_module = main_mod,
    });
    exe.linker_allow_shlib_undefined = true;
    b.installArtifact(exe);

    // Install icons per platform
    // Linux: hicolor icon theme
    const install_svg = b.addInstallFile(svg_path, "share/icons/hicolor/512x512/apps/calctron.svg");
    b.getInstallStep().dependOn(&install_svg.step);

    var png_installs: [7]*std.Build.Step = undefined;
    inline for ([_][]const u8{ "16", "32", "48", "64", "128", "256", "512" }, 0..) |sz, i| {
        const src = icon_dir.path(b, b.fmt("calctron-{s}.png", .{sz}));
        const inst = b.addInstallFile(src, b.fmt("share/icons/hicolor/{s}x{s}/apps/calctron.png", .{ sz, sz }));
        b.getInstallStep().dependOn(&inst.step);
        png_installs[i] = &inst.step;
    }

    // macOS: icns bundle (app icon)
    const mac_src = icon_dir.path(b, "calctron-1024.png");
    const install_mac_icon = b.addInstallFile(mac_src, "calctron.app/Contents/Resources/AppIcon.png");
    b.getInstallStep().dependOn(&install_mac_icon.step);

    // Windows: executable icon
    const win_src = icon_dir.path(b, "calctron-512.png");
    const install_win_icon = b.addInstallFile(win_src, "calctron.icon");
    b.getInstallStep().dependOn(&install_win_icon.step);

    // Icon step — also installs hicolor PNG icons
    const icon_step = b.step("icon", "Generate and install platform icons");
    icon_step.dependOn(&install_svg.step);
    for (png_installs) |s| {
        icon_step.dependOn(s);
    }
    icon_step.dependOn(&install_mac_icon.step);
    icon_step.dependOn(&install_win_icon.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the calculator");
    run_step.dependOn(&run_cmd.step);

    // ─── Tests ────────────────────────────────────────────────
    const parallel_mod = b.createModule(.{
        .root_source_file = b.path("src/parallel.zig"),
        .target = target,
        .optimize = optimize,
    });
    const parallel_tests = b.addTest(.{
        .root_module = parallel_mod,
    });

    const calc_mod = b.createModule(.{
        .root_source_file = b.path("src/calculator.zig"),
        .target = target,
        .optimize = optimize,
    });
    calc_mod.addImport("parallel.zig", parallel_mod);
    const calc_tests = b.addTest(.{
        .root_module = calc_mod,
    });

    const run_calc_tests = b.addRunArtifact(calc_tests);
    const run_parallel_tests = b.addRunArtifact(parallel_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_calc_tests.step);
    test_step.dependOn(&run_parallel_tests.step);

    // ─── Fuzz Tests ───────────────────────────────────────────
    const fuzz_mod = b.createModule(.{
        .root_source_file = b.path("src/fuzz.zig"),
        .target = target,
        .optimize = optimize,
    });
    fuzz_mod.addImport("calculator.zig", calc_mod);
    fuzz_mod.addImport("parallel.zig", parallel_mod);

    const fuzz_tests = b.addTest(.{
        .root_module = fuzz_mod,
    });
    fuzz_tests.root_module.fuzz = true;
    const run_fuzz = b.addRunArtifact(fuzz_tests);
    b.step("fuzz", "Run fuzz tests").dependOn(&run_fuzz.step);

    // ─── Code Quality ─────────────────────────────────────────
    // zig fmt --check
    const fmt_check = b.addFmt(.{
        .check = true,
        .paths = &.{ "src/", "build.zig" },
    });
    b.step("fmt-check", "Check code formatting").dependOn(&fmt_check.step);

    const fmt_fix = b.addFmt(.{
        .paths = &.{ "src/", "build.zig" },
    });
    b.step("fmt", "Format code").dependOn(&fmt_fix.step);

    // ─── AST Check ────────────────────────────────────────────
    const ast_check = b.addSystemCommand(&.{
        "bash", "-c", "for f in src/*.zig; do zig ast-check \"$f\"; done",
    });
    b.step("ast-check", "Check AST validity").dependOn(&ast_check.step);

    // ─── Cross-compile targets ────────────────────────────────
    const cross_targets: []const struct {
        name: []const u8,
        desc: []const u8,
        spec: std.Target.Query,
    } = &.{
        .{
            .name = "build-windows",
            .desc = "Cross-compile for Windows (x86_64)",
            .spec = .{ .cpu_arch = .x86_64, .os_tag = .windows },
        },
        .{
            .name = "build-macos",
            .desc = "Cross-compile for macOS (aarch64)",
            .spec = .{ .cpu_arch = .aarch64, .os_tag = .macos },
        },
        .{
            .name = "build-linux-native",
            .desc = "Cross-compile for Linux (x86_64, static libc)",
            .spec = .{
                .cpu_arch = .x86_64,
                .os_tag = .linux,
                .abi = .musl,
            },
        },
    };

    for (cross_targets) |ct| {
        const cross_target = b.resolveTargetQuery(ct.spec);
        const cross_mod = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = cross_target,
            .optimize = .ReleaseSafe,
            .link_libc = true,
        });
        cross_mod.addImport("raylib", raylib_dep.module("raylib"));

        const cross_exe = b.addExecutable(.{
            .name = "calctron",
            .root_module = cross_mod,
        });
        cross_exe.linker_allow_shlib_undefined = true;

        const install_cross = b.addInstallArtifact(cross_exe, .{
            .dest_dir = .{ .override = .{ .custom = ct.name } },
        });

        const cross_step = b.step(ct.name, ct.desc);
        cross_step.dependOn(&install_cross.step);
    }
}
