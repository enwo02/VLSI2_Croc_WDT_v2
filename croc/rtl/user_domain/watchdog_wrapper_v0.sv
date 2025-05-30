// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Elio Wanner <ewanner@ethz.ch>
// - Miguel Correa <mcorrea@ethz.ch>

//------------------------------------------------------------------------------
// Watch-dog OBI wrapper  (8-byte register block)
//   0x00  W   Kick      – write anything to reset the counter
//   0x04  RW  Timeout   – 32-bit timeout value
//------------------------------------------------------------------------------
`include "obi/typedef.svh"
`include "obi/assign.svh"

module watchdog_wrapper #(
  parameter logic [31:0]       BASE_ADDR = 32'h2000_0000,
  parameter obi_pkg::obi_cfg_t ObiCfg    = obi_pkg::ObiDefaultConfig,
  parameter type               obi_req_t = logic,
  parameter type               obi_rsp_t = logic
) (
  input  logic     clk_i,
  input  logic     rst_ni,

  // OBI subordinate port ------------------------------------------------------
  input  obi_req_t obi_req_i,
  output obi_rsp_t obi_rsp_o,

  // System reset generated by the watchdog ------------------------------------
  output logic     sys_rst_o
);

  // ---------------------------------------------------------------------------
  // 1. Pipeline the incoming request (aligns with the other Croc slaves)
  // ---------------------------------------------------------------------------
  logic                       req_q;
  logic                       we_q;
  logic [3:0]                 addr_lo_q;
  logic [3:0]                 be_q;
  logic [ObiCfg.IdWidth-1:0]  aid_q;
  logic [31:0]                wdata_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      req_q     <= 1'b0;
      we_q      <= 1'b0;
      addr_lo_q <= '0;
      be_q      <= '0;
      aid_q     <= '0;
      wdata_q   <= '0;
    end else begin
      req_q     <= obi_req_i.req;
      we_q      <= obi_req_i.a.we;
      addr_lo_q <= obi_req_i.a.addr[3:0];
      be_q      <= obi_req_i.a.be;
      aid_q     <= obi_req_i.a.aid;
      wdata_q   <= obi_req_i.a.wdata;
    end
  end

  // ---------------------------------------------------------------------------
  // 2. Address decoding and handshake signals
  // ---------------------------------------------------------------------------
  logic hit_kick_q    = (addr_lo_q == 4'h0);
  logic hit_timeout_q = (addr_lo_q == 4'h4);
  logic addr_hit_q    = hit_kick_q | hit_timeout_q;

  // Grant / accept for the pipelined request
  logic gnt;
  assign gnt    = req_q & addr_hit_q;      // stay high as long as req_q is high
  logic accept  = gnt;                     // request taken in the same cycle

  // ---------------------------------------------------------------------------
  // 3. Read-response bookkeeping
  // ---------------------------------------------------------------------------
  logic                      rsp_pending_q, rsp_pending_d;
  logic                      pop_rsp;
  logic [ObiCfg.IdWidth-1:0] rid_q,  rid_d;
  logic [31:0]               rdata_q, rdata_d;
  logic                      rerr_q,  rerr_d;

  // rready only exists if the config enables it
  generate
    if (ObiCfg.UseRReady) begin : g_with_rready
      assign pop_rsp = obi_rsp_o.rvalid & obi_rsp_o.r.rready;
    end else begin : g_without_rready
      assign pop_rsp = obi_rsp_o.rvalid;
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // 4. Combinational section
  // ---------------------------------------------------------------------------
  logic        kick_pulse_d;
  logic [31:0] timeout_d;
  logic [31:0] timeout_q = 32'hFFFFFFFF;       // default to max timeout

  always_comb begin
    // defaults
    kick_pulse_d  = 1'b0;
    rdata_d       = '0;
    rerr_d        = 1'b0;
    rid_d         = aid_q;
    rsp_pending_d = rsp_pending_q;
    timeout_d     = timeout_q;

    if (accept) begin
      //------------------------- WRITE ----------------------------------------
      if (we_q) begin
        if (hit_kick_q) begin
          kick_pulse_d = 1'b1;
        end else if (hit_timeout_q) begin
          timeout_d = timeout_q;                // start from old value
          for (int i = 0; i < 4; i++)
            if (be_q[i])
              timeout_d[i*8 +: 8] = wdata_q[i*8 +: 8];
        end
        rsp_pending_d = 1'b1;
      //------------------------- READ -----------------------------------------
      end else begin
        if (hit_timeout_q)      rdata_d = timeout_q;
        else if (hit_kick_q)    rdata_d = 32'h0;
        else begin
          rdata_d = 32'hDEAD_BEEF;
          rerr_d  = 1'b1;
        end
        rsp_pending_d = 1'b1;                 // owe a read response
      end
    end

    // clear pending flag once response is taken
    if (rsp_pending_q && pop_rsp)
      rsp_pending_d = 1'b0;
  end

  // ---------------------------------------------------------------------------
  // 5. Sequential section
  // ---------------------------------------------------------------------------
  logic kick_pulse_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      kick_pulse_q  <= 1'b0;
      rsp_pending_q <= 1'b0;
      rid_q         <= '0;
      rdata_q       <= '0;
      rerr_q        <= 1'b0;
    end else begin
      kick_pulse_q  <= kick_pulse_d;
      timeout_q     <= timeout_d;
      rsp_pending_q <= rsp_pending_d;
      rid_q         <= rid_d;
      if (accept && !we_q) begin       // capture read data/err
        rdata_q <= rdata_d;
        rerr_q  <= rerr_d;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 6. Drive OBI response channel
  // ---------------------------------------------------------------------------
  always_comb begin
    obi_rsp_o = '0;                    // X-prop barrier
    obi_rsp_o.gnt     = gnt;
    obi_rsp_o.rvalid  = rsp_pending_q;//1'b1;
    obi_rsp_o.r.rdata = rdata_q;
    obi_rsp_o.r.rid   = rid_q;
    obi_rsp_o.r.err   = rerr_q;  
  end

  // ---------------------------------------------------------------------------
  // 7. Instantiate watchdog core
  // ---------------------------------------------------------------------------
  watchdog i_watchdog (
    .clk_i     ( clk_i        ),
    .rst_ni    ( rst_ni       ),
    .kick_i    ( kick_pulse_q ),
    .timeout_i ( timeout_q    ),
    .sys_rst_o ( sys_rst_o    )
  );

endmodule
