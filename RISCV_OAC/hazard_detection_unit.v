module hazard_detection_unit (
    input wire       ID_EX_MemRead,
    input wire [4:0] ID_EX_RegisterRd,
    input wire [4:0] IF_ID_RegisterRs1,
    input wire [4:0] IF_ID_RegisterRs2,
    output reg hazard_detection_src;
);

    reg stall;
    always @(*) begin
        stall = 1'b0;

        // Data Hazard
        if (ID_EX_MemRead && (ID_EX_RegisterRd == IF_ID_RegisterRs1 || ID_EX_RegisterRd == IF_ID_RegisterRs2)) begin
            stall = 1'b1;
        end
    end

    assign hazard_detection_src = ~stall;

endmodule