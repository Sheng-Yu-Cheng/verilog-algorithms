module Cross (
    input wire signed [10:0]vec1[1:0], // {vx1, vy1}
    input wire signed [10:0]vec2[1:0], // {vx2, vy2}
    output wire signed [22:0]result
);
    assign result = vec1[0] * vec2[1] - vec1[1] * vec2[0];
endmodule