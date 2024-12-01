/*
    Somador em Cascata:

    Somador que devolve resultado com 1 bit a mais que os operandos, o que
    possibilita realizar todas as somas possíveis com N bits sem overflow.

    É montado através da concatenação de somadores completos de 1 bit.

*/

module somador #(parameter N = 64)
                (input [N-1:0] N1, input [N-1:0] N2, output [N:0] RES);

    wire [N:0] soma;
    wire [N:0] cout;

    assign cout[0] = 1'b0;

    generate
        genvar ii;
        for (ii=0; ii<N; ii=ii+1) begin : s
            somador_completo i_custom(
            .A(N1[ii])
            ,.B(N2[ii])
            ,.Cin(cout[ii])
            ,.Soma(soma[ii])
            ,.Cout(cout[ii+1])
            );
        end
    endgenerate

    assign soma[N] = cout[N];

    assign RES = soma;

endmodule

/*

    Somador Completo:

    Utiliza meios somadores para montar um somador completo de 1 bit
    com carry in e carry out.

*/

module somador_completo (A, B, Cin, Soma, Cout);
 
    input  A, B, Cin;
    output Soma, Cout;
    wire c1, c2, s1; 
    
    meio_somador som1 (A, B, s1, c1);
    meio_somador som2 (Cin, s1, Soma, c2);
    assign Cout = c1 | c2;

endmodule

/*

    Meio Somador:

    Define a soma por meio de um XOR entre as entradas.
    Define o carry por meio de um AND entre as entradas.

*/

module meio_somador (
    input wire  A, 
    input wire  B, 
    output wire soma, 
    output wire carry
);
    
    assign soma = A ^ B;
    assign carry = A & B;

endmodule