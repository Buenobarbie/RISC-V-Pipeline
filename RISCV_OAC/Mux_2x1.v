module mux_2x1 #(parameter N = 64)(
    input wire [N-1:0]  d0, 
    input wire [N-1:0]  d1, 
    input wire          S, 
    output wire [N-1:0] Y
);

assign Y = (S) ? d1:d0;

endmodule