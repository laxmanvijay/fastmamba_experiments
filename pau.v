// Clocked Parallel Adder Unit (simple version)
// Adds A and B element-wise, registers the result on each clock edge.

module pau #(
    parameter NUM_LANES  = 4,
    parameter DATA_WIDTH = 16
)(
    input  wire clk,
    input  wire rst,   // synchronous active-high reset

    input  wire [NUM_LANES*DATA_WIDTH-1:0] A_flat,
    input  wire [NUM_LANES*DATA_WIDTH-1:0] B_flat,

    output reg  [NUM_LANES*(DATA_WIDTH+1)-1:0] P_flat   // registered output
);

    localparam OUT_W = DATA_WIDTH + 1;

    wire [OUT_W-1:0] lane_sum [0:NUM_LANES-1];

    genvar i;
    generate
        for (i = 0; i < NUM_LANES; i = i + 1) begin : ADD_LANE
            wire [DATA_WIDTH-1:0] Ai =
                A_flat[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
            wire [DATA_WIDTH-1:0] Bi =
                B_flat[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];

            assign lane_sum[i] = {1'b0, Ai} + {1'b0, Bi};
        end
    endgenerate

    integer j;
    always @(posedge clk) begin
        if (rst) begin
            P_flat <= {NUM_LANES*(OUT_W){1'b0}};
        end else begin
            for (j = 0; j < NUM_LANES; j = j + 1) begin
                P_flat[(j+1)*OUT_W-1 -: OUT_W] <= lane_sum[j];
            end
        end
    end

endmodule
