module polirv #(parameter i_addr_bits = 6, parameter d_addr_bits = 6)
               (input clk, input rst_n, output [i_addr_bits-1:0] i_mem_addr, input [31:0] i_mem_data, 
                output d_mem_we, output [d_addr_bits-1:0] d_mem_addr, inout [63:0] d_mem_data);

    wire [6:0] opcode;

    wire [2:0] func3,
               ula_cmds;

    wire       func7b5, 
               rf_we, 
               ula_mux, 
               pc_mux, 
               rf_mux, 
               zero;

    wire [31:0] instruction;

    assign opcode = instruction[6:0];
    assign func3 = instruction[14:12];
    assign func7b5 = instruction[30];

    uc uc (
        .clk        (clk        ), 
        .rst_n      (rst_n      ), 
        .opcode     (opcode     ),
        .func3      (func3      ), 
        .zero       (zero       ),
        .func7b5    (func7b5    ),
        .d_mem_we   (d_mem_we   ), 
        .rf_we      (rf_we      ), 
        .ula_cmd    (ula_cmds   ), //SUS
        .ula_src    (ula_mux    ),
        .pc_src     (pc_mux     ), //mudar o nome
        .rf_src     (rf_mux     )  //mudar o nome
);


    datapath fd (
        .clk        (clk        ), 
        .rst_n      (rst_n      ),
        .d_mem_we   (d_mem_we   ), 
        .rf_we      (rf_we      ), 
        .ula_src    (ula_mux    ), //SUS
        .pc_src     (pc_mux     ), 
        .rf_src     (rf_mux     ),
        .ula_cmd    (ula_cmds   ), //SUS
        .i_mem_data (i_mem_data ),

        .zero       (zero       ),
        .i_mem_addr (i_mem_addr ),
        .d_mem_addr (d_mem_addr ),

        .d_mem_data (d_mem_data ),
        .instruction (instruction)
    );

endmodule