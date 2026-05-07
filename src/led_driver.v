// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Simulation timestep
// `timescale 1ns / 10ps

module led_driver (
    input clk,
    input reset_n,
    input [23:0] data,
    input new_pixel,
    output reg din,
    output reg ready,
    output [1:0] status
);

  // assign new_pixel = BTN2;
  // Define timing parameters according to WS2812B datasheet
  localparam T0H = 400e-9;  // width of '0' high pulse (400ns)
  localparam T1H = 800e-9;  // width of '1' high pulse (800ns)
  localparam T0L = 850e-9;  // width of '0' low pulse (850ns)
  localparam T1L = 450e-9;  // width of '1' low pulse (450ns)
  localparam PERIOD = 1250e-9;  // total period of one bit (1250ns)
  localparam RES_DELAY = 300e-6;  // reset duration (300us)

  // Calculate clock cycles needed based on input clock frequency
  parameter CLOCK_FREQ = 12e6;  // 12MHz clock frequency

  // Calculate clock cycles for each timing parameter
  localparam [15:0] CYCLES_PERIOD = $floor(CLOCK_FREQ * PERIOD);
  localparam [15:0] CYCLES_T0H = $floor(CLOCK_FREQ * T0H);
  localparam [15:0] CYCLES_T1H = $floor(CLOCK_FREQ * T1H);
  localparam [15:0] CYCLES_T0L = CYCLES_PERIOD - CYCLES_T0H;
  localparam [15:0] CYCLES_T1L = CYCLES_PERIOD - CYCLES_T1H;
  localparam [15:0] CYCLES_RESET = $floor(CLOCK_FREQ * RES_DELAY);

  // state machine
  parameter RST = 0, READY = 1, SENDING = 2;
  reg [1:0] state;
  assign status = state;
  reg [ 4:0] bit_index;
  reg [15:0] time_counter = 0;

  always @(posedge clk, negedge reset_n) begin
    if (!reset_n) begin
      state <= RST;
      time_counter <= 0;
      din <= 0;
      ready <= 0;
      bit_index <= 0;
    end else begin
      case (state)
        RST: begin
          if (time_counter < CYCLES_RESET - 1) begin
            time_counter <= time_counter + 1;
          end else begin
            state <= READY;
          end
        end

        READY: begin
          if (new_pixel) begin
            state <= SENDING;
            din <= 1;
            bit_index <= 0;
            time_counter <= 0;
          end else begin
            din   <= 0;
            ready <= 1;
          end
        end

        SENDING: begin
          if (time_counter < CYCLES_PERIOD - 1) begin
            ready <= 0;
            time_counter <= time_counter + 1;
            if (time_counter < (data[5'd23-bit_index] ? CYCLES_T1H : CYCLES_T0H)) begin
              din <= 1;
            end else begin
              din <= 0;
            end
          end else if (bit_index < 5'd23) begin
            time_counter <= 0;
            bit_index <= bit_index + 1;
          end else begin
            state <= READY;
          end
        end

        default: begin
          state <= RST;
        end
      endcase
    end
  end

endmodule
