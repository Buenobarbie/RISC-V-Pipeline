module load_hazard_correction (
    input [4:0] Rs1D, Rs2D, RdE; 
    input ResultSrcE0, PCSrcE;
    output StallF, StallD, FlushD, FlushE; 
);

    wire lwStall = ResultSrcE0 && ((Rs1D == RdE) || (Rs2D == RdE));

    StallF = lwStall;
    StallD = lwStall;

    FlushD = PCSrcE;
    FlushE = lwStall || PCSrcE;

endmodule