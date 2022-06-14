`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Wuhan University
// Engineer: Xuanyu Hu
// 
// Create Date: 2022/04/27 16:39:33
// Design Name: vigna_v1
// Module Name: vigna
// Project Name: vigna
// Description: A simple RV32I CPU core
// 
// Dependencies: none
// 
// Revision: 
// Revision 1.07 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//vigna top module
module vigna#(
    parameter RESET_ADDR = 32'h0000_0000
    )(
    input clk,
    input resetn,

    output reg        i_valid,
    input             i_ready,
    output     [31:0] i_addr,
    input      [31:0] i_rdata,
    output     [31:0] i_wdata,
    output     [ 3:0] i_wstrb,

    output reg        d_valid,
    input             d_ready,
    output reg [31:0] d_addr,
    input      [31:0] d_rdata,
    output reg [31:0] d_wdata,
    output reg [ 3:0] d_wstrb
);

assign i_wdata = 32'h0;
assign i_wstrb = 4'h0;

//program counter
reg  [31:0] pc;
wire [31:0] pc_next;

//part 1: fetching unit
wire [31:0] inst;
wire [31:0] inst_addr;
reg  [ 1:0] fetch_state;

reg fetch_recieved;
wire fetched;
assign fetched = (fetch_state == 1 && i_ready) || fetch_state == 3;

assign inst = i_ready ? i_rdata : inst;
assign inst_addr = i_addr;
assign i_addr = pc;

always @ (posedge clk) begin
    //reset logic
    if (!resetn) begin
        pc          <= RESET_ADDR;
        fetch_state <= 0;
        i_valid     <= 0;
    end else begin
        //fetch logic
        case (fetch_state)
            0: begin
                i_valid     <= 1;
                fetch_state <= 1;
            end
            1: begin
                if (i_ready) begin
                    i_valid     <= 0;
                    fetch_state <= 3;
                end
            end
            3: begin
                if (fetch_recieved) begin
                    i_valid     <= 1;
                    pc          <= pc_next;
                    fetch_state <= 1;
                end
            end
            default: begin
                i_valid     <= 0;
                fetch_state <= 0;
            end
        endcase
    end
end

//decode logic
wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;
wire [4:0] rd;
wire [4:0] rs1;
wire [4:0] rs2;

assign opcode = inst[6:0];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];
assign rd     = inst[11:7];
assign rs1    = inst[19:15];
assign rs2    = inst[24:20];

wire funct7_zero, funct7_sub_sra;
assign funct7_zero = funct7 == 0;
assign funct7_sub_sra = funct7 == 7'b0100000;

wire r_type, i_type, s_type, u_type, b_type, j_type;
assign r_type = opcode == 7'b0110011;
assign i_type = opcode == 7'b0010011 || opcode == 7'b0000011 || opcode == 7'b1100111;
assign s_type = opcode == 7'b0100011;
assign u_type = opcode == 7'b0110111 || opcode == 7'b0010111;
assign b_type = opcode == 7'b1100011;
assign j_type = opcode == 7'b1101111;

wire [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;
//always sign extend
assign i_imm = {{20{inst[31]}}, inst[31:20]};
assign s_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
assign b_imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
assign u_imm = {inst[31:12], 12'b0};
assign j_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

wire [4:0] shamt;
assign shamt = inst[24:20];

//r type
wire is_add, is_sub, is_sll, is_slt, is_sltu, is_xor, is_srl, is_sra, is_or, is_and;
assign is_add  = funct3 == 3'b000 && funct7_zero    && r_type;
assign is_sub  = funct3 == 3'b000 && funct7_sub_sra && r_type;
assign is_sll  = funct3 == 3'b001 && funct7_zero    && r_type;
assign is_slt  = funct3 == 3'b010 && funct7_zero    && r_type;
assign is_sltu = funct3 == 3'b011 && funct7_zero    && r_type;
assign is_xor  = funct3 == 3'b100 && funct7_zero    && r_type;
assign is_srl  = funct3 == 3'b101 && funct7_zero    && r_type;
assign is_sra  = funct3 == 3'b101 && funct7_zero    && r_type;
assign is_or   = funct3 == 3'b110 && funct7_zero    && r_type;
assign is_and  = funct3 == 3'b111 && funct7_zero    && r_type;

//i type
wire is_addi, is_slli, is_slti, is_sltiu, is_xori, is_srli, is_srai, is_ori, is_andi;
wire is_jalr, is_lb, is_lh, is_lw, is_lbu, is_lhu;
assign is_addi  = opcode == 7'b0010011 && funct3 == 3'b000 && i_type;
assign is_slli  = opcode == 7'b0010011 && funct3 == 3'b001 && i_type;
assign is_slti  = opcode == 7'b0010011 && funct3 == 3'b010 && i_type;
assign is_sltiu = opcode == 7'b0010011 && funct3 == 3'b011 && i_type;
assign is_xori  = opcode == 7'b0010011 && funct3 == 3'b100 && i_type;
assign is_srli  = opcode == 7'b0010011 && funct3 == 3'b101 && i_type && funct7 == 7'b0000000;
assign is_srai  = opcode == 7'b0010011 && funct3 == 3'b101 && i_type && funct7 == 7'b0100000;
assign is_ori   = opcode == 7'b0010011 && funct3 == 3'b110 && i_type;
assign is_andi  = opcode == 7'b0010011 && funct3 == 3'b111 && i_type;
assign is_jalr  = opcode == 7'b1100111 && funct3 == 3'b000 && i_type;
assign is_lb    = opcode == 7'b0000011 && funct3 == 3'b000 && i_type;
assign is_lh    = opcode == 7'b0000011 && funct3 == 3'b001 && i_type;
assign is_lw    = opcode == 7'b0000011 && funct3 == 3'b010 && i_type;
assign is_lbu   = opcode == 7'b0000011 && funct3 == 3'b100 && i_type;
assign is_lhu   = opcode == 7'b0000011 && funct3 == 3'b101 && i_type;

wire is_load;
assign is_load = is_lb || is_lh || is_lw || is_lbu || is_lhu;

//s type
wire is_sb, is_sh, is_sw;
assign is_sb = funct3 == 3'b000 && s_type;
assign is_sh = funct3 == 3'b001 && s_type;
assign is_sw = funct3 == 3'b010 && s_type;

//b type
wire is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu;
assign is_beq  = funct3 == 3'b000 && b_type;
assign is_bne  = funct3 == 3'b001 && b_type;
assign is_blt  = funct3 == 3'b100 && b_type;
assign is_bge  = funct3 == 3'b101 && b_type;
assign is_bltu = funct3 == 3'b110 && b_type;
assign is_bgeu = funct3 == 3'b111 && b_type;

//u type
wire is_lui, is_auipc;
assign is_lui   = opcode == 7'b0110111 && u_type;
assign is_auipc = opcode == 7'b0010111 && u_type;

//j type
wire is_jal;
assign is_jal = j_type;

//illegal instruction
wire is_illegal;
assign is_illegal = !(is_add || is_sub || is_sll || is_slt || is_sltu || is_xor || is_srl || is_sra || is_or || is_and || is_addi || is_slli || is_slti || is_sltiu || is_xori || is_srli || is_srai || is_ori || is_andi || is_jalr || is_lb || is_lh || is_lw || is_lbu || is_lhu || is_sb || is_sh || is_sw || is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu || is_lui || is_auipc || is_jal);


//cpu regs
reg [31:0] cpu_regs[31:1];
//rs from reg
wire [31:0] rs1_val;
assign rs1_val = rs1 == 0 ? 32'd0 : cpu_regs[rs1];
//rs2 from reg
wire [31:0] rs2_val;
assign rs2_val = rs2 == 0 ? 32'd0 : cpu_regs[rs2];


wire [31:0] op1, op2;
assign op1 = is_jal ? j_imm :
             u_type ? u_imm :
             rs1_val;
assign op2 = r_type || b_type   ? rs2_val :
             s_type             ? s_imm :
             is_auipc || j_type ? inst_addr :
             is_slli || is_srli ? {27'b0, shamt} :
             is_lui             ? 32'd0 :
             i_imm; 

//backend state
reg [3:0] exec_state;

//source reg
reg [31:0] d1, d2, d3;

//result
wire [31:0] dr;

//write back
reg [4:0] wb_reg;

//nums for signed compare
wire [32:0] sd1, sd2;
assign sd1 = d1 + 33'b0_1000_0000_0000_0000_0000_0000_0000_0000;
assign sd2 = d2 + 33'b0_1000_0000_0000_0000_0000_0000_0000_0000;

//alu comb logic
assign dr = 
    is_add || is_addi || is_jal || s_type
    || is_jalr || is_load || u_type ? d1 + d2 :
    is_sub                          ? d1 - d2 : 
    is_sll || is_slli               ? d1 << d2 : 
    is_slt || is_slti               ? (sd1[31:0] >= sd2[31:0] ? 32'd1 : 32'd0) : 
    is_sltu || is_sltiu             ? (d1 < d2 ? 32'd1 : 32'd0) : 
    is_xor || is_xori               ? d1 ^ d2 : 
    is_srl || is_srli               ? d1 >> d2 : 
    is_sra || is_srai               ? d1 >>> d2 : 
    is_or || is_ori                 ? d1 | d2 : 
    is_and || is_andi               ? d1 & d2 : 
    is_beq                          ? (d1 == d2 ? 32'd1 : 32'd0) : 
    is_bne                          ? (d1 != d2 ? 32'd1 : 32'd0) : 
    is_blt                          ? (sd1[31:0] < sd2[31:0] ? 32'd1 : 32'd0) : 
    is_bge                          ? (sd1[31:0] >= sd2[31:0] ? 32'd1 : 32'd0) : 
    is_bltu                         ? (d1 < d2 ? 32'd1 : 32'd0) : 
    is_bgeu                         ? (d1 >= d2 ? 32'd1 : 32'd0) :
    is_illegal                      ? 32'd0 : 32'd0;

//branch addr and return addr
reg [31:0] branch_addr, return_addr;

reg ex_branch;
reg ex_jump;
reg [3:0] ex_type;
reg [3:0] ls_strb;
reg ls_sign_extend;

assign pc_next = ex_branch ? (dr[0] ? branch_addr : pc + 32'd4) : ex_jump ? dr : pc + 32'd4;

reg write_mem;

//part2. executon unit
always @ (posedge clk) begin
    //reset logic
    if (!resetn) begin
        d_valid        <= 0;
        d_addr         <= 0;
        d_wdata        <= 0;
        d_wstrb        <= 0;
        d1             <= 0;
        d2             <= 0;
        d3             <= 0;
        exec_state     <= 0;
        fetch_recieved <= 0;
        wb_reg         <= 0;
        ex_jump        <= 0;
        ex_branch      <= 0;
        branch_addr    <= 0;
        return_addr    <= 0;
        write_mem      <= 0;
        ls_strb        <= 0;
        ls_sign_extend <= 0;
    end else begin
        //state machine
        case (exec_state)
            0: begin
                if (fetched) begin
                    d1 <= op1;
                    d2 <= op2;
                    if (s_type) begin
                        d3 <= rs2_val;
                    end else begin
                        d3 <= 0;
                    end
                
                    fetch_recieved <= 1;
                    
                    if (u_type || j_type || i_type || r_type) begin
                        wb_reg <= rd;
                    end else begin
                        wb_reg <= 0;
                    end
                    branch_addr <= inst_addr + b_imm;
                    return_addr <= inst_addr + 32'd4;
                    ex_branch   <= b_type;
                    ex_jump     <= is_jal || is_jalr;

                    //next state logic
                    if (is_load || s_type) begin
                        exec_state <= 4'b0001;
                        if (!is_load) begin
                            write_mem <= 1;
                        end else begin
                            write_mem <= 0;
                        end
                    end
                    else if (r_type || (i_type & !is_load & !is_jalr) || u_type || is_illegal) begin
                        exec_state <= 4'b0010;
                    end
                    else if (is_jal || is_jalr) begin
                        exec_state <= 4'b0100;
                    end
                    else if (b_type) begin
                        exec_state <= 4'b1000;
                    end
                    else begin
                        exec_state <= 4'b0000;
                    end

                    //set strobe
                    if (is_lw || is_sw) ls_strb <= 4'b1111;
                    else if (is_lh || is_lhu || is_sh) ls_strb <= 4'b0011;
                    else if (is_lb || is_lbu || is_sb) ls_strb <= 4'b0001;

                    if (is_lw || is_lh || is_lb) ls_sign_extend <= 1;
                    else ls_sign_extend <= 0;
                end
                
            end
            4'b0001: begin
                fetch_recieved <= 0;
                //load/store func
                if (!write_mem) begin
                    d_valid    <= 1;
                    d_addr     <= dr;
                    d_wstrb    <= 0;
                    exec_state <= 4'b0011;
                end else begin
                    d_valid    <= 1;
                    d_addr     <= dr;
                    d_wdata    <= d3;
                    d_wstrb    <= ls_strb;
                    exec_state <= 4'b0101;
                end

            end
            4'b0010: begin
                //calc func
                exec_state <= 0;
                if (wb_reg != 0) begin
                    cpu_regs[wb_reg] <= dr;
                end
                fetch_recieved <= 0;
            end
            4'b0100: begin
                //jump func
                exec_state <= 0;
                if (wb_reg != 0) begin
                    cpu_regs[wb_reg] <= return_addr;
                end
                fetch_recieved <= 0;
            end
            4'b1000: begin
                //branch func
                exec_state     <= 0;
                fetch_recieved <= 0;
            end
            4'b0011: begin
                //load wait stage
                if (d_ready) begin
                    exec_state <= 0;
                    d_valid    <= 0;
                    if (wb_reg != 0) begin
                        if      (!ls_sign_extend)    cpu_regs[wb_reg] <= d_rdata & {{8{ls_strb[3]}}, {8{ls_strb[2]}}, {8{ls_strb[1]}}, {8{ls_strb[0]}}};
                        else if (ls_strb == 4'b0001) cpu_regs[wb_reg] <= {{24{d_rdata[7]}}, d_rdata[7:0]};
                        else if (ls_strb == 4'b0011) cpu_regs[wb_reg] <= {{16{d_rdata[15]}}, d_rdata[15:0]};
                        else                         cpu_regs[wb_reg] <= d_rdata;
                    end
                end
                fetch_recieved <= 0;
            end
            4'b0101: begin
                //store wait stage
                if (d_ready) begin
                    exec_state <= 0;
                    d_valid    <= 0;
                    d_wstrb    <= 4'd0;
                    d_wdata    <= 0;
                end
                fetch_recieved <= 0;

            end
            default: begin
                exec_state <= 0;
            end
        endcase
    end
end


endmodule
