/*
 * Copyright (c) 2025 Daniel Theunissen
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_led_matrix_driver (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // I/O Pins

  // Assign unused pins to 0
  assign uio_out = 0;
  assign uio_oe = 0;
  assign uo_out[7:5] = 0;

  // SCK
  wire SCK;
  assign SCK = ui_in[0];

  // SDI
  wire SDI;
  assign SDI = ui_in[1];

  // CS
  wire CS;
  assign CS = ui_in[2];

  // RESET
  wire RESET;
  assign RESET = rst_n;

  // CLK
  wire CLK;
  assign CLK = clk;

  // DIN
  wire DIN;
  assign uo_out[0] = DIN;

  // LED1
  wire LED1;
  assign uo_out[1] = LED1;

  // LED2
  wire LED2;
  assign uo_out[2] = LED2;

  wire [1:0] status;
  assign uo_out[4:3] = status;

  serial_matrix_driver driver (
      .CLK(CLK),
      .RESET(RESET),
      .SCK(SCK),
      .SDI(SDI),
      .CS(CS),
      .DIN(DIN),
      .LED1(LED1),
      .LED2(LED2),
      .status(status)
  );

endmodule
