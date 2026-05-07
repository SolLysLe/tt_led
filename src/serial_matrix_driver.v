// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
// `timescale 1ns / 10ps

module serial_matrix_driver (
    input CLK,
    input RESET,
    input SCK,
    input SDI,
    input CS,
    output DIN,
    output LED1,
    output LED2,
    output [1:0] status
);

  assign LED2 = !CS;

  wire [23:0] shift_register_data;
  wire latch_en;

  spi spi (
      .sck(SCK),
      .clk(CLK),
      .sdi(SDI),
      .cs(CS),
      .received_data(shift_register_data),
      .pixel_received(latch_en)
  );

  always @(posedge CLK) begin
    if (latch_en & ready) begin
      pixel_data <= shift_register_data;
    end
  end

  reg [23:0] pixel_data;
  wire ready;

  assign LED1 = ready;

  wire new_pixel_en;
  assign new_pixel_en = latch_en & !CS;

  led_driver led_driver (
      .clk(CLK),
      .reset_n(RESET),
      .data(pixel_data),
      .new_pixel(new_pixel_en),
      .ready(ready),
      .din(DIN),
      .status(status)
  );


endmodule
