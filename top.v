//==========================================================
// TOP LEVEL WRAPPER for PMU
// Safe for FPGA implementation
// Exposes only minimal I/O pins
//==========================================================

module top_wrapper (
    input  wire clk,
    input  wire rst,

    // Example small external interface
    input  wire load_en,          // load A and B registers
    input  wire [7:0] dinA,       // input for A
    input  wire [7:0] dinB,       // input for B
    output wire [8:0] dout        // output from one lane (example)
);

    //------------------------------------------------------
    // PARAMETERS (same as PMU)
    //------------------------------------------------------
    localparam NUM_LANES  = 240;
    localparam DATA_WIDTH = 16;
    localparam OUT_W      = DATA_WIDTH + 1;

    //------------------------------------------------------
    // INTERNAL STORAGE (Equivalent to BRAM)
    //------------------------------------------------------

    reg [NUM_LANES*DATA_WIDTH-1:0] A_store = 0;
    reg [NUM_LANES*DATA_WIDTH-1:0] B_store = 0;

    reg [7:0] write_index = 0;

    //------------------------------------------------------
    // LOAD LOGIC (Example: feed 1 lane per cycle)
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
    // PMU INSTANCE
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
        .P_flat(P_bus)
    );

    //------------------------------------------------------
    // EXAMPLE OUTPUT (Expose only 1 lane to the board)
    //------------------------------------------------------

    assign dout = P_bus[OUT_W-1:0];  // lane 0 output

endmodule
