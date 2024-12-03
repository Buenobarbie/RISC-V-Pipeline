module uc (input wire        clk,     
           input wire        rst_n,   
           input wire [6:0]  opcode,  
           input wire [2:0]  func3,   
           input wire        zero,    
           input wire        func7b5, 

           // Saídas
           output reg        d_mem_we,
           output reg        d_mem_re,
           output reg        rf_we,   
           output wire  [2:0] ula_cmd, 
           output reg        ula_src, 
           output reg        branch,  
           output reg        rf_src   
);

//////////////////////////////////////////////// ULA Operations //////////////////////////////////////////////////////   

    wire  RtypeSub;
    assign RtypeSub = func7b5 & opcode[5];  // TRUE for R-type subtract instruction

    assign ula_cmd = (ula_ops == 2'b00) ? 3'b000 :                          // add, addi
                     (ula_ops == 2'b01) ? 3'b001 :                          // sub, subi
                     (func3 ==  3'b000) ? ((RtypeSub) ? 3'b001 : 3'b000) :  // sub, add
                     (func3 ==  3'b010) ? 3'b101 :                          // slt
                     (func3 ==  3'b110) ? 3'b011 :                          // or
                     (func3 ==  3'b111) ? 3'b010 : 3'bxxx;                  // and

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////// UC Completa //////////////////////////////////////////////////////   

    // Estados
    reg [2:0] state, 
              next_state;

    // Sinais de Controle
    reg [1:0] ula_ops;

    // Parâmetros para os estados
    parameter RESET     = 3'b000, //0
              EXE_ADD   = 3'b001, //1
              EXE_LB    = 3'b010, //2
              EXE_SB    = 3'b011, //3
              EXE_BEQ   = 3'b100, //4
              STALL     = 3'b101; //5

    
    always @(posedge clk) begin 
        if (~rst_n) begin
            state <= RESET;     
        end
        else begin 
            // if (state == RESET) state <= STALL;
            // else begin
                case (opcode)
                    7'b0110011: state <= EXE_ADD; // R - Type
                    7'b0000011: state <= EXE_LB;  // I - Type
                    7'b0100011: state <= EXE_SB;  // S - Type
                    7'b1100011: state <= EXE_BEQ; // SB - Type
                    default:    state <= RESET;
                endcase
            // end
        end
    end

    always@ (state)
        begin
            case (state)
                RESET:
                    begin
                        d_mem_we <= 0;
                        d_mem_re <= 0;
                        rf_we <= 0;
                        branch <= 0;
                        ula_src <= 0;
                        rf_src <= 0;
                    end
                STALL:
                    begin
                        d_mem_we <= 0;
                        d_mem_re <= 0;
                        rf_we <= 0;
                        branch <= 0;
                        ula_src <= 0;
                        rf_src <= 0;
                    end
                EXE_ADD:
                    begin
                        ula_src     <= 0;
                        rf_src      <= 0;
                        rf_we       <= 1;
                        d_mem_we    <= 0;
                        d_mem_re    <= 0;
                        branch      <= 0;
                        ula_ops     <= 2'b10;
                        // next_state  <= DECODE;
                    end
                EXE_LB:
                    begin
                        ula_src     <= 1;
                        rf_src      <= 1;
                        rf_we       <= 1;
                        d_mem_we    <= 0;
                        d_mem_re    <= 1;
                        branch      <= 0;
                        ula_ops     <= 2'b00;
                        // next_state  <= DECODE;
                    end
                EXE_SB:
                    begin
                        ula_src     <= 1;
                        rf_src      <= 0;
                        rf_we       <= 0;
                        d_mem_we    <= 1;
                        d_mem_re    <= 0;
                        branch      <= 0;
                        ula_ops     <= 2'b00;
                        // next_state  <= DECODE;
                    end
                EXE_BEQ:
                    begin
                        ula_src     <= 0;
                        rf_src      <= 0;
                        rf_we       <= 0;
                        d_mem_we    <= 0;
                        d_mem_re    <= 0;
                        branch      <= 1;
                        ula_ops     <= 2'b01;
                        // next_state  <= DECODE;
                    end
            endcase
        end 

endmodule
