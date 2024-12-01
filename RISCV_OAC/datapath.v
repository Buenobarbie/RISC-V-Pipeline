module datapath #(parameter i_addr_bits = 6, parameter d_addr_bits = 6) (
    input wire        clk, 
    input wire        rst_n,  
    input wire        d_mem_we, 
    input wire        rf_we,
    input wire        ula_src, 
    input wire        pc_src, 
    input wire        rf_src,
    input wire [2:0]  ula_cmd,
    input wire [31:0] i_mem_data,
    //saidas
    output wire                      zero,
    output wire [i_addr_bits-1:0]    i_mem_addr,  
    output wire [d_addr_bits-1:0]    d_mem_addr,

    inout [63:0] d_mem_data
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
        .S  (pc_src     ), 
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
        .S  (ula_src    ), 
        .Y  (ula_in     )
    );

    ULA ula (
        .ula_src    (ula_cmd        ), 
        .operand1   (ula_in         ), 
        .operand2   (rf_out_A       ), 
        .result     (ula_out        ), 
        .zero       (zero           )
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
