module ULA (
    input wire [63:0] operand1,
    input wire [63:0] operand2,
    input wire [2:0] ula_src,
    output reg [63:0] result,
    output wire zero
);
    wire [63:0] add_sub_result;
    wire [63:0] logic_result;
    wire [63:0] shift_result;
    wire slt_result;

    // Instancia os módulos
    adder_subtractor add_sub_inst (
        .a(operand1),
        .b(operand2),
        .sub(ula_src[0]),
        .result(add_sub_result)
    );

    logic_unit logic_inst (
        .a(operand1),
        .b(operand2),
        .op(ula_src[1:0]),
        .result(logic_result)
    );

    shifter shift_inst (
        .a(operand1),
        .shamt(operand2[5:0]),   // 6 bits para deslocamento até 63 posições
        .type(ula_src[1:0]),
        .result(shift_result)
    );

    slt_unit slt_inst (
        .a(operand1),
        .b(operand2),
        .result(slt_result)
    );

    // Multiplexador para selecionar o resultado final
    always @(*) begin
        case (ula_src)
            3'b000, 3'b001: result = add_sub_result;  // Soma ou subtração
            3'b010, 3'b011, 3'b100: result = logic_result; // AND, OR, XOR
            3'b110, 3'b111: result = shift_result; // Deslocamentos
            3'b101: result = {63'b0, slt_result};      // SLT (Set Less Than)
            default: result = 64'b0;                    // Default
        endcase
    end

    // Define a flag zero
    assign zero = (result == 64'd0) ? 1'b1 : 1'b0;

endmodule



module slt_unit (
    input wire [63:0] a,
    input wire [63:0] b,
    output wire result
);
    assign result = ($signed(a) < $signed(b)) ? 1'b1 : 1'b0;
endmodule


module shifter (
    input wire [63:0] a,
    input wire [5:0] shamt,      // 6 bits para suportar deslocamento de até 63 posições
    input wire [1:0] type,       // 01=SLL, 10=SRL, 11=SRA
    output wire [63:0] result
);
    assign result = (type == 2'b10) ? (a << shamt) :          // Deslocamento lógico à esquerda (SLL)
                    (type == 2'b11) ? (a >> shamt) : 64'b0;   // Deslocamento lógico à direita (SRL)
                     
endmodule



module logic_unit (
    input wire [63:0] a,
    input wire [63:0] b,
    input wire [1:0] op,         // 00=AND, 01=OR, 10=XOR
    output wire [63:0] result
);
    assign result = (op == 2'b10) ? (a & b) :
                    (op == 2'b11) ? (a | b) :
                    (op == 2'b00) ? (a ^ b) : 64'b0;
endmodule



module adder_subtractor (
    input wire [63:0] a,
    input wire [63:0] b,
    input wire sub,              // Define se é soma (0) ou subtração (1)
    output wire [63:0] result
);
    assign result = sub ? (a - b) : (a + b);
endmodule