module BitonicSortingNetwork (
    input wire clk, 
    input wire rst_n, 
    input wire start, 
    output reg busy, 
    output reg done, 

    input  [7:0] cmp [7:0], 
    output reg [2:0] result [7:0]
);
    typedef enum logic [2:0] {
        S_IDLE, 
        S_BI1, 
        S_BI2, 
        S_BI2_MG2, 
        S_BI4, 
        S_BI4_MG4, 
        S_BI4_MG2
    } state_t;
    state_t state, next_state;
    reg do_bi1; reg do_bi2; reg do_bi4;
    reg do_bi2_mg2; reg do_bi4_mg4; reg do_bi4_mg2;

    // ----------------------------- State Register -----------------------------
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE; 
            for (i = 0; i < 8; i++) result[i] = i;
        end else begin
            if (do_bi1) begin
                {result[1], result[0]} <= (cmp[result[1]] > cmp[result[0]]) ? {result[1], result[0]} : {result[0], result[1]};
                {result[3], result[2]} <= (cmp[result[3]] < cmp[result[2]]) ? {result[3], result[2]} : {result[2], result[3]};
                {result[5], result[4]} <= (cmp[result[5]] > cmp[result[4]]) ? {result[5], result[4]} : {result[4], result[5]};
                {result[7], result[6]} <= (cmp[result[7]] < cmp[result[6]]) ? {result[7], result[6]} : {result[6], result[7]};
            end
            if (do_bi2) begin
                {result[2], result[0]} <= (cmp[result[2]] > cmp[result[0]]) ? {result[2], result[0]} : {result[0], result[2]};
                {result[3], result[1]} <= (cmp[result[3]] > cmp[result[1]]) ? {result[3], result[1]} : {result[1], result[3]};
                {result[6], result[4]} <= (cmp[result[6]] < cmp[result[4]]) ? {result[6], result[4]} : {result[4], result[6]};
                {result[7], result[5]} <= (cmp[result[7]] < cmp[result[5]]) ? {result[7], result[5]} : {result[5], result[7]};
            end 
            if (do_bi2_mg2) begin
                {result[1], result[0]} <= (cmp[result[1]] > cmp[result[0]]) ? {result[1], result[0]} : {result[0], result[1]};
                {result[3], result[2]} <= (cmp[result[3]] > cmp[result[2]]) ? {result[3], result[2]} : {result[2], result[3]};
                {result[5], result[4]} <= (cmp[result[5]] < cmp[result[4]]) ? {result[5], result[4]} : {result[4], result[5]};
                {result[7], result[6]} <= (cmp[result[7]] < cmp[result[6]]) ? {result[7], result[6]} : {result[6], result[7]};
            end
            if (do_bi4) begin
                {result[4], result[0]} <= (cmp[result[4]] > cmp[result[0]]) ? {result[4], result[0]} : {result[0], result[4]};
                {result[5], result[1]} <= (cmp[result[5]] > cmp[result[1]]) ? {result[5], result[1]} : {result[1], result[5]};
                {result[6], result[2]} <= (cmp[result[6]] > cmp[result[2]]) ? {result[6], result[2]} : {result[2], result[6]};
                {result[7], result[3]} <= (cmp[result[7]] > cmp[result[3]]) ? {result[7], result[3]} : {result[3], result[7]};
            end 
            if (do_bi4_mg4) begin
                {result[2], result[0]} <= (cmp[result[2]] > cmp[result[0]]) ? {result[2], result[0]} : {result[0], result[2]};
                {result[3], result[1]} <= (cmp[result[3]] > cmp[result[1]]) ? {result[3], result[1]} : {result[1], result[3]};
                {result[6], result[4]} <= (cmp[result[6]] > cmp[result[4]]) ? {result[6], result[4]} : {result[4], result[6]};
                {result[7], result[5]} <= (cmp[result[7]] > cmp[result[5]]) ? {result[7], result[5]} : {result[5], result[7]};
            end 
            if (do_bi4_mg2) begin
                {result[1], result[0]} <= (cmp[result[1]] > cmp[result[0]]) ? {result[1], result[0]} : {result[0], result[1]};
                {result[3], result[2]} <= (cmp[result[3]] > cmp[result[2]]) ? {result[3], result[2]} : {result[2], result[3]};
                {result[5], result[4]} <= (cmp[result[5]] > cmp[result[4]]) ? {result[5], result[4]} : {result[4], result[5]};
                {result[7], result[6]} <= (cmp[result[7]] > cmp[result[6]]) ? {result[7], result[6]} : {result[6], result[7]};
            end
            state <= next_state;
        end
    end


    // ---------------------------- Next State Logic ----------------------------
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE      : if (start) next_state = S_BI1;
            S_BI1       : next_state = S_BI2;
            S_BI2       : next_state = S_BI2_MG2;
            S_BI2_MG2   : next_state = S_BI4;
            S_BI4       : next_state = S_BI4_MG4;
            S_BI4_MG4   : next_state = S_BI4_MG2;
            S_BI4_MG2   : next_state = S_IDLE;
        endcase
    end


    // ------------------------------ Output Logic ------------------------------
    always @(*) begin
        busy = (state != S_IDLE);
        done = (state == S_IDLE);
        do_bi1       = 0;
        do_bi2       = 0;
        do_bi2_mg2   = 0;
        do_bi4       = 0;
        do_bi4_mg4   = 0;
        do_bi4_mg2   = 0;
        case (state)
            S_BI1:       do_bi1 = 1;
            S_BI2:       do_bi2 = 1;
            S_BI2_MG2:   do_bi2_mg2 = 1;
            S_BI4:       do_bi4 = 1;
            S_BI4_MG4:   do_bi4_mg4 = 1;
            S_BI4_MG2:   do_bi4_mg2 = 1;
        endcase
    end

endmodule