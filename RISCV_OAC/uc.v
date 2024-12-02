module uc (input wire        clk,     
           input wire        rst_n,   
           input wire [6:0]  opcode,  
           input wire [2:0]  func3,   
           input wire        zero,    
           input wire        func7b5, 

           // Saídas
           output reg        d_mem_we,
           output reg        rf_we,   
           output reg  [2:0] ula_cmd, 
           output reg        ula_src, 
           output reg        branch,  
           output reg        rf_src   
);

//////////////////////////////////////////////// ULA Operations //////////////////////////////////////////////////////   

    wire  RtypeSub;
    assign RtypeSub = func7b5 & opcode[5];  // TRUE for R-type subtract instruction

    always @(posedge clk or ula_ops) begin
        case(ula_ops)
        2'b00:                ula_cmd <= 3'b000; // addition
        2'b01:                ula_cmd <= 3'b001; // subtraction
        default: case(func3) // R-type or I-type ALU
                    3'b000: if (RtypeSub) 
                                ula_cmd <= 3'b001; // sub
                            else          
                                ula_cmd <= 3'b000; // add, addi
                    3'b010:    ula_cmd <= 3'b101; // slt, slti
                    3'b110:    ula_cmd <= 3'b011; // or, ori
                    3'b111:    ula_cmd <= 3'b010; // and, andi
                    default:   ula_cmd <= 3'bxxx; // ???
                endcase
        endcase
    end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////// UC Completa //////////////////////////////////////////////////////   

    // Estados
    reg [3:0] state, 
              next_state;

    // Sinais de Controle
    reg [1:0] ula_ops;

    // Parâmetros para os estados
    parameter RESET     = 4'b0000, 
              FETCH     = 4'b0001, 
              DECODE    = 4'b0010, 
              EXE_ADD   = 4'b0011, 
              EXE_LB    = 4'b0100, 
              EXE_SB    = 4'b0101, 
              EXE_BEQ   = 4'b0110,  
              MEM       = 4'b0111,
              WB        = 4'b1000;
    
    always @(posedge clk) begin 
        if (~rst_n) begin
            state <= RESET;     
        end
        else begin 
            state <= next_state;
        end
    end

    always@ (posedge clk or state)
        begin
            case (state)
                RESET:
                    begin
                        d_mem_we <= 0;
                        rf_we <= 0;
                        branch <= 0;
                        ula_src <= 0;
                        rf_src <= 0;
                        next_state <= FETCH;
                    end
                FETCH:
                    begin
                        next_state <= DECODE;
                        branch <= 0;
                        rf_we <= 0;
                        d_mem_we <= 0;
                    end
                DECODE:
                    begin
                        case (opcode)
                            7'b0110011: begin //R - Type
                                next_state <= EXE_ADD;
                            end
                            7'b0000011: begin//I - Type
                                next_state <= EXE_LB;
                            end
                            7'b0100011: begin//S - Type
                                next_state <= EXE_SB;
                            end
                            7'b1100011: begin//SB - Type
                                next_state <= EXE_BEQ;
                            end
                        endcase
                    end
                EXE_ADD:
                    begin
                        ula_src <= 0;
                        rf_src <= 0;
                        branch <= 0;
                        rf_we <= 1;
                        ula_ops <= 2'b10;
                        next_state <= MEM;
                    end
                EXE_LB:
                    begin
                        ula_src <= 1;
                        rf_src <= 1;
                        branch <= 0;
                        rf_we <= 1;
                        ula_ops <= 2'b00;
                        next_state <= MEM;
                    end
                EXE_SB:
                    begin
                        ula_src <= 1;
                        rf_src <= 0;
                        branch <= 0;
                        d_mem_we <= 1;
                        ula_ops <= 2'b00;
                        next_state <= MEM;
                    end
                EXE_BEQ:
                    begin
                        ula_src <= 0;
                        rf_src <= 0;
                        branch <= 1;
                        ula_ops <= 2'b01;
                        next_state <= MEM;
                    end
                MEM:
                    begin
                        next_state <= WB;
                    end
                WB:
                    begin
                        next_state <= FETCH;
                    end
            endcase
        end 

endmodule
