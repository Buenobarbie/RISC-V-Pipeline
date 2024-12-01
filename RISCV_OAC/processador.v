module polirv #(parameter i_addr_bits = 6, parameter d_addr_bits = 6)
               (input clk, input rst_n, output [i_addr_bits-1:0] i_mem_addr, input [31:0] i_mem_data, 
                output d_mem_we, output [d_addr_bits-1:0] d_mem_addr, inout [63:0] d_mem_data);

    wire [6:0] opcode;
    wire rf_we, ula_mux, pc_mux, rf_mux;
    wire [3:0] ula_flags, ula_cmds;

    uc uc (clk, rst_n, opcode, d_mem_we, rf_we, ula_flags, ula_cmds, ula_mux, pc_mux, rf_mux);

    datapath fd (
        .clk        (clk        ), 
        .rst_n      (rst_n      ),
        .d_mem_we   (d_mem_we   ), 
        .rf_we      (rf_we      ), 
        .alu_src    (ula_mux    ), 
        .pc_src     (pc_mux     ), 
        .rf_src     (rf_mux     ),
        .alu_cmd    (ula_cmds   ),
        .i_mem_data (i_mem_data ),

        .opcode     (opcode     ),
        .alu_flags  (ula_flags  ),
        .i_mem_addr (i_mem_addr ),
        .d_mem_addr (d_mem_addr ),

        .d_mem_data (d_mem_data )
    );

endmodule