`timescale 1ns/1ps

/*
Run:
vcs -R -full64 -sverilog BitonicSortingNetwork-testbench.sv BitonicSortingNetwork.v +access+r +vcs+fsdbon
*/

module tb_BitonicSortingNetwork;

    logic clk;
    logic rst_n;
    logic start;
    logic busy;
    logic done;

    // DUT interface
    logic [7:0] cmp [7:0];
    logic [2:0] result [7:0];

    // local stimulus / golden
    integer value  [7:0];
    integer golden [7:0];

    integer i, j;
    integer total_tests;
    integer pass_tests;

    // ----------------------------
    // DUT
    // ----------------------------
    BitonicSortingNetwork dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start),
        .busy   (busy),
        .done   (done),
        .cmp    (cmp),
        .result (result)
    );

    // ----------------------------
    // clock
    // ----------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ----------------------------
    // FSDB
    // ----------------------------
    initial begin
        $fsdbDumpfile("BitonicSortingNetwork.fsdb");
        $fsdbDumpvars(0, tb_BitonicSortingNetwork);
    end

    // ----------------------------
    // Utility: print
    // ----------------------------
    task print_values;
        begin
            $write("[TB] values        = ");
            for (i = 0; i < 8; i = i + 1) begin
                $write("%0d", value[i]);
                if (i != 7) $write(", ");
            end
            $write("\n");
        end
    endtask

    task print_result_indices;
        begin
            $write("[TB] DUT result idx = ");
            for (i = 0; i < 8; i = i + 1) begin
                $write("%0d", result[i]);
                if (i != 7) $write(", ");
            end
            $write("\n");
        end
    endtask

    task print_golden_indices;
        begin
            $write("[TB] golden idx     = ");
            for (i = 0; i < 8; i = i + 1) begin
                $write("%0d", golden[i]);
                if (i != 7) $write(", ");
            end
            $write("\n");
        end
    endtask

    task print_result_values;
        begin
            $write("[TB] DUT values     = ");
            for (i = 0; i < 8; i = i + 1) begin
                $write("%0d", value[result[i]]);
                if (i != 7) $write(", ");
            end
            $write("\n");
        end
    endtask

    task print_golden_values;
        begin
            $write("[TB] golden values  = ");
            for (i = 0; i < 8; i = i + 1) begin
                $write("%0d", value[golden[i]]);
                if (i != 7) $write(", ");
            end
            $write("\n");
        end
    endtask

    // ----------------------------
    // Build cmp matrix from values
    // cmp[a][b] = 1 means value[a] <= value[b]
    // tie-break by index to make ordering deterministic
    // ----------------------------
    task build_cmp_from_values;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    if (value[i] < value[j])
                        cmp[i][j] = 1'b1;
                    else if (value[i] > value[j])
                        cmp[i][j] = 1'b0;
                    else
                        cmp[i][j] = (i <= j); // stable tie-break
                end
            end
        end
    endtask

    // ----------------------------
    // Build golden sorted index order
    // ascending by value, tie-break by index
    // ----------------------------
    task build_golden;
        integer tmp;
        begin
            for (i = 0; i < 8; i = i + 1)
                golden[i] = i;

            for (i = 0; i < 8; i = i + 1) begin
                for (j = i + 1; j < 8; j = j + 1) begin
                    if (value[golden[j]] < value[golden[i]]) begin
                        tmp       = golden[i];
                        golden[i] = golden[j];
                        golden[j] = tmp;
                    end
                    else if (value[golden[j]] == value[golden[i]] &&
                             golden[j] < golden[i]) begin
                        tmp       = golden[i];
                        golden[i] = golden[j];
                        golden[j] = tmp;
                    end
                end
            end
        end
    endtask

    // ----------------------------
    // Reset
    // ----------------------------
    task do_reset;
        begin
            rst_n = 1'b0;
            start = 1'b0;
            for (i = 0; i < 8; i = i + 1)
                cmp[i] = '0;

            repeat (2) @(negedge clk);
            rst_n = 1'b1;
            repeat (1) @(negedge clk);
        end
    endtask

    // ----------------------------
    // Start pulse: one cycle
    // ----------------------------
    task start_once;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    // ----------------------------
    // Wait until DUT returns idle
    // ----------------------------
    task wait_done;
        integer cycle_count;
        begin
            cycle_count = 0;
            while ((done !== 1'b1) || (busy !== 1'b0)) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
                if (cycle_count > 20) begin
                    $display("[TB] ERROR: timeout waiting for done");
                    $finish;
                end
            end
        end
    endtask

    // ----------------------------
    // Compare DUT result with golden
    // ----------------------------
    task check_result;
        integer mismatch;
        begin
            mismatch = 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (result[i] !== golden[i][2:0])
                    mismatch = 1;
            end

            total_tests = total_tests + 1;

            if (mismatch) begin
                $display("[TB] FAIL");
                print_values();
                print_result_indices();
                print_golden_indices();
                print_result_values();
                print_golden_values();
                $display("");
            end
            else begin
                pass_tests = pass_tests + 1;
                $display("[TB] PASS");
                print_values();
                print_result_indices();
                print_result_values();
                $display("");
            end
        end
    endtask

    // ----------------------------
    // One test wrapper
    // ----------------------------
    task run_case(
        input integer v0, input integer v1, input integer v2, input integer v3,
        input integer v4, input integer v5, input integer v6, input integer v7
    );
        begin
            value[0] = v0; value[1] = v1; value[2] = v2; value[3] = v3;
            value[4] = v4; value[5] = v5; value[6] = v6; value[7] = v7;

            build_cmp_from_values();
            build_golden();
            start_once();
            wait_done();
            check_result();
        end
    endtask

    // ----------------------------
    // Optional monitor
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
    // Main stimulus
    // ----------------------------
    initial begin
        total_tests = 0;
        pass_tests  = 0;

        do_reset();

        $display("\n[TB] Directed tests start\n");

        // distinct values
        run_case(13, 2, 99, 7, 45, 1, 88, 20);

        // descending
        run_case(8, 7, 6, 5, 4, 3, 2, 1);

        // ascending
        run_case(1, 2, 3, 4, 5, 6, 7, 8);

        // duplicates
        run_case(10, 10, 3, 3, 50, 50, 1, 1);

        // all equal
        run_case(5, 5, 5, 5, 5, 5, 5, 5);

        // mixed
        run_case(42, 0, 17, 17, 99, 3, 42, 1);

        $display("[TB] Summary: %0d / %0d passed", pass_tests, total_tests);

        if (pass_tests == total_tests)
            $display("[TB] ALL TESTS PASSED");
        else
            $display("[TB] SOME TESTS FAILED");

        #20;
        $finish;
    end

endmodule