module uc (input        clk,        // Check?
           input        rst_n,      // Check?
           input [6:0]  opcode,     // Check
           input [2:0]  func3,      // Check
           input        zero,       // Check
           input        func7b5,    // Check

           // Saídas
           output       d_mem_we,   // Check
           output       rf_we,      // Check
           output reg [2:0] ula_cmd,    // Check
           output       ula_src,    // Check
           output       pc_src,     // Check
           output       rf_src
);

//                   output logic [1:0] ResultSrc,
//                   output logic [1:0] ImmSrc,

    wire [1:0] ULA_ops;
    wire jump;
    reg [10:0] controls;

    assign ULA_ops = controls[2:1];
    assign jump = controls[0];

    // assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
    //         ResultSrc, Branch, ALUOp, Jump} = controls;

    always @(posedge clk or opcode) begin
        case(opcode)
            // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
            7'b0000011: controls <= 11'b1_00_1_0_01_0_00_0; // lw
            7'b0100011: controls <= 11'b0_01_1_1_00_0_00_0; // sw
            7'b0110011: controls <= 11'b1_xx_0_0_00_0_10_0; // R-type 
            7'b1100011: controls <= 11'b0_10_0_0_00_1_01_0; // beq
            7'b0010011: controls <= 11'b1_00_1_0_00_0_10_0; // I-type ALU
            7'b1101111: controls <= 11'b1_11_0_0_10_0_00_1; // jal
            default:    controls <= 11'bx_xx_x_x_xx_x_xx_x; // non-implemented instruction
        endcase
    end

    wire  RtypeSub;
    assign RtypeSub = func7b5 & opcode[5];  // TRUE for R-type subtract instruction

    always @(posedge clk or ULA_ops) begin
        case(ULA_ops)
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

    assign pc_src = add_mux & zero | jump;


  


    // Estados
    reg [3:0] state, next_state;
    reg aux; //SUS

    // Parâmetros para os estados
    parameter RESET = 3'd0, 
              FETCH = 3'd1, 
              DECODE = 3'd2, 
              add = 3'd3, 
              lb = 3'd4, 
              sb = 3'd5, 
              beq = 3'd6, 
              WB = 3'd7;

    reg ula_operation, ram_write_enable, rf_write_enable, add_mux, ula_mux, ram_mux;

    assign d_mem_we = ram_write_enable;
    assign rf_we = rf_write_enable;
    // assign pc_src = add_mux;
    assign ula_src = ula_mux;
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