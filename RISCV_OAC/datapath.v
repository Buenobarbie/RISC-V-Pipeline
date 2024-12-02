module datapath #(parameter i_addr_bits = 6, parameter d_addr_bits = 6) (
    input wire        clk, 
    input wire        rst_n,  
    input wire        d_mem_we, 
    input wire        rf_we,
    input wire        ula_src, 
    input wire        branch, 
    input wire        rf_src,
    input wire [2:0]  ula_cmd,
    input wire [31:0] i_mem_data,
    //saidas
    output wire                      zero,
    output wire [i_addr_bits-1:0]    i_mem_addr,  
    output wire [d_addr_bits-1:0]    d_mem_addr,

    inout [63:0] d_mem_data
);
    wire zero_reg,
         rf_we2, 
         rf_src2, 
         branch2, 
         d_mem_we2, 
         ula_src2,
         rf_we3, 
         rf_src3, 
         branch3, 
         d_mem_we3,
         rf_we4,
         rf_src4;

    wire [2:0] ula_cmd2;

    wire [31:0] mem_out,
                instr,
                instr_2,
                instr_3,
                instr_4;;

    wire [63:0] pc_out, 
                add_out_1, 
                imme_out, 
                rf_out_A, 
                rf_out_B,
                ula_in, 
                ula_out, 
                ram_out, 
                add_out_mux, 
                ram_out_mux, 
                imme_shift,
                add_out_2,
                pc_reg_1,
                pc_reg_2,
                rf_reg_A,
                rf_reg_B,
                imme_reg,
                add_reg_2,
                ula_reg,
                rf_reg_B_2,
                ram_reg,
                ula_reg_2;

//////////////////////////////////////////////// Instruction fetch //////////////////////////////////////////////////////   

    PC pc (
        .clk    (clk        ), 
        .rst    (~rst_n     ), 
        .pc_in  (add_out_mux), 
        .pc_out (pc_out     )
    );
    
    Add add1 (
        .operand1   (pc_out     ), 
        .operand2   (64'd4      ), 
        .result     (add_out_1  )
    );

    mux_2x1 mux_add (
        .d0 (add_out_1  ), 
        .d1 (add_reg_2  ), 
        .S  (pc_src     ), 
        .Y  (add_out_mux)
    );

    assign i_mem_addr = pc_out;
    assign mem_out = i_mem_data;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    regN #( .N(96) ) IF_ID (
        .CLK    (clk                ),
        .RESET  (~rst_n             ),
        .ENABLE (1'b1               ),
        .LOAD   ({pc_out, mem_out}  ),
        .Q      ({pc_reg_1, instr}  )
    );

//////////////////////////////////////////////// Instruction decode ///////////////////////////////////////////////////   

    RegisterFile RF (
        .CLK        (clk            ),
        .RESET      (~rst_n         ),
        .WE         (rf_we4         ),
        .RD_ADDR1   (instr[19:15]   ),
        .RD_ADDR2   (instr[24:20]   ),
        .WR_ADDR    (instr_4[11:7]  ),
        .WR_DATA    (ram_out_mux    ),
        .RD_DATA1   (rf_out_A       ),
        .RD_DATA2   (rf_out_B       )
    );

    ImmGen imm_gen (
        .instr  (instr    ), 
        .imm_out(imme_out )
    );

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    regN #( .N(296) ) ID_EX (
        .CLK    (clk                                                       ),
        .RESET  (~rst_n                                                    ),
        .ENABLE (1'b1                                                      ),
        .LOAD   ({pc_reg_1, rf_out_A, rf_out_B, imme_out, instr, 
                  rf_we, rf_src, branch, d_mem_we, ula_src, ula_cmd}       ),
        .Q      ({pc_reg_2, rf_reg_A, rf_reg_B, imme_reg, instr_2, 
                  rf_we2, rf_src2, branch2, d_mem_we2, ula_src2, ula_cmd2} )
    );  

////////////////////////////////////////////////// Execution //////////////////////////////////////////////////////////   

    Add add2 (pc_reg_2, imme_shift, add_out_2);

    mux_2x1 mux_ula (
        .d0 (rf_reg_B   ), 
        .d1 (imme_reg   ), 
        .S  (ula_src2   ), 
        .Y  (ula_in     )
    );

    ULA ula (
        .ula_src    (ula_cmd2       ), 
        .operand1   (ula_in         ), 
        .operand2   (rf_reg_A       ), 
        .result     (ula_out        ), 
        .zero       (zero           )
    );

    //assign feito para controlar o shift do imediato
    assign imme_shift = imme_out << 1'b1;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    regN #( .N(229) ) EX_MEM (
        .CLK    (clk                                                 ),
        .RESET  (~rst_n                                              ),
        .ENABLE (1'b1                                                ),
        .LOAD   ({add_out_2, zero, ula_out, rf_reg_B, instr_2, rf_we2, rf_src2, branch2, d_mem_we2}),
        .Q      ({add_reg_2, zero_reg, ula_reg, rf_reg_B_2, instr_3, rf_we3, rf_src3, branch3, d_mem_we3} )
    );

///////////////////////////////////////////////////// Memory //////////////////////////////////////////////////////////   

    //assign feitos para garantir o funcionamento do inout

    assign d_mem_data = (d_mem_we3) ? rf_reg_B_2 : 64'bz;
    assign ram_out = (~d_mem_we3) ? d_mem_data : 64'bz;

    assign d_mem_addr = ula_reg;

    assign pc_src = zero_reg & branch3;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    regN #( .N(162) ) MEM_WB (
        .CLK    (clk                                            ),
        .RESET  (~rst_n                                         ),
        .ENABLE (1'b1                                           ),
        .LOAD   ({ram_out, ula_reg, instr_3, rf_we3, rf_src3}   ),
        .Q      ({ram_reg, ula_reg_2, instr_4, rf_we4, rf_src4} )
    );

/////////////////////////////////////////////////// Write-back ////////////////////////////////////////////////////////   

    mux_2x1 mux_ram (
        .d0 (ula_reg_2  ), 
        .d1 (ram_reg    ), 
        .S  (rf_src4    ), 
        .Y  (ram_out_mux)
    );

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //Fazemos isso no datapath para que cada 4 ciclos de clock da UC ser 1 ciclo de clock do FD

    // reg CLK = 0;
    // integer i = 4;

    // always @ (posedge clk) begin
    //     if (i == 4) begin
    //         CLK <= 1;
    //         i = 0;
    //     end
    //     else if (i == 1) begin
    //         CLK <= 0;
    //         i = i + 1;
    //     end
    //     else begin
    //         i = i + 1;
    //     end
    // end

endmodule
