module polirv #(parameter i_addr_bits = 6, parameter d_addr_bits = 6)
               (input clk, input rst_n, output [i_addr_bits-1:0] i_mem_addr, input [31:0] i_mem_data, 
                output d_mem_we, output d_mem_re, output [d_addr_bits-1:0] d_mem_addr, inout [63:0] d_mem_data);

    wire [6:0] opcode;

    wire [2:0] func3,
               ula_cmds;

    wire       func7b5, 
               rf_we, 
               ula_mux, 
               branch, 
               rf_mux, 
               zero,
               d_mem_we_fd,
               d_mem_re_fd;

    assign opcode = i_mem_data[6:0];
    assign func3 = i_mem_data[14:12];
    assign func7b5 = i_mem_data[30];

    uc uc (
        .clk        (clk        ), 
        .rst_n      (rst_n      ), 
        .opcode     (opcode     ),
        .func3      (func3      ), 
        .zero       (zero       ),
        .func7b5    (func7b5    ),
        .d_mem_we   (d_mem_we_fd),
        .d_mem_re   (d_mem_re_fd),
        .rf_we      (rf_we      ), 
        .ula_cmd    (ula_cmds   ),
        .ula_src    (ula_mux    ),
        .branch     (branch     ),
        .rf_src     (rf_mux     ) 
);


    datapath fd (
        .clk        (clk        ), 
        .rst_n      (rst_n      ),
        .d_mem_we_fd(d_mem_we_fd),
        .d_mem_re_fd(d_mem_re_fd),
        .rf_we      (rf_we      ), 
        .ula_src    (ula_mux    ),
        .branch     (branch     ), 
        .rf_src     (rf_mux     ),
        .ula_cmd    (ula_cmds   ),
        .i_mem_data (i_mem_data ),

        .zero       (zero       ),
        .d_mem_we   (d_mem_we   ),
        .d_mem_re   (d_mem_re   ),
        .i_mem_addr (i_mem_addr ),
        .d_mem_addr (d_mem_addr ),

        .d_mem_data (d_mem_data )
    );

endmodule