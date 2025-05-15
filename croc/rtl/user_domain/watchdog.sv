// Created on: 14.03.2025
// Created by: Elio Wanner
//
// Last modified on: 22.03.2025
// Modified by: Miguel Correa, Elio Wanner
//
// Description: This file contains the implementation of the Watchdog Timer (WDT) module.

module watchdog (
    input  logic        clk_i,       // Clock input
    input  logic        rst_ni,      // Active-low reset
    input  logic        kick_i,      // Kick signal (OBI request signal)
    input  logic [31:0] timeout_i,   // Timeout threshold
    output logic        sys_rst_o    // System reset output (active-high)
);

    // Internal signals
    logic [31:0] counter_q, counter_d;  // Counter for timeout detection
    logic        timeout;               // Timeout flag

    // Next state logic for counter
    assign counter_d = (kick_i) ? 32'b0 : counter_q + 1;
    
    // Flip-flop for counter state
    always_ff @ (posedge clk_i,
                 negedge rst_ni) begin
        if (rst_ni == 1'b0) begin
            counter_q <= 32'b0;
        end else begin
            counter_q <= counter_d;
        end
    end

    // System reset logic (output)
    assign sys_rst_o = (counter_q >= timeout_i);

endmodule
