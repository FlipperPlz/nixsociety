const std = @import("std");

const HardwareConfig = struct {
    name: []const u8,
    path: []const u8,
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();
    const allocator = std.heap.page_allocator;

    const hardware_dir = "flake/hardware";
    const configs = getHardwareConfigs(allocator, hardware_dir) catch |err| {
        try stdout.print("Error reading hardware configs: {}\n", .{err});
        return;
    };
    defer {
        for (configs) |config| {
            allocator.free(config.name);
            allocator.free(config.path);
        }
        allocator.free(configs);
    }

    try stdout.print("🖥️  NixSociety Hardware Selection\n", .{});
    try stdout.print("===============================\n\n", .{});

    if (configs.len == 0) {
        try stdout.print("❌ No hardware configurations found\n", .{});
        try stdout.print("Add .nix files to {s} to configure hardware\n", .{hardware_dir});
        return;
    }

    try stdout.print("Available hardware configurations:\n", .{});
    for (configs, 0..) |config, i| {
        try stdout.print("  {d:>2}. {s}\n", .{ i + 1, config.name });
    }

    try stdout.print("\nEnter the number of your hardware config (or press Enter for none): ", .{});

    var buf: [10]u8 = undefined;
    const maybe_input = stdin.readUntilDelimiterOrEof(&buf, '\n') catch |e| {
        try stdout.print("Error reading input: {}\n", .{e});
        return;
    };
    if (maybe_input) |input| {
        const trimmed = std.mem.trim(u8, input, " \n\r");
        if (trimmed.len > 0) {
            const selection = std.fmt.parseInt(usize, trimmed, 10) catch {
                try stdout.print("❌ Invalid selection\n", .{});
                return;
            };

            if (selection > 0 and selection <= configs.len) {
                const config = configs[selection - 1];
                try stdout.print("✅ Selected: {s}\n", .{config.name});
                try stdout.print("📁 Config: {s}\n", .{config.path});
                try stdout.print("🔧 Adding hardware config to ISO...\n", .{});

                const hardware_cfg_path = "flake/modules/hardware.nix";
                try std.fs.cwd().makePath("flake/modules");
                var hw_file = try std.fs.cwd().createFile(hardware_cfg_path, .{ .truncate = true });
                defer hw_file.close();

                const file_contents = try std.fmt.allocPrint(
                    allocator,
                    "{{ ... }}:\n{{\n  imports = [ ../hardware/{s}.nix ];\n}}\n",
                    .{config.name},
                );
                defer allocator.free(file_contents);
                try hw_file.writer().writeAll(file_contents);
                try stdout.print("🧩 Wrote hardware config to {s}\n", .{hardware_cfg_path});
            } else {
                try stdout.print("❌ Invalid selection\n", .{});
                return;
            }
        } else {
            try stdout.print("ℹ️  No hardware config selected\n", .{});
            const hardware_cfg_path = "flake/modules/hardware.nix";
            std.fs.cwd().deleteFile(hardware_cfg_path) catch {};
        }
    } else {
        try stdout.print("ℹ️  No hardware config selected\n", .{});
        const hardware_cfg_path = "flake/modules/hardware.nix";
        std.fs.cwd().deleteFile(hardware_cfg_path) catch {};
    }

    try stdout.print("\n🚀 Building NixSociety ISO...\n", .{});

    var child = std.process.Child.init(&.{ "nix", "build", ".#iso", "--no-link", "--print-out-paths" }, allocator);
    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Inherit;
    try child.spawn();

    var out_buf = std.ArrayList(u8).init(allocator);
    defer out_buf.deinit();
    if (child.stdout) |so| {
        var r = so.reader();
        try r.readAllArrayList(&out_buf, 1 << 20);
    }
    const term = try child.wait();
    if (term != .Exited or term.Exited != 0) {
        try stdout.print("❌ ISO build failed.\n", .{});
        return;
    }

    const store_path = std.mem.trim(u8, out_buf.items, " \n\r");
    try stdout.print("✅ ISO built successfully!\n", .{});
    try stdout.print("📁 Store path: {s}\n", .{store_path});

    try stdout.print("\n📁 Copying ISO to zig-out/iso/...\n", .{});
    try std.fs.cwd().makePath("zig-out/iso");

    const iso_dir_path = try std.fs.path.join(allocator, &.{ store_path, "iso" });
    defer allocator.free(iso_dir_path);

    var src_dir = std.fs.cwd().openDir(iso_dir_path, .{ .iterate = true }) catch |err| {
        try stdout.print("❌ Failed to open ISO directory {s}: {}\n", .{ iso_dir_path, err });
        return;
    };
    defer src_dir.close();

    var dst_dir = try std.fs.cwd().openDir("zig-out/iso", .{});
    defer dst_dir.close();

    var found_iso = false;
    var iter2 = src_dir.iterate();
    while (try iter2.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".iso")) {
            try src_dir.copyFile(entry.name, dst_dir, entry.name, .{});
            try stdout.print("✅ ISO copied to zig-out/iso/{s}\n", .{entry.name});
            found_iso = true;
            break;
        }
    }

    if (!found_iso) {
        try stdout.print("❌ No .iso file found under {s}\n", .{iso_dir_path});
        return;
    }
}

fn getHardwareConfigs(allocator: std.mem.Allocator, dir_path: []const u8) ![]HardwareConfig {
    var configs = std.ArrayList(HardwareConfig).init(allocator);
    defer configs.deinit();

    var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".nix")) {
            const name = try allocator.dupe(u8, entry.name[0 .. entry.name.len - 4]);
            const path = try std.fs.path.join(allocator, &.{ dir_path, entry.name });

            try configs.append(.{
                .name = name,
                .path = path,
            });
        }
    }

    return configs.toOwnedSlice();
}
