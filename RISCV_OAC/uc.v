module uc (input clk, input rst_n, input [6:0] opcode, output d_mem_we, output rf_we, input  [3:0] alu_flags,
           output [3:0] alu_cmd, output alu_src, output pc_src, output rf_src);

    reg [3:0] state;
    reg [3:0] next_state; 
    reg aux;

    reg ula_operation, ram_write_enable, rf_write_enable, add_mux, ula_mux, ram_mux;

    parameter RESET = 3'd0, FETCH = 3'd1, DECODE = 3'd2, add = 3'd3, lb = 3'd4, sb = 3'd5, 
              beq = 3'd6, WB = 3'd7;

    assign d_mem_we = ram_write_enable;
    assign rf_we = rf_write_enable;
    assign pc_src = add_mux;
    assign alu_src = ula_mux;
    assign rf_src = ram_mux;

    
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
                        ram_write_enable <= 0;
                        rf_write_enable <= 0;
                        add_mux <= 0;
                        ula_mux <= 0;
                        ram_mux <= 0;
                        next_state <= FETCH;
                    end
                FETCH:
                    begin
                        next_state <= DECODE;
                        add_mux <= 0;
                        rf_write_enable <= 0;
                        ram_write_enable <= 0;
                        aux <= 0;
                    end
                DECODE:
                    begin
                        case (opcode)
                            7'b0110011: begin //R - Type
                                next_state <= add;
                            end
                            7'b0000011: begin//I - Type
                                next_state <= lb;
                            end
                            7'b0100011: begin//S - Type
                                next_state <= sb;
                            end
                            7'b1100011: begin//SB - Type
                                next_state <= beq;
                            end
                        endcase
                    end
                add:
                    begin
                        ula_mux = 0;
                        ram_mux = 0;
                        add_mux = 0;
                        ram_write_enable = 0;
                        next_state <= WB;
                        aux <= 1;
                    end
                lb:
                    begin
                        ula_mux = 1;
                        ram_mux = 1;
                        add_mux = 0;
                        ram_write_enable = 0;
                        next_state <= WB;
                        aux <= 1;
                    end
                sb:
                    begin
                        ula_mux = 1;
                        ram_mux = 0;
                        add_mux = 0;
                        ram_write_enable = 1;
                        next_state <= WB;
                    end
                beq:
                    begin
                        ula_mux = 0;
                        ram_mux = 1;
                        add_mux = 1;
                        ram_write_enable = 0;
                        next_state <= WB;
                    end
                WB:
                    begin
                        next_state <= FETCH;
                        if (aux) rf_write_enable = 1;
                    end
            endcase
        end 


endmodule