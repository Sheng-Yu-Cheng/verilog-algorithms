`timescale 1ns/1ps

module tb_BitonicSortingNetwork;

    logic clk;
    logic rst_n;
    logic start;
    logic busy;
    logic done;

    logic [7:0] cmp [7:0];
    logic [2:0] result [7:0];

    integer i;

    // DUT
    BitonicSortingNetwork dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start),
        .busy   (busy),
        .done   (done),
        .cmp    (cmp),
        .result (result)
    );

    // clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // ----------------------------
    // Utility tasks
    // ----------------------------
    task print_inputs;
        begin
            $write("[TB] cmp = ");
            for (i = 0; i < 8; i = i + 1) begin
                $write("%0d", cmp[i]);
                if (i != 7) $write(", ");
            end
            $write("\n");
        end
    endtask

    task print_results;
        begin
            $write("[TB] result index order = ");
            for (i = 0; i < 8; i = i + 1) begin
                $write("%0d", result[i]);
                if (i != 7) $write(", ");
            end
            $write("\n");
        end
    endtask

    task apply_case(
        input [7:0] c0, input [7:0] c1, input [7:0] c2, input [7:0] c3,
        input [7:0] c4, input [7:0] c5, input [7:0] c6, input [7:0] c7
    );
        begin
            cmp[0] = c0; cmp[1] = c1; cmp[2] = c2; cmp[3] = c3;
            cmp[4] = c4; cmp[5] = c5; cmp[6] = c6; cmp[7] = c7;
        end
    endtask

    task start_once;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_done;
        integer cycle_count;
        begin
            cycle_count = 0;
            while (done !== 1'b1 || busy !== 1'b0) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
                if (cycle_count > 20) begin
                    $display("[TB] ERROR: timeout waiting for done");
                    $finish;
                end
            end
            $display("[TB] done observed after %0d cycles", cycle_count);
        end
    endtask

    // ----------------------------
    // Monitor
    // ----------------------------
    initial begin
        $display("time   rst_n start busy done | result");
        forever begin
            @(posedge clk);
            $write("%4t   %0b     %0b    %0b    %0b  | ",
                   $time, rst_n, start, busy, done);
            for (i = 0; i < 8; i = i + 1) begin
                $write("%0d", result[i]);
                if (i != 7) $write(" ");
            end
            $write("\n");
        end
    end

    // ----------------------------
    // Stimulus
    // ----------------------------
    initial begin
        // init
        rst_n = 0;
        start = 0;
        for (i = 0; i < 8; i = i + 1)
            cmp[i] = 0;

        // reset
        #12;
        rst_n = 1;

        // after reset, result should be 0..7
        @(posedge clk);
        $display("\n[TB] After reset");
        print_results();

        // case 1
        $display("\n[TB] CASE 1");
        apply_case(8'd13, 8'd2, 8'd99, 8'd7, 8'd45, 8'd1, 8'd88, 8'd20);
        print_inputs();
        start_once();
        wait_done();
        print_results();

        // case 2
        $display("\n[TB] CASE 2");
        apply_case(8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1);
        print_inputs();
        start_once();
        wait_done();
        print_results();

        // case 3
        $display("\n[TB] CASE 3");
        apply_case(8'd10, 8'd10, 8'd3, 8'd3, 8'd50, 8'd50, 8'd1, 8'd1);
        print_inputs();
        start_once();
        wait_done();
        print_results();

        $display("\n[TB] Simulation finished.");
        #20;
        $finish;
    end

endmodule