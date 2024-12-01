// Grupo 10 - Tássyla Lissa Lima, João Felipe Pereira Carvalho e Gabriel Arthur

/*

Para executar utilizamos um ambiente PS e executamos os seguintes comandos:

$ iverilog -o dsn datapath.v memoria.v processador.v testbench.v uc.v Add.v ImmGen.v Mux_2x1.v PC.v RegN.v RF.v Som_sub.v Somador.v ULA.v
$ vvp.exe dsn
$ gtkwave test_final.vcd 

*/

`timescale 1 ns/10 ps

module testbench();

    parameter clock_period = 10, verdadeiro = 1'b1, falso = 1'b0;

    // Inicializa registradores e fios necessários para a simulação

    reg clk = falso, reset = falso;

    wire [63:0] d_mem_data;
    wire [31:0] i_mem_data;
    wire [5:0] i_mem_addr, d_mem_addr;

    wire we;

    // Inicializa módulos a serem usados

    polirv RISC_V (
        .clk        (clk        ), 
        .rst_n      (reset      ), 
        .i_mem_addr (i_mem_addr ), 
        .i_mem_data (i_mem_data ), 
        .d_mem_we   (we         ),
        .d_mem_addr (d_mem_addr ), 
        .d_mem_data (d_mem_data )
    );
    
    memoria memoria_externa (
        .i_mem_addr (i_mem_addr ), 
        .d_mem_addr (d_mem_addr ), 
        .d_we       (we         ), 
        .i_mem_data (i_mem_data ), 
        .d_mem_data (d_mem_data )
    );

    // Simulação
 
    always #(clock_period/2) clk = ~clk;

    initial begin

        $dumpfile("teste_final.vcd");
        $dumpvars(0, testbench);

        reset = 0;

        #(3*clock_period);

        reset = 1;

        #(120*clock_period);

        $display("Teste | Valor: %d.", 1'b1);

        $finish;
    end

endmodule
