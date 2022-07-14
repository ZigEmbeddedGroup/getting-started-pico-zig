const std = @import("std");
const microzig = @import("microzig");
const rp2040 = microzig.hal;
const gpio = rp2040.gpio;
const clocks = rp2040.clocks;
const time = rp2040.time;
const regs = microzig.chip.registers;
const multicore = rp2040.multicore;

pub fn panic(message: []const u8, maybe_stack_trace: ?*std.builtin.StackTrace) noreturn {
    _ = message;
    _ = maybe_stack_trace;
    @breakpoint();
    while (true) {}
}

const clock_config = clocks.GlobalConfiguration.init(.{
    .sys = .{ .source = .src_xosc },
    .gpout0 = .{ .source = .clk_sys },
});

pub fn init() void {
    clock_config.apply();
    gpio.reset();
}

const gpout0_pin = 21;

pub fn main() !void {
    gpio.setFunction(gpout0_pin, .gpck);
    while (true) {}
}
