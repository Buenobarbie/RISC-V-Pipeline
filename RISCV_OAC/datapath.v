module datapath #(parameter i_addr_bits = 6, parameter d_addr_bits = 6) (
    input wire        clk, 
    input wire        rst_n,  
    input wire        d_mem_we, 
    input wire        rf_we,
    input wire        alu_src, 
    input wire        pc_src, 
    input wire        rf_src,
    input wire [3:0]  alu_cmd,
    input wire [31:0] i_mem_data,
    //saidas
    output wire [6:0]                opcode, 
    output wire [3:0]                alu_flags,  
    output wire [i_addr_bits-1:0]    i_mem_addr,  
    output wire [d_addr_bits-1:0]    d_mem_addr,

    inout [63:0] d_mem_data
);

    wire        flags, 
                add_mux, 
                branch;

    wire [2:0]  ULA_operation;
    wire [31:0] mem_out;

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
                add_out_2;

//////////////////////////////////////////////// Instruction fetch //////////////////////////////////////////////////////   

    PC pc (
        .clk    (CLK        ), 
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
        .d1 (add_out_2  ), 
        .S  (add_mux    ), 
        .Y  (add_out_mux)
    );

    assign i_mem_addr = pc_out;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////// Instruction decode ///////////////////////////////////////////////////   

    RegisterFile RF (
        .CLK        (CLK            ),
        .RESET      (~rst_n         ),
        .WE         (rf_we          ),
        .RD_ADDR1   (mem_out[19:15] ),
        .RD_ADDR2   (mem_out[24:20] ),
        .WR_ADDR    (mem_out[11:7]  ),
        .WR_DATA    (ram_out_mux    ),
        .RD_DATA1   (rf_out_A       ),
        .RD_DATA2   (rf_out_B       )
    );

    ImmGen imm_gen (
        .instr  (mem_out    ), 
        .imm_out(imme_out   )
    );

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
////////////////////////////////////////////////// Execution //////////////////////////////////////////////////////////   

    Add add2 (pc_out, imme_shift, add_out_2);

    mux_2x1 mux_ula (
        .d0 (rf_out_B   ), 
        .d1 (imme_out   ), 
        .S  (alu_src    ), 
        .Y  (ula_in     )
    );

    //MUITO SUS
    ULA ula (
        .operation  (ULA_operation  ), 
        .operand1   (ula_in         ), 
        .operand2   (rf_out_A       ), 
        .result     (ula_out        ), 
        .flag       (alu_flags      )
    );

    //SUS
    //assign feito para controlar o shift do imediato
    assign imme_shift = (mem_out[6:0] == 7'b0010111) ? imme_out << 12'b0 : 
                        (mem_out[6:0] == 7'b1101111) ? imme_out << 1'b0 : imme_out << 1'b1;

    assign d_mem_addr = ula_out;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////// Memory //////////////////////////////////////////////////////////   

    assign mem_out = i_mem_data;

    //assign feitos para garantir o funcionamento do inout

    assign d_mem_data = (d_mem_we) ? rf_out_B : 64'bz;
    assign ram_out = (~d_mem_we) ? d_mem_data : 64'bz;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////// Write-back ////////////////////////////////////////////////////////   

    mux_2x1 mux_ram (
        .d0 (ula_out    ), 
        .d1 (ram_out    ), 
        .S  (rf_src     ), 
        .Y  (ram_out_mux)
    );

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    assign sel = (mem_out[6:0] == 7'b1100011) ? 1'b1 : 1'b0;
    
    // Talvez, errado
    mux_2x1 #( .N(1) ) mux_mux (
        .d0 (pc_src ), 
        .d1 (flags  ), 
        .S  (sel    ), 
        .Y  (add_mux)
    );

    //assign feito para controlar quando vamos somar ou subtrair o imediato do PC
    assign branch = (mem_out[6:0] != 7'b1100011) ? 1'b0 : mem_out[31];

    //assigns feitos para usar os flags da ULA no condtionals (beq, bne, ...)
    //so usamos o beq na primeira entrega
    assign flags = (mem_out[6:0] != 7'b1100011) ? 1'b0 : 
                   (mem_out[14:12] == 3'b000) ? alu_flags[0] :
                   (mem_out[14:12] == 3'b001) ? ~alu_flags[0] :
                   (mem_out[14:12] == 3'b100) ? alu_flags[1] :
                   (mem_out[14:12] == 3'b101) ? ~alu_flags[1] :
                   (mem_out[14:12] == 3'b110) ? alu_flags[1] :
                   (mem_out[14:12] == 3'b111) ? ~alu_flags[1] : 1'b0;


    //Assigns feitos para controlar a operacao realizada na ULA
    //0: soma
    //1: subtracao
    //2: and
    assign ULA_operation = (mem_out[6:0] == 7'b1100011) ? 2'd1 :
                           (mem_out[6:0] != 7'b0110011) ? 2'd0 : 
                           (mem_out[31:25] == 7'b0100000) ? 2'd1 : 
                           (mem_out[14:12] == 3'b111) ? 2'd2 : 2'd0;

    assign opcode = mem_out[6:0];

    //Fazemos isso no datapath para que cada 4 ciclos de clock da UC ser 1 ciclo de clock do FD

    // Tá errado
    reg CLK = 0;
    integer i = 2;

    always @ (posedge clk) begin
        if (i == 3) begin
            CLK <= 1;
            i = 0;
        end
        else if (i == 1) begin
            CLK <= 0;
            i = i + 1;
        end
        else begin
            i = i + 1;
        end
    end

endmodule
