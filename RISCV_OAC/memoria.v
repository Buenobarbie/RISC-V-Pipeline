module memoria (input [5:0] i_mem_addr, input [5:0] d_mem_addr, input d_we, input d_re,
                output [31:0] i_mem_data, inout [63:0] d_mem_data);

    reg [31:0] instruction [63:0];
    reg [63:0] data [127:64];

    reg [31:0] i_out;
    reg [63:0] d_out;

    always@ (d_we) begin
        if(d_we) data[d_mem_addr + 64] <= d_mem_data;
    end

    initial begin
        instruction[0]  = 32'b000000000001_11111_000_00001_0000011;   // lw x1, 1(x31)  -- Carrega 50 em x1
        instruction[4]  = 32'b000000000010_11111_000_00010_0000011;   // lw x2, 2(x31)  -- Carrega 30 em x2
        instruction[8]  = 32'b000000000100_11111_000_00011_0000011;   // lw x3, 4(x31)  -- Carrega um valor grande em x3

        instruction[12]  = 32'b000000000100_11111_000_10000_0000011;   // lw x3, 4(x31)  -- Carrega um valor grande em x3
        instruction[16]  = 32'b000000000100_11111_000_10001_0000011;   // lw x3, 4(x31)  -- Carrega um valor grande em x3

        instruction[20] = 32'b0000000_00001_00010_000_00100_0110011;  // add x4, x1, x2 -- x4 = 50 + 30 = 80
        instruction[24] = 32'b0100000_00001_00010_000_00101_0110011;  // sub x5, x1, x2 -- x5 = 50 - 30 = 20

        instruction[28] = 32'b0000000_00001_00011_111_00110_0110011;  // and x6, x1, x3 -- Operação bitwise entre 20 e x3
        instruction[32] = 32'b0000000_00001_00011_110_00111_0110011;  // or  x7, x1, x3 -- Operação OR entre x1 (50) e x3

        instruction[36] = 32'b0000000_00100_00001_000_01000_1100011;  // beq x4, x1, jump -- Salta se x4 == x1 (falso, sem salto)

        instruction[40] = 32'b0000000_00101_00000_000_00000_0100011;  // sw x5, 0(x0)   -- Armazena x7 na memória
        instruction[44] = 32'b1111111_10000_10000_000_00000_1100011;  // beq sempre verdadeiro, loop infinito


        data[65] = 64'd50;
        data[66] = 64'd30;
        data[68] = 64'b1000000000000000000000000000000000000000000000000000000000000000;
    end

    assign i_mem_data = instruction[i_mem_addr];
    assign d_mem_data = (d_re) ? data[d_mem_addr + 64] : 64'bz;

endmodule