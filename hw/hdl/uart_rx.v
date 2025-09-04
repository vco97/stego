//-----------------------------------------------------------------------------
// UART_RX Module
//
// Description:
//   This module receives 8-bit data over a UART serial line.
//   It assumes the following format: 1 start bit, 8 data bits, 1 stop bit.
//   The module is synchronized to a single-cycle pulse that occurs at the
//   beginning of each bit period, simplifying the bit-timing logic.
//
// Inputs:
//   clk         - 64 MHz system clock
//   rst_n       - Active-low reset
//   rx_tick     - A single-cycle pulse at the beginning of each bit period
//   rx_in       - The serial data input line
//
// Outputs:
//   rx_data_out - 8-bit received data (valid for one clock cycle when rx_done is high)
//   rx_done     - A single-cycle pulse indicating valid data is available
//
//-----------------------------------------------------------------------------
module uart_rx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx_tick,
    input  wire        rx_in,
    output reg  [7:0]  rx_data_out,
    output reg         rx_done
);

    // State definitions for the receiver FSM
    localparam STATE_IDLE    = 3'b000;
    localparam STATE_START   = 3'b001;
    localparam STATE_DATA    = 3'b010;
    localparam STATE_STOP    = 3'b011;

    // FSM State and counter registers
    reg  [2:0]  current_state;
    reg  [2:0]  bit_count;
    reg  [7:0]  rx_data_reg;

    // Output registers initialization
    initial begin
        rx_data_out = 8'h00;
        rx_done     = 1'b0;
    end

    // Main FSM logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous reset
            current_state <= STATE_IDLE;
            bit_count     <= 3'b000;
            rx_data_reg   <= 8'h00;
            rx_done       <= 1'b0;
            rx_data_out   <= 8'h00;
        end else begin
            // Default assignments to prevent latch inference
            rx_done <= 1'b0;

            case (current_state)
                STATE_IDLE: begin
                    // Wait for the start bit (active low)
                    if (rx_tick && !rx_in) begin
                        current_state <= STATE_DATA;
                        bit_count     <= 3'b000;
                    end
                end

                STATE_DATA: begin
                    if (rx_tick) begin
                        // Shift in the received data bit
                        rx_data_reg <= {rx_in, rx_data_reg[7:1]};
                        bit_count   <= bit_count + 1;
                        
                        // Check if all 8 data bits have been received
                        if (bit_count == 3'd7) begin
                            current_state <= STATE_STOP;
                        end
                    end
                end
                
                STATE_STOP: begin
                    // Wait for the stop bit (active high)
                    if (rx_tick) begin
                        if (rx_in) begin
                            // Stop bit received successfully, data is valid
                            rx_data_out <= rx_data_reg;
                            rx_done     <= 1'b1;
                        end
                        // Transition back to idle state
                        current_state <= STATE_IDLE;
                    end
                end
                
                default: begin
                    // Should not happen, but for completeness
                    current_state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
