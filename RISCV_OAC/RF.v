module RegisterFile (
    input wire          CLK,                 // Clock
    input wire          RESET,               // Reset global
    input wire          WE,                  // Write Enable
    input wire [4:0]    RD_ADDR1,            // Endereço para leitura 1
    input wire [4:0]    RD_ADDR2,            // Endereço para leitura 2
    input wire [4:0]    WR_ADDR,             // Endereço para escrita
    input wire [63:0]   WR_DATA,             // Dados para escrita
    output wire [63:0]  RD_DATA1,            // Dados lidos (porta 1)
    output wire [63:0]  RD_DATA2             // Dados lidos (porta 2)
);

    // Sinais de saída dos registradores
    wire [63:0] regs_out [31:0];

    // Geração de instâncias dos 32 registradores
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : reg_file
            regN #(.N(64)) reg_instance (
                .CLK(CLK),
                .RESET(RESET),                // Reset global
                .ENABLE((WE && WR_ADDR == i && i != 0)), // Ativa escrita somente no registrador correto
                .LOAD(WR_DATA),
                .Q(regs_out[i])
            );
        end
    endgenerate

    // Leitura assíncrona
    assign RD_DATA1 = (RD_ADDR1 != 0) ? regs_out[RD_ADDR1] : 64'b0;
    assign RD_DATA2 = (RD_ADDR2 != 0) ? regs_out[RD_ADDR2] : 64'b0;

endmodule
