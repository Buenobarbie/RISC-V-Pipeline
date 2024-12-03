module datapath #(parameter i_addr_bits = 6, parameter d_addr_bits = 6) (
    input wire        clk, 
    input wire        rst_n,  
    input wire        d_mem_we, 
    input wire        rf_we,
    input wire        ula_src, 
    input wire        rf_src,
    input wire [2:0]  ula_cmd,
    input wire [31:0] i_mem_data,
    //saidas
    output wire                      zero,
    output wire [i_addr_bits-1:0]    i_mem_addr,  
    output wire [d_addr_bits-1:0]    d_mem_addr,

    inout [63:0] d_mem_data,
    input wire [31:0] instruction
);

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

    wire pc_src;

//////////////////////////////////////////////// Instruction fetch ////////////////////////////////////////////////////// 
    
    wire hazard_detection_src;

    // Atualizar o registrador PC com o endereço da próxima instrução
    PC pc (
        .clk    (CLK        ), 
        .rst    (~rst_n     ),
        .enable (hazard_detection_src), // Se houver stall, o PC não é atualizado (hazard_detection_src = 0) 
        .pc_in  (add_out_mux), 
        .pc_out (pc_out     )
    );
    
    // Soma 4 ao endereço da instrução
    Add add1 (
        .operand1   (pc_out     ), 
        .operand2   (64'd4      ), 
        .result     (add_out_1  )
    );

    // Mux para escolher o endereço da próxima instrução
    // Pc + 4 ou branch
    mux_2x1 mux_add (
        .d0 (add_out_1  ), 
        .d1 (add_out_2  ), 
        .S  (pc_src     ), 
        .Y  (add_out_mux)
    );

    // Endereço da próxima instrução
    // output do datapath para acessar a memória externa
    assign i_mem_addr = pc_out;

    // Registrador  intermediário IF ID 
    wire [95:0] reg_IF_ID;
    // pc_out: endereço da instrução  [95:32]
    // mem_out: instrução de 32 bits  [31:0]
    RegN registrador_IF_ID (
        .CLK        (CLK        ), 
        .RESET      (~rst_n     ), 
        .ENABLE     (hazard_detection_src),  // Se houver stall, reg_IF_ID não é atualizado (hazard_detection_src = 0)    
        .LOAD       ({pc_out, mem_out}    ), 
        .Q          (reg_IF_ID    )
    );



//////////////////////////////////////////////// Instruction decode ///////////////////////////////////////////////////   

    assign instruction = reg_IF_ID[31:0];

    harzard_detection_unit hazard_detection_unit (
    .ID_EX_MemRead     (~reg_ID_EX[277]),  // MemRead é o contrário de d_mem_we
    .ID_EX_RegisterRd  (reg_ID_EX[132:128] ), 
    .IF_ID_RegisterRs1  (reg_IF_ID[19:15] ), 
    .IF_ID_RegisterRs2  (reg_IF_ID[24:20] ), 
    .hazard_detection_src (hazard_detection_src)
);

    RegisterFile RF (
        .CLK        (CLK            ),
        .RESET      (~rst_n         ),
        .WE         (rf_we          ),
        .RD_ADDR1   (reg_IF_ID[19:15] ),
        .RD_ADDR2   (reg_IF_ID[24:20] ),
        .WR_ADDR    (reg_MEM_WB[11:7] ),
        .WR_DATA    (ram_out_mux    ),
        .RD_DATA1   (rf_out_A       ),
        .RD_DATA2   (rf_out_B       )
    );

    ImmGen imm_gen (
        .instr  (reg_IF_ID[31:0]    ), 
        .imm_out(imme_out   )
    );

    wire [6:0] control_signals;
    mux_2x1  #(.N(7))
    mux_stall(
        .d0 (7'b0  ), // Se stall (harzard_detection_unit = 0), os sinais de controle devem ser todos 0
        .d1 ({d_mem_we, ula_cmd, ula_src, branch, rf_src}  ), 
        .S  (hazard_detection_src), 
        .Y  (control_signals          )
    );

    wire [277:0] reg_ID_EX;
    // [277] d_mem_we: controla a escrita na memória de dados
    // [276:274]ula_cmd: comando da ula
    // [273] ula_src: origem da entrada da ula
    // [272] branch: controla o branch
    // [271] rf_src: origem do dado que será escrito no registrador
    // [270:207] rf_out_A: dado do registrador 1
    // [206:143] rf_out_B: dado do registrador 2
    // [142:138] regA_addr reg_IF_ID[19:15] : endereço do registrador 1
    // [137:133] regB_addr reg_IF_ID[24:20]: endereço do registrador 2
    // [132:128]reg_IF_ID[11:7] : endereço do registrador de destino
    // [127:64] registrador_IF_ID[pc_out]: endereço da instrução vindo do registrador anterior
    // [63:0] imme_out: imediato

    RegN registrador_ID_EX (
        .CLK        (CLK        ), 
        .RESET      (~rst_n     ), 
        .ENABLE     (1'b1      ), 
        .LOAD       ({control_signals, rf_out_A, rf_out_B, reg_IF_ID[19:15], reg_IF_ID[24:20], reg_IF_ID[11:7], reg_IF_ID[95:32], imme_out} ), 
        .Q          (reg_ID_EX    )
    );    

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
////////////////////////////////////////////////// Execution //////////////////////////////////////////////////////////   
    
    wire [1:0] forwardA, forwardB;
    forwarding_unit forwarding_unit (
        .EX_MEM_RegWrite    (reg_EX_MEM[] ), 
        .EX_MEM_RegisterRd   (reg_EX_MEM[] ), 
        .ID_EX_RegisterRs1   (reg_ID_EX[] ), 
        .ID_EX_RegisterRs2   (reg_ID_EX[] ), 
        .MEM_WB_RegWrite    (reg_MEM_WB[] ), 
        .MEM_WB_RegisterRd   (reg_MEM_WB[] ), 
        .ForwardA           (forwardA    ), 
        .ForwardB           (forwardB    )
    );
    
    //              pc_out 
    Add add2 (reg_ID_EX[127:64], imme_shift, add_out_2);

    wire [63:0] ula_operand1, ula_operand2;

    mux_3x1 mux_ula_op1 (
        .d0 (reg_ID_EX[270:207]  ), // rf_out_A: dado do registrador 1
        .d1 (ram_out_mux  ), 
        .d2 (  reg_EX_MEM[132:69]  ), 
        .S0  (forwardA[0]    ), 
        .S1  (forwardA[1]    ),
        .Y  (ula_operand1    )
    );

    mux_3x1 mux_ula_op2 (
        .d0 (reg_ID_EX[206:143]  ), // rf_out_B: dado do registrador 2
        .d1 (reg_EX_MEM[132:69]   ),
        .d2 (ram_out_mux    ), // dado da memória de dados
        .S0  (forwardB[0]    ), 
        .S1  (forwardB[1]    ),
        .Y  (ula_operand2     )
    );


    ULA ula (
        .ula_src    (reg_ID_EX[276:274]       ), 
        .operand1   (ula_operand1    ), 
        .operand2   (ula_operand2     ), 
        .result     (ula_out        ), 
        .zero       (zero           )
    );

    //                  imme_out
    assign imme_shift = reg_ID_EX[63:0] << 1'b1;


    assign d_mem_addr = ula_out;

    wire [4:0] rd_addr;
    assign rd_addr = reg_ID_EX[132:128];

    wire [200:0] reg_EX_MEM;
    // [200] d_mem_we reg_ID_EX[277]: controla a escrita na memória de dados
    // [199] branch reg_ID_EX[272]: controla o branch
    // [198] rf_src reg_ID_EX[271]: origem do dado que será escrito no registrador
    // [197:134] add_out_2: resultado da soma do imediato com o pc
    // [133] zero: flag de zero
    // [132:69] ula_out: resultado da operação da ula
    // [68:5] reg_ID_EX[206:143]: dado do registrador 2
    // [4:0]  Rd_addr endereco do registrador de destino


    RegN registrador_EX_MEM (
        .CLK        (CLK        ), 
        .RESET      (~rst_n     ), 
        .ENABLE     (1'b1       ), 
        .LOAD       ({reg_ID_EX[277], reg_ID_EX[272], reg_ID_EX[271], add_out_2, zero, ula_out, reg_ID_EX[206:143], rd_addr}    ), 
        .Q          (reg_EX_MEM    )
    );



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////// Memory //////////////////////////////////////////////////////////   

    assign mem_out = i_mem_data;

    //assign feitos para garantir o funcionamento do inout
                        //d_mem_we           rf_out_B
    assign d_mem_data = (reg_EX_MEM[200]) ? reg_EX_MEM[197:134] : 64'bz;
    assign ram_out = (~reg_EX_MEM[200]) ? d_mem_data : 64'bz;

    wire [133:0] reg_MEM_WB;
    // [133] rf_we: controla a escrita no registrador
    // [132:128] rd_addr: endereço do registrador de destino
    // [127:64] ram_out: dado da memória de dados
    // [63:0] ula_out: resultado da operação da ula

    RegN registrador_MEM_WB (
        .CLK        (CLK        ), 
        .RESET      (~rst_n     ), 
        .ENABLE     (1'b1      ), 
        .LOAD       ({reg_EX_MEM[198], reg_EX_MEM[4:0], ram_out, reg_EX_MEM[132:69]}    ), 
        .Q          (reg_MEM_WB    )
    );

    // BRANCH
    assign pc_src = reg_EX_MEM[133] && reg_EX_MEM[199];

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////// Write-back ////////////////////////////////////////////////////////   

    mux_2x1 mux_ram (
        .d0 (reg_MEM_WB[63:0]  ), // ula_out: resultado da operação da ula
        .d1 (reg_MEM_WB[127:64]  ),  // dado da memória de dados (ram_out   )
        .S  (reg_MEM_WB[133]     ),  // rf_src: controla qual dado será escrito no registrador
        .Y  (ram_out_mux)
    );

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //Fazemos isso no datapath para que cada 4 ciclos de clock da UC ser 1 ciclo de clock do FD

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
