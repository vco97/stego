//-----------------------------------------------------------------------------
// Top_UART_Loopback Module (Updated for separate RX and TX pins)
//
// Description:
//   This module combines the UART_RX and UART_TX modules to create a
//   simple loopback testbench. It receives a byte on rx_pin, and once the
//   reception is complete, it triggers the transmission of that same byte
//   on tx_pin. It includes a simple baud rate generator.
//
// Inputs:
//   clk         - 64 MHz system clock
//   rst_n       - Active-low reset
//   rx_pin      - The serial data input from an external device
//
// Outputs:
//   tx_pin      - The serial data output to an external device
//
//-----------------------------------------------------------------------------
module top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx_pin,
    output wire        tx_pin
);

    // Internal wires for connecting the submodules
    wire [7:0]  rx_data;
    wire        rx_done;
    wire        tx_busy;
    wire        tx_en;
    wire        tick_pulse;

    // Baud Rate Generator Parameters
    // For 115200 baud rate on a 64 MHz clock
    // Clock cycles per bit = 64,000,000 / 115,200 = 555.55...
    // Clock cycles per bit = 64,000,000 / 9,800 = 6,530.61...
    // localparam BAUD_RATE_COUNTER_MAX = 555 - 1;
    localparam BAUD_RATE_COUNTER_MAX = 6530 - 1;

    //-------------------------------------------------------------------------
    // Baud Rate Generator
    //-------------------------------------------------------------------------
    reg  [12:0] baud_counter;
    reg         tick_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 10'b0;
            tick_reg     <= 1'b0;
        end else begin
            tick_reg <= 1'b0;
            if (baud_counter == BAUD_RATE_COUNTER_MAX) begin
                baud_counter <= 10'b0;
                tick_reg     <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1;
            end
        end
    end
    assign tick_pulse = tick_reg;
    
    //-------------------------------------------------------------------------
    // Loopback Logic
    //
    // - rx_done pulse triggers a new transmission.
    // - The tx_en signal must be a single-cycle pulse.
    // - It must only be high when tx_busy is low.
    //-------------------------------------------------------------------------
    reg tx_en_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_en_reg <= 1'b0;
        end else begin
            tx_en_reg <= rx_done && !tx_busy;
        end
    end
    assign tx_en = tx_en_reg;
    
    //-------------------------------------------------------------------------
    // Instantiation of the UART RX and TX modules
    //-------------------------------------------------------------------------

    // Instantiate the UART Receiver
    uart_rx u_uart_rx (
        .clk         (clk),
        .rst_n       (rst_n),
        .rx_tick     (tick_pulse),
        .rx_in       (rx_pin), // Connected to the dedicated RX pin
        .rx_data_out (rx_data),
        .rx_done     (rx_done)
    );

    // Instantiate the UART Transmitter
    uart_tx u_uart_tx (
        .clk         (clk),
        .rst_n       (rst_n),
        .tx_en       (tx_en),
        .tx_data_in  (rx_data),
        .tx_tick     (tick_pulse),
        .tx_out      (tx_pin), // Connected to the dedicated TX pin
        .tx_busy     (tx_busy)
    );

endmodule
