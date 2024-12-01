/*

    Registrador Parametrizável:

    Armazena uma informação quando desabilitado e escreve uma 
    informação passada como parâmetro quando habilitado.

*/

module regN #(parameter N = 64) (
    input wire          CLK,
    input wire          RESET,
    input wire          ENABLE,
    input wire [N-1:0]  LOAD,
    output reg [N-1:0]  Q
);
    always @(posedge CLK) begin
        if (RESET)
            Q <= {N{1'b0}}; // Reseta o registrador para 0
        else if (ENABLE)
            Q <= LOAD;
    end
endmodule

