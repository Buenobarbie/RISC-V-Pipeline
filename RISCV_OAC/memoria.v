module memoria (input [5:0] i_mem_addr, input [5:0] d_mem_addr, input d_we, output [31:0] i_mem_data, 
                inout [63:0] d_mem_data);

    reg [31:0] instruction [63:0];
    reg [63:0] data [127:64];

    reg [31:0] i_out;
    reg [63:0] d_out;

    always@ (d_we) begin
        if(d_we) data[d_mem_addr + 64] <= d_mem_data;
    end

    initial begin
        instruction[0] = 32'b0;
        instruction[4] = 32'b000000000001_11111_000_00001_0000011;  // LOADa:  Formato I; x1 <= 50
        instruction[8] = 32'b000000000010_11111_000_00010_0000011;  // LOADb:  Formato I; x2 <= 30
        instruction[12] = 32'b000000000100_11111_000_00011_0000011;  // LOADc:  Formato I; x3 <= LSB(1)
        instruction[16] = 32'b0000000_00010_00001_000_10100_1100011;  // BEQ:   Formato Sb; if(x1 == x2) jump to instruction[16+40]

            instruction[20] = 32'b0100000_00010_00001_000_00100_0110011;  // SUB:  Formato R; x4 <= x2 - x1
            instruction[24] = 32'b0000000_00100_00011_111_00101_0110011;  // AND:  Formato R; x5 <= x3 & x4
            instruction[28] = 32'b0000000_00011_00101_000_01000_1100011;  // BEQ:  Formato Sb; if (x5 < 0) jump to instruction[28+16]
                instruction[44] = 32'b0100000_00001_00010_000_00111_0110011;  // SUB:  Formato R; x7 <= x1 - x2
                instruction[48] = 32'b0000000_00000_00111_000_00001_0110011;  // ADD:  Formato R; x1 <= x7 + x0
                instruction[52] = 32'b1111111_10000_10000_000_01111_1100011;  // BEQ:  Formato Sb; if (true) jump to instruction[52-36]

            instruction[32] = 32'b0100000_00010_00001_000_00111_0110011;  // SUB:  Formato R; x7 <= x2 - x1
            instruction[36] = 32'b0000000_00000_00111_000_00010_0110011;  // ADD:  Formato R; x2 <= x7 + x0
            instruction[40] = 32'b1111111_10000_10000_000_01001_1110011;  // BEQ:  Formato Sb; if (true) jump to instruction[40-24]

        instruction[56] = 32'b0000000_00001_00000_000_00011_0100011; // STORE:  Formato S; MEM <= x1
        instruction[60] = 32'b0000000_00000_00000_000_00000_1100011;   // BEQ:  Formato Sb; if (true) jump to instruction[60]

        data[65] = 64'd50;
        data[66] = 64'd30;
        data[68] = 64'b1000000000000000000000000000000000000000000000000000000000000000;
    end

    assign i_mem_data = instruction[i_mem_addr];
    assign d_mem_data = (!d_we) ? data[d_mem_addr + 64] : 64'bz;

endmodule