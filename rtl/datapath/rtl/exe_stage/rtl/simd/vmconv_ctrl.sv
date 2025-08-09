module vmconv_ctrl
    import drac_pkg::*;
    import riscv_pkg::*;
(
    input wire                  clk_i,           // Clock
    input wire                  rstn_i,          // Reset
    input rr_exe_simd_instr_t   instruction_i,   // Instruction input
    input rr_exe_simd_instr_t   sel_out_instr_i, // Instruction to select the output result
    input bus64_t               data_vs1_i,      // 64-bit source operand 1
    input bus64_t               data_vs2_i,      // 64-bit source operand 2
    input bus64_t               data_vm,         // 64-bit mask operands

    input bus64_t data2_vmul_i,
    input bus64_t result_vmul_i,

    input bus64_t data1_vaddsub_i,
    input bus64_t data2_vaddsub_i,
    input bus64_t result_vaddsub_i,

    input bus64_t result_vcomp_i,

    output bus64_t data_vs1_vcomp_o,
    output bus64_t data_vs2_vcomp_o,
    output bus64_t data_vs1_vmul_o,
    output bus64_t data_vs2_vmul_o,

    output bus64_t data_vs1_vaddsub_o,
    output bus64_t data_vs2_vaddsub_o,

    output instr_type_t vcomp_instr_type_o,
    output instr_type_t vmul_instr_type_o,
    output instr_type_t vaddsub_instr_type_o,

    output bus64_t result_vmcon_o

);


// VMERGE CTRL
logic [3:0] cnt_merge_stage;
logic pending_vmcon;
logic pending_vmcon_sh1;
logic rst_pending_vmcon;

bus64_t data_vs1_vmerge; //registers
bus64_t data_vs2_vmerge; //registers

bus64_t data_vs1_vmerge_comp;
bus64_t data_vs2_vmerge_comp;
bus64_t data_vs1_vmerge_mul;
bus64_t data_vs2_vmerge_mul;

assign data_vs1_vcomp_o =  (pending_vmcon) ? data_vs1_vmerge_comp : data_vs1_i;
assign data_vs2_vcomp_o =  (pending_vmcon) ? data_vs2_vmerge_comp : data_vs2_i;

assign data_vs1_vmul_o =  (pending_vmcon) ? data_vs1_vmerge_mul : data_vs1_i;
assign data_vs2_vmul_o =  (pending_vmcon) ? data_vs2_vmerge_mul : data2_vmul_i;

assign data_vs1_vaddsub_o = (pending_vmcon) ? result_vmul_i  : data1_vaddsub_i;
assign data_vs2_vaddsub_o = (pending_vmcon) ? result_vmcon_o : data2_vaddsub_i;

assign vcomp_instr_type_o = pending_vmcon ? VMSEQ : instruction_i.instr.instr_type;
assign vmul_instr_type_o = pending_vmcon ? VMUL : instruction_i.instr.instr_type;
assign vaddsub_instr_type_o = pending_vmcon ? VADD : sel_out_instr_i.instr.instr_type;


always_comb begin : merge_ctrl_comb
    case (cnt_merge_stage)
        0: begin
            case (instruction_i.instr.sew)
                SEW_8: begin

                    // Comparison Source
                    data_vs1_vmerge_comp[63:56] = data_vs1_vmerge[63:56];
                    data_vs1_vmerge_comp[55:48] = data_vs1_vmerge[63:56];
                    data_vs1_vmerge_comp[47:40] = data_vs1_vmerge[63:56];
                    data_vs1_vmerge_comp[39:32] = data_vs1_vmerge[63:56];
                    data_vs1_vmerge_comp[31:24] = data_vs1_vmerge[63:56];
                    data_vs1_vmerge_comp[23:16] = data_vs1_vmerge[63:56];
                    data_vs1_vmerge_comp[15:08] = data_vs1_vmerge[63:56];
                    data_vs1_vmerge_comp[07:00] = data_vs1_vmerge[55:48];

                    data_vs2_vmerge_comp[63:56] = data_vs1_vmerge[55:48];
                    data_vs2_vmerge_comp[55:48] = data_vs1_vmerge[47:40];
                    data_vs2_vmerge_comp[47:40] = data_vs1_vmerge[39:32];
                    data_vs2_vmerge_comp[39:32] = data_vs1_vmerge[31:24];
                    data_vs2_vmerge_comp[31:24] = data_vs1_vmerge[23:16];
                    data_vs2_vmerge_comp[23:16] = data_vs1_vmerge[15:08];
                    data_vs2_vmerge_comp[15:08] = data_vs1_vmerge[07:00];
                    data_vs2_vmerge_comp[07:00] = data_vs1_vmerge[47:40];

                    // Multiplication Source (Data Gate depending on comparison result)
                    data_vs1_vmerge_mul[63:56] = result_vcomp_i[7] ? data_vs2_vmerge[63:56] : 0;
                    data_vs1_vmerge_mul[55:48] = result_vcomp_i[6] ? data_vs2_vmerge[63:56] : 0;
                    data_vs1_vmerge_mul[47:40] = result_vcomp_i[5] ? data_vs2_vmerge[63:56] : 0;
                    data_vs1_vmerge_mul[39:32] = result_vcomp_i[4] ? data_vs2_vmerge[63:56] : 0;
                    data_vs1_vmerge_mul[31:24] = result_vcomp_i[3] ? data_vs2_vmerge[63:56] : 0;
                    data_vs1_vmerge_mul[23:16] = result_vcomp_i[2] ? data_vs2_vmerge[63:56] : 0;
                    data_vs1_vmerge_mul[15:08] = result_vcomp_i[1] ? data_vs2_vmerge[63:56] : 0;
                    data_vs1_vmerge_mul[07:00] = result_vcomp_i[0] ? data_vs2_vmerge[55:48] : 0;

                    data_vs2_vmerge_mul[63:56] = result_vcomp_i[7] ? data_vs2_vmerge[55:48] : 0;
                    data_vs2_vmerge_mul[55:48] = result_vcomp_i[6] ? data_vs2_vmerge[47:40] : 0;
                    data_vs2_vmerge_mul[47:40] = result_vcomp_i[5] ? data_vs2_vmerge[39:32] : 0;
                    data_vs2_vmerge_mul[39:32] = result_vcomp_i[4] ? data_vs2_vmerge[31:24] : 0;
                    data_vs2_vmerge_mul[31:24] = result_vcomp_i[3] ? data_vs2_vmerge[23:16] : 0;
                    data_vs2_vmerge_mul[23:16] = result_vcomp_i[2] ? data_vs2_vmerge[15:08] : 0;
                    data_vs2_vmerge_mul[15:08] = result_vcomp_i[1] ? data_vs2_vmerge[07:00] : 0;
                    data_vs2_vmerge_mul[07:00] = result_vcomp_i[0] ? data_vs2_vmerge[47:40] : 0;

                    rst_pending_vmcon = 1'b0;
                end
                SEW_16: begin
                    // Comparison Source
                    data_vs1_vmerge_comp[63:48] = data_vs1_vmerge[63:48];
                    data_vs1_vmerge_comp[47:32] = data_vs1_vmerge[63:48];
                    data_vs1_vmerge_comp[31:16] = data_vs1_vmerge[63:48];
                    data_vs1_vmerge_comp[15:00] = data_vs1_vmerge[47:32];
                    
                    data_vs2_vmerge_comp[63:48] = data_vs1_vmerge[47:32];
                    data_vs2_vmerge_comp[47:32] = data_vs1_vmerge[31:16];
                    data_vs2_vmerge_comp[31:16] = data_vs1_vmerge[15:00];
                    data_vs2_vmerge_comp[15:00] = data_vs1_vmerge[31:16];

                    // Multiplication Source (Data Gate depending on comparison result)
                    data_vs1_vmerge_mul[63:48] = result_vcomp_i[3] ? data_vs2_vmerge[63:48] : 0;
                    data_vs1_vmerge_mul[47:32] = result_vcomp_i[2] ? data_vs2_vmerge[63:48] : 0;
                    data_vs1_vmerge_mul[31:16] = result_vcomp_i[1] ? data_vs2_vmerge[63:48] : 0;
                    data_vs1_vmerge_mul[15:00] = result_vcomp_i[0] ? data_vs2_vmerge[47:32] : 0;
                    
                    data_vs2_vmerge_mul[63:48] = result_vcomp_i[3] ? data_vs2_vmerge[47:32] : 0;
                    data_vs2_vmerge_mul[47:32] = result_vcomp_i[2] ? data_vs2_vmerge[31:16] : 0;
                    data_vs2_vmerge_mul[31:16] = result_vcomp_i[1] ? data_vs2_vmerge[15:00] : 0;
                    data_vs2_vmerge_mul[15:00] = result_vcomp_i[0] ? data_vs2_vmerge[31:16] : 0;

                    rst_pending_vmcon = 1'b0;
                end
                SEW_32: begin
                    data_vs1_vmerge_comp = 0;
                    data_vs2_vmerge_comp = {64{1'b1}};

                    data_vs1_vmerge_mul = 0;
                    data_vs2_vmerge_mul = 0;

                    rst_pending_vmcon = 1'b0;
                end
                SEW_64: begin
                    data_vs1_vmerge_comp = 0;
                    data_vs2_vmerge_comp = {64{1'b1}};

                    data_vs1_vmerge_mul = 0;
                    data_vs2_vmerge_mul = 0;

                    rst_pending_vmcon = 1'b0;
                end
            endcase
        end

        1: begin
            case (instruction_i.instr.sew)
                SEW_8: begin
                    data_vs1_vmerge_comp[63:56] = data_vs1_vmerge[55:48];
                    data_vs1_vmerge_comp[55:48] = data_vs1_vmerge[55:48];
                    data_vs1_vmerge_comp[47:40] = data_vs1_vmerge[55:48];
                    data_vs1_vmerge_comp[39:32] = data_vs1_vmerge[55:48];
                    data_vs1_vmerge_comp[31:24] = data_vs1_vmerge[55:48];
                    data_vs1_vmerge_comp[23:16] = data_vs1_vmerge[47:40];
                    data_vs1_vmerge_comp[15:08] = data_vs1_vmerge[47:40];
                    data_vs1_vmerge_comp[07:00] = data_vs1_vmerge[47:40];

                    data_vs2_vmerge_comp[63:56] = data_vs1_vmerge[39:32];
                    data_vs2_vmerge_comp[55:48] = data_vs1_vmerge[31:24];
                    data_vs2_vmerge_comp[47:40] = data_vs1_vmerge[23:16];
                    data_vs2_vmerge_comp[39:32] = data_vs1_vmerge[15:08];
                    data_vs2_vmerge_comp[31:24] = data_vs1_vmerge[07:00];
                    data_vs2_vmerge_comp[23:16] = data_vs1_vmerge[39:32];
                    data_vs2_vmerge_comp[15:08] = data_vs1_vmerge[31:24];
                    data_vs2_vmerge_comp[07:00] = data_vs1_vmerge[23:16];

                    //
                    data_vs1_vmerge_mul[63:56] = result_vcomp_i[7] ? data_vs2_vmerge[55:48] : 0;
                    data_vs1_vmerge_mul[55:48] = result_vcomp_i[6] ? data_vs2_vmerge[55:48] : 0;
                    data_vs1_vmerge_mul[47:40] = result_vcomp_i[5] ? data_vs2_vmerge[55:48] : 0;
                    data_vs1_vmerge_mul[39:32] = result_vcomp_i[4] ? data_vs2_vmerge[55:48] : 0;
                    data_vs1_vmerge_mul[31:24] = result_vcomp_i[3] ? data_vs2_vmerge[55:48] : 0;
                    data_vs1_vmerge_mul[23:16] = result_vcomp_i[2] ? data_vs2_vmerge[47:40] : 0;
                    data_vs1_vmerge_mul[15:08] = result_vcomp_i[1] ? data_vs2_vmerge[47:40] : 0;
                    data_vs1_vmerge_mul[07:00] = result_vcomp_i[0] ? data_vs2_vmerge[47:40] : 0;

                    data_vs2_vmerge_mul[63:56] = result_vcomp_i[7] ? data_vs2_vmerge[39:32] : 0;
                    data_vs2_vmerge_mul[55:48] = result_vcomp_i[6] ? data_vs2_vmerge[31:24] : 0;
                    data_vs2_vmerge_mul[47:40] = result_vcomp_i[5] ? data_vs2_vmerge[23:16] : 0;
                    data_vs2_vmerge_mul[39:32] = result_vcomp_i[4] ? data_vs2_vmerge[15:08] : 0;
                    data_vs2_vmerge_mul[31:24] = result_vcomp_i[3] ? data_vs2_vmerge[07:00] : 0;
                    data_vs2_vmerge_mul[23:16] = result_vcomp_i[2] ? data_vs2_vmerge[39:32] : 0;
                    data_vs2_vmerge_mul[15:08] = result_vcomp_i[1] ? data_vs2_vmerge[31:24] : 0;
                    data_vs2_vmerge_mul[07:00] = result_vcomp_i[0] ? data_vs2_vmerge[23:16] : 0;

                    rst_pending_vmcon = 1'b0;
                end
                SEW_16: begin
                    data_vs1_vmerge_comp[63:48] = data_vs1_vmerge[47:32];
                    data_vs1_vmerge_comp[47:32] = data_vs1_vmerge[31:16];
                    data_vs1_vmerge_comp[31:16] = 0;
                    data_vs1_vmerge_comp[15:00] = 0;
                    
                    data_vs2_vmerge_comp[63:48] = data_vs1_vmerge[07:00];
                    data_vs2_vmerge_comp[47:32] = data_vs1_vmerge[07:00];
                    data_vs2_vmerge_comp[31:16] = 1;
                    data_vs2_vmerge_comp[15:00] = 1;

                    //

                    data_vs1_vmerge_mul[63:48] = result_vcomp_i[3] ? data_vs1_vmerge[47:32] : 0;
                    data_vs1_vmerge_mul[47:32] = result_vcomp_i[2] ? data_vs1_vmerge[31:16] : 0;
                    data_vs1_vmerge_mul[31:16] = 0;
                    data_vs1_vmerge_mul[15:00] = 0;
                    
                    data_vs2_vmerge_mul[63:48] = result_vcomp_i[3] ? data_vs2_vmerge[07:00] : 0;
                    data_vs2_vmerge_mul[47:32] = result_vcomp_i[2] ? data_vs2_vmerge[07:00] : 0;
                    data_vs2_vmerge_mul[31:16] = 0;
                    data_vs2_vmerge_mul[15:00] = 0;

                    rst_pending_vmcon = 1'b1;
                end
                SEW_32: begin
                    data_vs1_vmerge_comp = 0;
                    data_vs2_vmerge_comp = {64{1'b1}};

                    data_vs1_vmerge_mul = 0;
                    data_vs2_vmerge_mul = 0;

                    rst_pending_vmcon = 1'b0;
                end
                SEW_64: begin
                    data_vs1_vmerge_comp = 0;
                    data_vs2_vmerge_comp = {64{1'b1}};

                    data_vs1_vmerge_mul = 0;
                    data_vs2_vmerge_mul = 0;

                    rst_pending_vmcon = 1'b0;
                end
            endcase
        end

        2: begin
            case (instruction_i.instr.sew)
                SEW_8: begin
                    data_vs1_vmerge_comp[63:56] = data_vs1_vmerge[47:40];
                    data_vs1_vmerge_comp[55:48] = data_vs1_vmerge[47:40];
                    data_vs1_vmerge_comp[47:40] = data_vs1_vmerge[39:32];
                    data_vs1_vmerge_comp[39:32] = data_vs1_vmerge[39:32];
                    data_vs1_vmerge_comp[31:24] = data_vs1_vmerge[39:32];
                    data_vs1_vmerge_comp[23:16] = data_vs1_vmerge[39:32];
                    data_vs1_vmerge_comp[15:08] = data_vs1_vmerge[31:24];
                    data_vs1_vmerge_comp[07:00] = data_vs1_vmerge[31:24];

                    data_vs2_vmerge_comp[63:56] = data_vs1_vmerge[15:08];
                    data_vs2_vmerge_comp[55:48] = data_vs1_vmerge[07:00];
                    data_vs2_vmerge_comp[47:40] = data_vs1_vmerge[31:24];
                    data_vs2_vmerge_comp[39:32] = data_vs1_vmerge[23:16];
                    data_vs2_vmerge_comp[31:24] = data_vs1_vmerge[15:08];
                    data_vs2_vmerge_comp[23:16] = data_vs1_vmerge[07:00];
                    data_vs2_vmerge_comp[15:08] = data_vs1_vmerge[23:16];
                    data_vs2_vmerge_comp[07:00] = data_vs1_vmerge[15:08];

                    //
                    data_vs1_vmerge_mul[63:56] = result_vcomp_i[7] ? data_vs2_vmerge[47:40] : 0;
                    data_vs1_vmerge_mul[55:48] = result_vcomp_i[6] ? data_vs2_vmerge[47:40] : 0;
                    data_vs1_vmerge_mul[47:40] = result_vcomp_i[5] ? data_vs2_vmerge[39:32] : 0;
                    data_vs1_vmerge_mul[39:32] = result_vcomp_i[4] ? data_vs2_vmerge[39:32] : 0;
                    data_vs1_vmerge_mul[31:24] = result_vcomp_i[3] ? data_vs2_vmerge[39:32] : 0;
                    data_vs1_vmerge_mul[23:16] = result_vcomp_i[2] ? data_vs2_vmerge[39:32] : 0;
                    data_vs1_vmerge_mul[15:08] = result_vcomp_i[1] ? data_vs2_vmerge[31:24] : 0;
                    data_vs1_vmerge_mul[07:00] = result_vcomp_i[0] ? data_vs2_vmerge[31:24] : 0;

                    data_vs2_vmerge_mul[63:56] = result_vcomp_i[7] ? data_vs2_vmerge[15:08] : 0;
                    data_vs2_vmerge_mul[55:48] = result_vcomp_i[6] ? data_vs2_vmerge[07:00] : 0;
                    data_vs2_vmerge_mul[47:40] = result_vcomp_i[5] ? data_vs2_vmerge[31:24] : 0;
                    data_vs2_vmerge_mul[39:32] = result_vcomp_i[4] ? data_vs2_vmerge[23:16] : 0;
                    data_vs2_vmerge_mul[31:24] = result_vcomp_i[3] ? data_vs2_vmerge[15:08] : 0;
                    data_vs2_vmerge_mul[23:16] = result_vcomp_i[2] ? data_vs2_vmerge[07:00] : 0;
                    data_vs2_vmerge_mul[15:08] = result_vcomp_i[1] ? data_vs2_vmerge[23:16] : 0;
                    data_vs2_vmerge_mul[07:00] = result_vcomp_i[0] ? data_vs2_vmerge[15:08] : 0;

                    rst_pending_vmcon = 1'b0;
                end
                SEW_16: begin
                    data_vs1_vmerge_comp = 0;
                    data_vs2_vmerge_comp = {64{1'b1}};

                    data_vs1_vmerge_mul = 0;
                    data_vs2_vmerge_mul = 0;

                    rst_pending_vmcon = 1'b0;
                end
                SEW_32: begin
                    data_vs1_vmerge_comp = 0;
                    data_vs2_vmerge_comp = {64{1'b1}};

                    data_vs1_vmerge_mul = 0;
                    data_vs2_vmerge_mul = 0;

                    rst_pending_vmcon = 1'b0;
                end
                SEW_64: begin
                    data_vs1_vmerge_comp = 0;
                    data_vs2_vmerge_comp = {64{1'b1}};

                    data_vs1_vmerge_mul = 0;
                    data_vs2_vmerge_mul = 0;

                    rst_pending_vmcon = 1'b0;
                end
            endcase
        end

        3: begin
            case (instruction_i.instr.sew)
                SEW_8: begin
                    data_vs1_vmerge_comp[63:56] = data_vs1_vmerge[31:24];
                    data_vs1_vmerge_comp[55:48] = data_vs1_vmerge[23:16];
                    data_vs1_vmerge_comp[47:40] = data_vs1_vmerge[23:16];
                    data_vs1_vmerge_comp[39:32] = data_vs1_vmerge[15:08];
                    data_vs1_vmerge_comp[31:24] = 0;
                    data_vs1_vmerge_comp[23:16] = 0;
                    data_vs1_vmerge_comp[15:08] = 0;
                    data_vs1_vmerge_comp[07:00] = 0;

                    data_vs2_vmerge_comp[63:56] = data_vs1_vmerge[07:00];
                    data_vs2_vmerge_comp[55:48] = data_vs1_vmerge[15:08];
                    data_vs2_vmerge_comp[47:40] = data_vs1_vmerge[07:00];
                    data_vs2_vmerge_comp[39:32] = data_vs1_vmerge[07:00];
                    data_vs2_vmerge_comp[31:24] = 1;
                    data_vs2_vmerge_comp[23:16] = 1;
                    data_vs2_vmerge_comp[15:08] = 1;
                    data_vs2_vmerge_comp[07:00] = 1;

                    //
                    data_vs1_vmerge_mul[63:56] = result_vcomp_i[7] ? data_vs2_vmerge[31:24] : 0;
                    data_vs1_vmerge_mul[55:48] = result_vcomp_i[6] ? data_vs2_vmerge[23:16] : 0;
                    data_vs1_vmerge_mul[47:40] = result_vcomp_i[5] ? data_vs2_vmerge[23:16] : 0;
                    data_vs1_vmerge_mul[39:32] = result_vcomp_i[4] ? data_vs2_vmerge[15:08] : 0;
                    data_vs1_vmerge_mul[31:24] = 0;
                    data_vs1_vmerge_mul[23:16] = 0;
                    data_vs1_vmerge_mul[15:08] = 0;
                    data_vs1_vmerge_mul[07:00] = 0;

                    data_vs2_vmerge_mul[63:56] = result_vcomp_i[7] ? data_vs2_vmerge[07:00] : 0;
                    data_vs2_vmerge_mul[55:48] = result_vcomp_i[6] ? data_vs2_vmerge[15:08] : 0;
                    data_vs2_vmerge_mul[47:40] = result_vcomp_i[5] ? data_vs2_vmerge[07:00] : 0;
                    data_vs2_vmerge_mul[39:32] = result_vcomp_i[4] ? data_vs2_vmerge[07:00] : 0;
                    data_vs2_vmerge_mul[31:24] = 0;
                    data_vs2_vmerge_mul[23:16] = 0;
                    data_vs2_vmerge_mul[15:08] = 0;
                    data_vs2_vmerge_mul[07:00] = 0;

                    rst_pending_vmcon = 1'b1;
                end
                SEW_16: begin
                    data_vs1_vmerge_comp = 0;
                    data_vs2_vmerge_comp = {64{1'b1}};

                    data_vs1_vmerge_mul = 0;
                    data_vs2_vmerge_mul = 0;

                    rst_pending_vmcon = 1'b0;
                end
                SEW_32: begin
                    data_vs1_vmerge_comp = 0;
                    data_vs2_vmerge_comp = {64{1'b1}};

                    data_vs1_vmerge_mul = 0;
                    data_vs2_vmerge_mul = 0;

                    rst_pending_vmcon = 1'b0;
                end
                SEW_64: begin
                    data_vs1_vmerge_comp = 0;
                    data_vs2_vmerge_comp = {64{1'b1}};

                    data_vs1_vmerge_mul = 0;
                    data_vs2_vmerge_mul = 0;

                    rst_pending_vmcon = 1'b0;
                end
            endcase
        end
        default: begin
            data_vs1_vmerge_comp = 0;
            data_vs2_vmerge_comp = {64{1'b1}};

            data_vs1_vmerge_mul = 0;
            data_vs2_vmerge_mul = 0;

            rst_pending_vmcon = 1'b0;
        end
    endcase
end

always_ff@ (posedge clk_i, negedge rstn_i) begin
    if (~rstn_i) begin
        cnt_merge_stage <= 64'b0;
    end
    else begin
        if(pending_vmcon) begin
            cnt_merge_stage <= cnt_merge_stage+1;
        end
        else begin
            cnt_merge_stage <= 64'b0;
        end
    end
end

always_ff@ (posedge clk_i, negedge rstn_i) begin
    if (~rstn_i) begin
        data_vs1_vmerge <= 0;
        data_vs2_vmerge <= 0;
        pending_vmcon <= 1'b0;
        pending_vmcon_sh1 <= 1'b0;
    end
    else begin
        if(instruction_i.instr.instr_type == VMCON && instruction_i.instr.valid == 1'b1 && ~pending_vmcon) begin
            data_vs1_vmerge <= data_vs1_i;
            data_vs2_vmerge <= data_vs2_i;
            pending_vmcon <= 1'b1;
        end
        else begin
            data_vs1_vmerge <= data_vs1_vmerge;
            data_vs2_vmerge <= data_vs2_vmerge;
            if (rst_pending_vmcon == 1'b1) begin
                pending_vmcon <= 1'b0;
            end
            else begin
                pending_vmcon <= pending_vmcon;
            end
            pending_vmcon_sh1 <= pending_vmcon;
        end
    end
end

always_ff@ (posedge clk_i, negedge rstn_i) begin
    if (~rstn_i) begin
        result_vmcon_o <= 64'b0;
    end
    else begin
        if(pending_vmcon_sh1) begin
            result_vmcon_o <= result_vaddsub_i;
        end
        else begin
            result_vmcon_o <= 64'b0;
        end
    end
end

endmodule