/*

    Program Counter:

    Contador que navega entre as instruções a serem executadas.

*/

module PC #(parameter N = 64)(
    input wire          clk, 
    input wire          rst, 
    input wire  [N-1:0] pc_in, 
    output reg  [N-1:0] pc_out
);
    
    always @ (posedge clk) begin
        if(rst) begin
            pc_out <= {N{1'b0}};
        end
        else begin
            pc_out <= pc_in; 
        end
    end

endmodule