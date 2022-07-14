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

pub fn main() !void {
    gpio.init(led);
    gpio.setDir(led, .out);
    while (true) {
        gpio.put(led, 1);
        time.sleepMs(250);
        gpio.put(led, 0);
        time.sleepMs(250);
    }
}
