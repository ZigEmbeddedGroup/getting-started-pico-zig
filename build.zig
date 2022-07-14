const std = @import("std");
const builtin = @import("builtin");
const uf2 = @import("uf2/src/main.zig");
const rp2040 = @import("rp2040/build.zig");
const microzig = @import("microzig/src/main.zig");

const Builder = std.build.Builder;
const Step = std.build.Step;
const LibExeObjStep = std.build.LibExeObjStep;

const Message = @import("src/device_info.zig").Message;

fn root() []const u8 {
    return (std.fs.path.dirname(@src().file) orelse ".") ++ "/";
}

pub fn addExample(b: *Builder, comptime name: []const u8) !void {
    const mode = b.standardReleaseOptions();
    const blinky = rp2040.addPiPicoExecutable(
        microzig,
        b,
        name,
        "examples/" ++ name ++ ".zig",
        .{},
    );
    blinky.setBuildMode(mode);
    blinky.install();

    const uf2_step = uf2.Uf2Step.create(blinky, .{
        .family_id = .RP2040,
    });
    uf2_step.install();
}

pub fn build(b: *Builder) !void {
    try addExample(b, "blinky");
    try addExample(b, "blinky_core1");
    try addExample(b, "uart");
    try addExample(b, "gpio_clk");
}

// TODO: wip
pub const DeviceInfoStep = struct {
    step: Step,
    builder: *Builder,
    exe: *LibExeObjStep,

    pub fn create(b: *Builder) *DeviceInfoStep {
        var ret = b.allocator.create(DeviceInfoStep) catch @panic("failed to allocate DeviceInfoStep");
        ret.* = .{
            .step = Step.init(.custom, "device_info", b.allocator, make),
            .builder = b,
            .exe = b.addExecutable("device_info", root() ++ "src/device_info.zig"),
        };
        ret.step.dependOn(&ret.exe.step);

        if (builtin.os.tag == .linux) {
            ret.exe.linkLibC();
            // TODO: can we check for the existence of this library?
            ret.exe.linkSystemLibrary("libudev");
        }

        return ret;
    }

    fn make(step: *Step) !void {
        const device_info = @fieldParentPtr(DeviceInfoStep, "step", step);

        std.log.info("exe path: {s}", .{device_info.exe.getOutputSource().generated.getPath()});

        const child = try std.ChildProcess.init(&.{
            device_info.exe.getOutputSource().generated.getPath(),
        }, device_info.builder.allocator);
        defer child.deinit();

        child.stdin_behavior = .Pipe;
        child.stdout_behavior = .Pipe;

        try child.spawn();

        const writer = child.stdin.?.writer();
        _ = writer;
        const reader = child.stdout.?.reader();

        while (true) {
            const line = reader.readUntilDelimiterAlloc(device_info.builder.allocator, '\n', 1024 * 1024) catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };
            defer device_info.builder.allocator.free(line);

            var stream = std.json.TokenStream.init(line);
            const message = try std.json.parse(Message, &stream, .{ .allocator = device_info.builder.allocator });

            if (std.mem.eql(u8, "log", message.tag)) {
                std.log.info("{s}", .{message.payload});
            } else if (std.mem.eql(u8, "found", message.tag)) {
                std.log.info("found pi pico with device path: {s}", .{message.payload});
            } else @panic("incorrect message tag");
        }

        std.log.err("this device discovery thing isn't fully implemented yet, make sure it's mounted and specify that path.", .{});

        // could wait instead, but I'm in a bloodthirsty mood
        _ = try child.kill();
    }
};
