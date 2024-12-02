/*
    Program Counter:

    Contador que navega entre as instruções a serem executadas.

*/

module PC #(parameter N = 64)(
    input wire          clk, 
    input wire          rst, 
    input wire          enable, // Added enable signal
    input wire  [N-1:0] pc_in, 
    output reg  [N-1:0] pc_out
);
    
    always @ (posedge clk) begin
        if (rst) begin
            pc_out <= {N{1'b0}}; // Reset PC to 0
        end
        else if (enable) begin
            pc_out <= pc_in;     // Update PC only if enable is asserted
        end
    end

endmodule
