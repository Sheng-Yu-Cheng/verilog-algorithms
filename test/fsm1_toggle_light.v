module fsm1_toggle_light (
    input wire clk,
    input wire rst_n, 
    input wire toggle, 
    output reg light
);
    localparam  
        S_OFF = 1'b0, 
        S_ON  = 1'b1
    ;

    reg state, next_state;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_OFF;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_ON: next_state = toggle ? S_OFF : state;
            S_OFF: next_state = toggle ? S_ON : state;
            default: next_state = S_OFF;
        endcase
    end

    always @(*) begin
        case (state)
            S_ON: begin
                light = 1;
            end
            S_OFF: begin
                light = 0;
            end
            default: begin
                light = 0;
            end
        endcase
    end
endmodule