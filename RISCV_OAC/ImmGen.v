/*

    Immediator Generator:
    
    Recebe uma instrução, e, dependendendo do seu opcode, 
    organiza o imediato da instrução de forma correta.

*/

module ImmGen (
    input wire [31:0] instr,
    output reg [63:0] imm_out
);

    always @(*) begin
        case (instr[6:0])  // Baseado no opcode
            7'b0010011, 7'b0000011, 7'b1100111: // Formato I
                imm_out = {{52{instr[31]}}, instr[31:20]};

            7'b0100011: // Formato S
                imm_out = {{52{instr[31]}}, instr[31:25], instr[11:7]};

            7'b1100011: // Formato B
                imm_out = {{51{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

            7'b0110111, 7'b0010111: // Formato U
                imm_out = {{32{instr[31]}}, instr[31:12], 12'b0};

            7'b1101111: // Formato J
                imm_out = {{43{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

            default: imm_out = 64'b0; // Valor padrão
        endcase
    end
endmodule


module ImmGenAntigo(input [31:0] imm_in, output [63:0] imm_out);

assign imm_out = (imm_in[6:0] == 7'b0110011) ? 64'b0: 
                //  (imm_in[6:0] == 7'b0000011) ? {52'b0, imm_in[31:20]}:  Formato I
                //  (imm_in[6:0] == 7'b0010011) ? {52'b0, imm_in[31:20]}:  Formato I
                //  (imm_in[6:0] == 7'b1100111) ? {52'b0, imm_in[31:20]}:  Formato I
                //  (imm_in[6:0] == 7'b0100011) ? {52'b0, imm_in[31:25], imm_in[11:7]}:  
                //  (imm_in[6:0] == 7'b1100011) ? {52'b0, imm_in[7], imm_in[30:25], imm_in[11:8], 1'b0}: 
                //  (imm_in[6:0] == 7'b1101111) ? {43'b0, imm_in[31], imm_in[19:12], imm_in[20], imm_in[30:21], 1'b0}: 
                //  (imm_in[6:0] == 7'b0110111) ? {32'b0, imm_in[31:12], 12'b0} :
                 (imm_in[6:0] == 7'b0010111) ? {32'b0, imm_in[31:12], 12'b0} : 64'b0;

endmodule