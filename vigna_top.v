`include "core.v"
`include "utils/bus2to1.v"

module vigna_top#(
    parameter RESET_ADDR = 32'h0000_0000
    )(
    input clk,
    input resetn,

    output        m_valid,
    input         m_ready,
    output [31:0] m_addr,
    input  [31:0] m_rdata,
    output [31:0] m_wdata,
    output [ 3:0] m_wstrb
    );

wire i_valid;
wire i_ready;
wire [31:0] i_addr;
wire [31:0] i_rdata;

wire d_valid;
wire d_ready;
wire [31:0] d_addr;
wire [31:0] d_rdata;
wire [31:0] d_wdata;
wire [3:0] d_wstrb;

//vigna core instant
vigna #(
    .RESET_ADDR(RESET_ADDR)
    )
    core_inst(
    .clk(clk),
    .resetn(resetn),
    .i_valid(i_valid),
    .i_ready(i_ready),
    .i_addr(i_addr),
    .i_rdata(i_rdata),
    .d_valid(d_valid),
    .d_ready(d_ready),
    .d_addr(d_addr),
    .d_rdata(d_rdata),
    .d_wdata(d_wdata),
    .d_wstrb(d_wstrb)
    );

//bus2to1 instant
bus2to1 b21(
    .clk(clk),
    .resetn(resetn),
    .m1_valid(i_valid),
    .m1_ready(i_ready),
    .m1_addr(i_addr),
    .m1_rdata(i_rdata),
    .m1_wdata(32'd0),
    .m1_wstrb(4'd0),
    .m2_valid(d_valid),
    .m2_ready(d_ready),
    .m2_addr(d_addr),
    .m2_rdata(d_rdata),
    .m2_wdata(d_wdata),
    .m2_wstrb(d_wstrb),
    .s_valid(m_valid),
    .s_ready(m_ready),
    .s_addr(m_addr),
    .s_rdata(m_rdata),
    .s_wdata(m_wdata),
    .s_wstrb(m_wstrb)
    );
    


endmodule
