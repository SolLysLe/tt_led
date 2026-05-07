// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
// `timescale 1ns / 10ps

module spi (
    input sck,
    input clk,
    input sdi,
    input cs,
    output reg [23:0] received_data,
    output reg pixel_received
);

  // Oversampling everything to take it into the FPGA/ASIC clock domain
  reg [2:0] sck_reg;
  reg [2:0] cs_reg;
  reg [1:0] sdi_reg;

  always @(posedge clk) begin
    sck_reg <= {sck_reg[1:0], sck};
    cs_reg  <= {cs_reg[1:0], cs};
    sdi_reg <= {sdi_reg[0], sdi};
  end

  wire sck_rising_edge = (sck_reg[2:1] == 2'b01);
  wire cs_active = !cs_reg[1];
  wire sdi_data = sdi_reg[1];

  // Receive 24 bits
  reg [4:0] bit_count;

  always @(posedge clk) begin
    if (!cs_active) begin
      bit_count <= 5'b00000;
    end else if (sck_rising_edge) begin  // Sample SDI on rising edge
      bit_count <= bit_count + 5'b00001;
      received_data <= {received_data[22:0], sdi_data};
      if (bit_count == 5'b10111) begin
        bit_count <= 0;
      end
    end
  end

  always @(posedge clk) begin
    pixel_received <= cs_active && sck_rising_edge && (bit_count == 5'b10111);
  end

endmodule
