// 手動疊stage，讓design complier自己切stage

module SquareRoot #(
    parameter WIDTH = 32
) (
    input wire clk, 
    input wire reset, 
    input wire start,
    output reg busy,  
    output reg done, 
    
    input wire [WIDTH - 1 : 0] radicand, 
    output reg [WIDTH / 2 - 1 : 0] root
);
    parameter OUT_WIDTH = WIDTH / 2;

    reg [WIDTH - 1 : 0]radicand_r;
    reg [OUT_WIDTH - 1 : 0]remainder;
    reg [5:0]k;

    wire [OUT_WIDTH + 2 : 0]remainder_candidate_no_sub; // (4 * c_k + d_k)
    assign remainder_candidate_no_sub = {remainder, radicand_r[WIDTH - 1: WIDTH - 2]};
    wire [OUT_WIDTH + 2 : 0]remainder_candidate_sub; // (4 * c_k + d_k) - (4 * r_k + 1)
    assign remainder_candidate_sub = remainder_candidate_no_sub - {root, 2'b01};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            k <= 0; remainder <= 0; radicand_r <= 0;
            done <= 0; root <= 0; busy <= 0;
        end else begin
            if (start && !busy) begin
                k <= OUT_WIDTH; remainder <= (OUT_WIDTH)'b0; radicand_r <= radicand;
                done <= 0; root <= (OUT_WIDTH)'b0; busy <= 1;
            end else if (k > 0) begin
                if (remainder_candidate_sub[OUT_WIDTH + 2]) begin
                    root <= {root[OUT_WIDTH - 2 : 0], 1'b0};
                    remainder <= remainder_candidate_no_sub[OUT_WIDTH - 1 : 0];
                end else begin
                    root <= {root[OUT_WIDTH - 2 : 0], 1'b1};
                    remainder <= remainder_candidate_sub[OUT_WIDTH - 1 : 0];
                end
                radicand_r <= {radicand_r[WIDTH - 3 : 0], 2'b00};
                k <= k - 1;
            end else if (k == 0) begin
                done <= 1;
                busy <= 0;
                k <= k - 1;
            end
        end
    end

endmodule