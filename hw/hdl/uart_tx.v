//-----------------------------------------------------------------------------
// UART_TX Module
//
// Description:
//   This module transmits 8-bit data over a UART serial line.
//   It assumes the following format: 1 start bit, 8 data bits, 1 stop bit.
//   The module is synchronized to a single-cycle pulse that occurs at the
//   beginning of each bit period.
//
// Inputs:
//   clk         - 64 MHz system clock
//   rst_n       - Active-low reset
//   tx_en       - A single-cycle pulse to trigger transmission
//   tx_data_in  - 8-bit data to be transmitted
//   tx_tick     - A single-cycle pulse at the beginning of each bit period
//
// Outputs:
//   tx_out      - The serial data output line
//   tx_busy     - High when a transmission is in progress
//
//-----------------------------------------------------------------------------
module uart_tx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        tx_en,
    input  wire [7:0]  tx_data_in,
    input  wire        tx_tick,
    output reg         tx_out,
    output reg         tx_busy
);

    // State definitions for the transmitter FSM
    localparam STATE_IDLE    = 3'b000;
    localparam STATE_START   = 3'b001;
    localparam STATE_DATA    = 3'b010;
    localparam STATE_STOP    = 3'b011;

    // FSM State and counter registers
    reg  [2:0]  current_state;
    reg  [3:0]  bit_count;
    reg  [7:0]  data_to_send;

    // Output registers initialization
    initial begin
        tx_out  = 1'b1; // Idle state is high
        tx_busy = 1'b0;
    end

    // Main FSM logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous reset
            current_state <= STATE_IDLE;
            bit_count     <= 4'b0000;
            data_to_send  <= 8'h00;
            tx_out        <= 1'b1;
            tx_busy       <= 1'b0;
        end else begin
            // Default assignments to prevent latch inference
            tx_busy <= tx_busy; // Retain current busy state

            case (current_state)
                STATE_IDLE: begin
                    tx_out <= 1'b1;
                    if (tx_en) begin
                        // Start transmission on rising edge of tx_en
                        current_state <= STATE_START;
                        data_to_send  <= tx_data_in;
                        bit_count     <= 4'b0000;
                        tx_busy       <= 1'b1;
                    end
                end

                STATE_START: begin
                    // Send start bit (logic 0)
                    tx_out <= 1'b0;
                    if (tx_tick) begin
                        current_state <= STATE_DATA;
                    end
                end

                STATE_DATA: begin
                    // Send data bits, LSB first
                    tx_out <= data_to_send[0];
                    if (tx_tick) begin
                        data_to_send <= data_to_send >> 1; // Shift right for next bit
                        bit_count    <= bit_count + 1;

                        // Check if all 8 data bits have been sent
                        if (bit_count == 4'd7) begin
                            current_state <= STATE_STOP;
                        end
                    end
                end

                STATE_STOP: begin
                    // Send stop bit (logic 1)
                    tx_out <= 1'b1;
                    if (tx_tick) begin
                        current_state <= STATE_IDLE;
                        tx_busy       <= 1'b0;
                    end
                end
                
                default: begin
                    current_state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
