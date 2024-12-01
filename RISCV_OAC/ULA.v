
/*

    Unidade Lógica e Aritmética:

    Realiza operações de soma e subtração, além de indicar por meio das flags
    igualde entre os números, dígito mais significativo da operação feita e se
    houve overflow na operação realizada.

*/

module ULA(
    input wire [2:0]    operation, 
    input wire [63:0]   operand1, 
    input wire [63:0]   operand2, 
    output wire [63:0]  result, 
    output wire [3:0]   flag
);

    reg sub = 1'b1;
    reg som = 1'b0;

	wire [64:0] sum;
	wire [64:0] diff;

    assign flag[0] = (result == 64'b0) ? 1'b1 : 1'b0;
    assign flag[1] = result[63];
    assign flag[2] = sum[64];

    som_sub U1 (operand1, operand2, som, sum);
    som_sub U2 (operand1, operand2, sub, diff);

    assign result = (operation == 2'd1) ? diff[63:0] : 
                    (operation == 2'd0) ? sum[63:0] : operand1 & operand2;

endmodule
