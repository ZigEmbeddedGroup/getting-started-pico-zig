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

const led = 25;

fn core1() void {
    while (true) {
        gpio.put(led, 1);
        time.sleepMs(250);
        gpio.put(led, 0);
        time.sleepMs(250);
    }
}

pub fn main() !void {
    try rp2040.default_clock_config.apply();

    gpio.reset();
    gpio.init(led);
    gpio.setDir(led, .out);

    multicore.launchCore1(core1);

    while (true) {
        microzig.cpu.wfi();
    }
}
