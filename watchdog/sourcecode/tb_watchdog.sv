// Created on: 15.03.2025
// Created by: Miguel Correa
//
// Last modified on: 26.03.2025
// Modified by: Miguel Correa
//
// Description: This file contains the implementation of the WDT module testbench.

`timescale 1ns / 1ps
module tb_watchdog;

  //------------------ Structs and Parameters ------------------//
  parameter  T_CLK_HI       = 5ns;                 // set clock high time
  parameter  T_CLK_LO       = 5ns;                 // set clock low time
  localparam T_CLK          = T_CLK_HI + T_CLK_LO; // calculate clock period
  parameter  T_APPL_DEL     = 1ns;                 // set stimuli application delay
  parameter  T_ACQ_DEL      = 5ns;                 // set response acquisition delay

  parameter int NUM_VECTOR  = 32;                   // number of vectors in stimuli

  parameter STIMULI_FILE    = "./stimuli/stimuli.txt";
  parameter RESPONSE_FILE   = "./stimuli/expected_response.txt";

  typedef struct packed {
    logic [31:0]  timeout;
    logic [31:0]  kick_t;
  } stimuli_t;

  typedef struct packed {
    logic         syst_rst; 
    logic [31:0]  syst_rst_t;
  } exp_rsp_t;

  //------------------ Logic Wires ------------------//
  logic       eoc;                   // End of computation
  stimuli_t   stimuli[];             // Input stimuli array
  exp_rsp_t   exp_response[];        // Expected responses
  exp_rsp_t   actual_responses[];    // Captured responses

  logic       clk;
  logic       rst_n;
  logic       kick;                  // Kick signal to DUT
  logic [31:0] timeout;              // Timeout threshold input
  logic        syst_rst;             // System reset output

  //------------------ Clock and Reset Generation ------------------//
  initial begin
    forever begin
      clk = 1'b1; #T_CLK_HI;
      clk = 1'b0; #T_CLK_LO;
    end
  end

  initial begin
    rst_n = 1'b0;
    #(2*T_CLK);
    rst_n = 1'b1;
  end

  //------------------ Design Under Test ------------------//
  watchdog i_dut (
    .clk_i      (clk),
    .rst_ni     (rst_n),
    .kick_i     (kick),
    .timeout_i  (timeout),
    .sys_rst_o  (syst_rst)
  );

  //------------------ Stimuli Application ------------------//
  initial begin : stim_apply
    int cycle_count;
    bit sys_rst_triggered;

    $dumpfile("watchdog.vcd");
    $dumpvars(1, i_dut);

    load_stimuli(STIMULI_FILE);
    actual_responses = new[stimuli.size()];

    foreach (stimuli[i]) begin
      // Initialize for new vector
      timeout = stimuli[i].timeout;
      kick = 0;
      cycle_count = 0;
      //sys_rst_triggered = 0;
      rst_n = 0;
      @(negedge clk) rst_n = 1;

      fork
        // Monitor for system reset
        begin
          wait (syst_rst);
          //sys_rst_triggered = 1;
          actual_responses[i].syst_rst = 1'b1;
          actual_responses[i].syst_rst_t = cycle_count;
        end

        // Apply kick after kick_t cycles
        begin
          repeat (stimuli[i].kick_t) @(posedge clk) cycle_count++;
          if (!syst_rst) begin
            kick = 1;
            actual_responses[i].syst_rst_t = cycle_count;
            @(posedge clk) kick = 0;
            cycle_count++;
          end
        end
      join_any
      disable fork;

      // Wait 2 cycles between vectors
      repeat (2) @(posedge clk);
    end

    eoc = 1;
    $dumpflush;
  end

  //------------------ Response Checking ------------------//
  initial begin : resp_check
    wait(eoc); // Wait for all vectors to complete
    load_exp_response(RESPONSE_FILE);

    foreach (exp_response[i]) begin
      if (actual_responses[i] !== exp_response[i]) begin
        $error("Mismatch at vector %0d: Exp(syst_rst=%b, t=%0d) Act(syst_rst=%b, t=%0d)",
               i, exp_response[i].syst_rst, exp_response[i].syst_rst_t,
               actual_responses[i].syst_rst, actual_responses[i].syst_rst_t);
      end else begin
        $display("Vector %0d: Pass", i);
      end
    end
    $finish;
  end

  //------------------ File Loading Tasks ------------------//
  task load_stimuli(input string filename);
    int file, i=0;
    string line;
    logic [63:0] temp;

    file = $fopen(filename, "r");
    if (!file) $fatal(1, "Failed to open %s", filename);

    stimuli = new[0];
    while ($fgets(line, file)) begin
      stimuli = new[stimuli.size()+1] (stimuli);
      $sscanf(line, "%b", temp);
      stimuli[i].timeout = temp[63:32];
      stimuli[i].kick_t  = temp[31:0];
      i++;
    end
    $fclose(file);
  endtask

  task load_exp_response(input string filename);
    int file, i=0;
    string line;
    logic [32:0] temp;

    file = $fopen(filename, "r");
    if (!file) $fatal(1, "Failed to open %s", filename);

    exp_response = new[0];
    while ($fgets(line, file)) begin
      exp_response = new[exp_response.size()+1] (exp_response);
      $sscanf(line, "%b", temp);
      exp_response[i].syst_rst   = temp[32];
      exp_response[i].syst_rst_t = temp[31:0];
      i++;
    end
    $fclose(file);
  endtask

endmodule
