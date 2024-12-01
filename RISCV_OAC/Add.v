/*

    Somador que devolve resultado com a mesma quantidade de bits que os operandos.

*/

module Add #(parameter N = 64) (
    input wire [N-1:0]  operand1, 
    input wire [N-1:0]  operand2, 
    output wire [N-1:0] result
);

	wire [N:0] sum;

    somador somador (operand1, operand2, sum);

    assign result = sum[N-1:0];

endmodule