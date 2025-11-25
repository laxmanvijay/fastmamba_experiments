module top_wrapper (
    input  wire clk,
    input  wire rst,
    
    // Serial input interface
    input  wire load_en,          // pulse high to load one lane
    input  wire [15:0] dinA,      // 16-bit input for A
    input  wire [15:0] dinB,      // 16-bit input for B
    
    // Compute control
    input  wire compute_start,    // pulse to trigger computation
    
    // Serial output interface
    input  wire read_en,          // pulse high to read next lane
    output wire [16:0] dout,      // output from current lane
    output wire valid,            // high when dout is valid
    output wire done              // high when all lanes read out
);
    //------------------------------------------------------
    // PARAMETERS
    //------------------------------------------------------
    localparam NUM_LANES  = 240;
    localparam DATA_WIDTH = 16;
    localparam OUT_W      = DATA_WIDTH + 1;
    
    //------------------------------------------------------
    // INTERNAL STORAGE for inputs
    //------------------------------------------------------
    reg [NUM_LANES*DATA_WIDTH-1:0] A_store = 0;
    reg [NUM_LANES*DATA_WIDTH-1:0] B_store = 0;
    reg [7:0] write_index = 0;
    
    //------------------------------------------------------
    // OUTPUT STORAGE (capture parallel results)
    //------------------------------------------------------
    reg [NUM_LANES*OUT_W-1:0] P_store = 0;
    reg [7:0] read_index = 0;
    reg results_valid = 0;
    
    //------------------------------------------------------
    // LOAD LOGIC (Serial input: 1 lane per cycle)
    //------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            write_index <= 0;
        end else if (load_en) begin
            if (write_index < NUM_LANES) begin
                A_store[(write_index+1)*DATA_WIDTH-1 -: DATA_WIDTH] <= dinA;
                B_store[(write_index+1)*DATA_WIDTH-1 -: DATA_WIDTH] <= dinB;
                write_index <= write_index + 1;
            end
        end
    end
    
    //------------------------------------------------------
    // PMU INSTANCE (Parallel computation)
    //------------------------------------------------------
    wire [NUM_LANES*OUT_W-1:0] P_bus;
    
    pmu #(
        .NUM_LANES(NUM_LANES),
        .DATA_WIDTH(DATA_WIDTH)
    ) pmu_inst (
        .clk   (clk),
        .rst   (rst),
        .A_flat(A_store),
        .B_flat(B_store),
        .P_flat(P_bus)        // All 240 results computed in parallel
    );
    
    //------------------------------------------------------
    // CAPTURE parallel results when computation completes
    //------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            P_store <= 0;
            results_valid <= 0;
        end else if (compute_start) begin
            P_store <= P_bus;     // Capture all 240 results at once
            results_valid <= 1;
            read_index <= 0;
        end
    end
    
    //------------------------------------------------------
    // READOUT LOGIC (Serial output: 1 lane per cycle)
    //------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            read_index <= 0;
        end else if (read_en && results_valid) begin
            if (read_index < NUM_LANES - 1) begin
                read_index <= read_index + 1;
            end
        end
    end
    
    //------------------------------------------------------
    // OUTPUT ASSIGNMENT
    //------------------------------------------------------
    assign dout = P_store[(read_index+1)*OUT_W-1 -: OUT_W];
    assign valid = results_valid;
    assign done = (read_index == NUM_LANES - 1) && results_valid;
    
endmodule
