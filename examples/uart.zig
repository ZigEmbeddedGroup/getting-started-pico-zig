const std = @import("std");
const microzig = @import("microzig");

const rp2040 = microzig.hal;
const time = rp2040.time;
const gpio = rp2040.gpio;
const clocks = rp2040.clocks;

const uart_id = 0;
const baud_rate = 115200;
const uart_tx_pin = 0;
const uart_rx_pin = 1;

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
    gpio.put(led, 1);

    const uart = rp2040.uart.UART.init(uart_id, .{
        .baud_rate = baud_rate,
        .tx_pin = uart_tx_pin,
        .rx_pin = uart_rx_pin,
        .clock_config = rp2040.clock_config,
    }).writer();

    while (true) {
        gpio.put(led, 1);
        const khz = clocks.countFrequencyKhz(.clk_sys, rp2040.clock_config);
        try uart.print("hello worlb\r\n", .{khz});
        time.sleepMs(500);

        gpio.put(led, 0);
        time.sleepMs(500);
    }
}
