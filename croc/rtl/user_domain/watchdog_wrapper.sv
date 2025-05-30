// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Elio Wanner <ewanner@ethz.ch>
// - Miguel Correa <corream@ethz.ch>
//------------------------------------------------------------------------------
`include "common_cells/registers.svh"

module watchdog_wrapper #(
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

  // Define some registers to hold the requests fields
  logic req_d, req_q;
  logic we_d, we_q;
  logic [ObiCfg.AddrWidth-1:0] addr_d, addr_q;
  logic [ObiCfg.IdWidth-1:0] id_d, id_q;
  logic [ObiCfg.DataWidth-1:0] wdata_d, wdata_q;

  // Signals used to create the response
  logic [ObiCfg.DataWidth-1:0] rsp_data; // Data field of the obi response
  logic rsp_err; // Error field of the obi response

  // Internal signals, registers
  logic [31:0] timeout_d, timeout_q;
  logic        kick_pulse_d, kick_pulse_q;
  logic        sys_rst_d, sys_rst_q;

  // Flip flops from registers.shv
  `FF(timeout_q, timeout_d, 32'hFFFFFFFF);
  `FF(kick_pulse_q, kick_pulse_d, '0);
  `FF(sys_rst_q, sys_rst_d, '0);

  `FF(req_q, req_d, '0);
  `FF(id_q , id_d , '0);
  `FF(we_q , we_d , '0);
  `FF(wdata_q , wdata_d , '0);
  `FF(addr_q , addr_d , '0);


  assign req_d = obi_req_i.req;
  assign id_d = obi_req_i.a.aid;
  assign we_d = obi_req_i.a.we;
  assign addr_d = obi_req_i.a.addr;
  assign wdata_d = obi_req_i.a.wdata;

  // Address decoding
  logic [1:0] word_addr;
  always_comb begin
    rsp_data = '0;
    rsp_err  = '0;
    word_addr = addr_q[3:2];
    timeout_d = timeout_q;
    kick_pulse_d = 1'b0;

    if(req_q) begin
      case(word_addr)
        2'h0: begin
          if(we_q) begin
            kick_pulse_d = 1'b1;
          end else begin
            rsp_err = '1;
          end
        end
        2'h1: begin
          if(we_q) begin
            timeout_d = wdata_q;
          end else begin
            rsp_data = timeout_q;
          end
        end
        default: rsp_data = 32'hffffffff;
      endcase
    end
  end

  // Wire the output
  assign sys_rst_o = sys_rst_q; // One cycle delay to have time to "see" signal
  // Wire the response
  // A channel
  assign obi_rsp_o.gnt = obi_req_i.req;
  // R channel:
  assign obi_rsp_o.rvalid = req_q;
  assign obi_rsp_o.r.rdata = rsp_data;
  assign obi_rsp_o.r.rid = id_q;
  assign obi_rsp_o.r.err = rsp_err;
  assign obi_rsp_o.r.r_optional = '0;

  // Instantiate watchdog core
  watchdog i_watchdog (
    .clk_i     ( clk_i        ),
    .rst_ni    ( rst_ni       ),
    .kick_i    ( kick_pulse_q ),
    .timeout_i ( timeout_q    ),
    .sys_rst_o ( sys_rst_d    )
  );

endmodule
