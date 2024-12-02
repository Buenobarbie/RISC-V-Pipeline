module mux_3x1 #(parameter N = 64)(
    input wire [N-1:0]  d0, 
    input wire [N-1:0]  d1, 
    input wire [N-1:0]  d2, 
    input wire          S0, 
    input wire          S1, 
    output wire [N-1:0] Y
);

assign Y = (S1) ? d2 : (S0) ? d1 : d0;

endmodule