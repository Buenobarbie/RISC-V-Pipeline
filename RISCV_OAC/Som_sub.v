/*  

    Somador e Subtrador:
    
    Realiza soma e subtração de dois números de N bits.
    Decide resultado da saída através do parâmetro SUB (subtração).
    Converte o parâmetro N2 para complemento de 2 para realizar a subtração. 

*/

module som_sub #(parameter N = 64) (
    input wire [N-1:0]  N1, 
    input wire [N-1:0]  N2, 
    input wire          SUB, 
    output wire [N:0]   RES
);

    wire [N:0] n2, res_sub, res_som;

    somador complemento((~(N2)), {{N-1{1'b0}}, 1'b1}, n2);
    somador sub(N1, n2[N-1:0], res_sub);
    somador som(N1, N2, res_som);

    assign RES = SUB ? res_sub : res_som;

endmodule