`timescale 1ns/1ps

module tb_SquareRoot;

    // =========================
    // Parameter (可改這裡)
    // =========================
    parameter WIDTH = 32;
    localparam OUT_WIDTH = WIDTH / 2;

    // =========================
    // DUT IO
    // =========================
    reg clk;
    reg reset;
    reg start;
    wire busy;
    wire done;

    reg  [WIDTH-1:0] radicand;
    wire [OUT_WIDTH-1:0] root;

    // =========================
    // Instantiate DUT
    // =========================
    SquareRoot #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .busy(busy),
        .done(done),
        .radicand(radicand),
        .root(root)
    );

    // =========================
    // Clock
    // =========================
    always #5 clk = ~clk;

    // =========================
    // Integer sqrt (golden)
    // =========================
    function [OUT_WIDTH-1:0] isqrt;
        input [WIDTH-1:0] x;
        reg   [WIDTH-1:0] r;
        reg   [WIDTH-1:0] bit;
        begin
            r = 0;
            bit = 1 << (WIDTH-2); // largest even power

            // 找到 <= x 的最高 bit
            while (bit > x)
                bit = bit >> 2;

            while (bit != 0) begin
                if (x >= r + bit) begin
                    x = x - (r + bit);
                    r = (r >> 1) + bit;
                end else begin
                    r = r >> 1;
                end
                bit = bit >> 2;
            end

            isqrt = r[OUT_WIDTH-1:0];
        end
    endfunction

    // =========================
    // Task: run one test
    // =========================
    task run_test;
        input [WIDTH-1:0] val;
        reg   [OUT_WIDTH-1:0] golden;
        begin
            @(posedge clk);
            radicand = val;
            start = 1;
            @(posedge clk);
            start = 0;

            // 等 done
            while (!done) @(posedge clk);

            golden = isqrt(val);

            if (root !== golden) begin
                $display("[FAIL] x=%0d (0x%h), root=%0d, golden=%0d",
                          val, val, root, golden);
            end else begin
                $display("[PASS] x=%0d root=%0d", val, root);
            end
        end
    endtask

    // =========================
    // Main
    // =========================
    integer i;

    initial begin
        clk = 0;
        reset = 1;
        start = 0;
        radicand = 0;

        #20;
        reset = 0;

        $display("=== Directed Tests ===");

        run_test(0);
        run_test(1);
        run_test(2);
        run_test(3);
        run_test(4);
        run_test(15);
        run_test(16);
        run_test(17);

        run_test({WIDTH{1'b1}}); // max

        $display("=== Random Tests ===");

        for (i = 0; i < 50; i = i + 1) begin
            run_test($random);
        end

        $display("=== DONE ===");
        $finish;
    end

endmodule