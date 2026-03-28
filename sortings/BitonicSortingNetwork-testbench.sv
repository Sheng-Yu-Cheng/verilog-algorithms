`timescale 1ns/1ps

/*
Run:
vcs -R -full64 -sverilog BitonicSortingNetwork_geofence_tb.sv BitonicSortingNetwork.v +access+r +vcs+fsdbon
*/

module tb_BitonicSortingNetwork;

    logic clk;
    logic rst_n;
    logic start;
    logic busy;
    logic done;

    logic [7:0] cmp [7:0];
    logic [2:0] result [7:0];

    integer i, j, t;

    // generic values for full-sort testing
    integer value [7:0];
    integer golden [7:0];

    // geofence-style angle ranks for indices 0..5
    // indices 6,7 are dummy
    integer rank6 [5:0];
    integer golden6 [5:0];

    integer total_tests;
    integer pass_tests;

    BitonicSortingNetwork dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start),
        .busy   (busy),
        .done   (done),
        .cmp    (cmp),
        .result (result)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $fsdbDumpfile("BitonicSortingNetwork_geofence_tb.fsdb");
        $fsdbDumpvars(0, tb_BitonicSortingNetwork);
    end

    // ----------------------------
    // common utils
    // ----------------------------
    task do_reset;
        begin
            rst_n  = 0;
            start  = 0;
            for (i = 0; i < 8; i = i + 1) cmp[i] = '0;
            repeat (2) @(negedge clk);
            rst_n = 1;
            repeat (1) @(negedge clk);
        end
    endtask

    task pulse_start;
        begin
            @(negedge clk);
            start = 1;
            @(negedge clk);
            start = 0;
        end
    endtask

    task wait_done;
        integer cyc;
        begin
            cyc = 0;
            while (!done) begin
                @(posedge clk);
                cyc = cyc + 1;
                if (cyc > 20) begin
                    $display("[TB] ERROR: timeout waiting done");
                    $finish;
                end
            end
        end
    endtask

    task print_result;
        begin
            $write("[TB] result idx = ");
            for (i = 0; i < 8; i = i + 1) begin
                $write("%0d", result[i]);
                if (i != 7) $write(" ");
            end
            $write("\n");
        end
    endtask

    // ============================================================
    // PART 1: generic full-sort test
    // ============================================================
    task build_cmp_from_values;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    if (value[i] < value[j])
                        cmp[i][j] = 1'b1;
                    else if (value[i] > value[j])
                        cmp[i][j] = 1'b0;
                    else
                        cmp[i][j] = (i <= j); // deterministic tie-break
                end
            end
        end
    endtask

    task build_golden_full;
        integer tmp;
        begin
            for (i = 0; i < 8; i = i + 1) golden[i] = i;

            for (i = 0; i < 8; i = i + 1) begin
                for (j = i + 1; j < 8; j = j + 1) begin
                    if (value[golden[j]] < value[golden[i]] ||
                       ((value[golden[j]] == value[golden[i]]) && (golden[j] < golden[i]))) begin
                        tmp       = golden[i];
                        golden[i] = golden[j];
                        golden[j] = tmp;
                    end
                end
            end
        end
    endtask

    task check_full_sort;
        integer mismatch;
        begin
            mismatch = 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (result[i] !== golden[i][2:0])
                    mismatch = 1;
            end

            total_tests = total_tests + 1;

            if (mismatch) begin
                $display("[TB][FULL] FAIL");
                $write("  values      = ");
                for (i = 0; i < 8; i = i + 1) begin
                    $write("%0d", value[i]);
                    if (i != 7) $write(" ");
                end
                $write("\n");

                print_result();

                $write("  golden idx  = ");
                for (i = 0; i < 8; i = i + 1) begin
                    $write("%0d", golden[i]);
                    if (i != 7) $write(" ");
                end
                $write("\n\n");
            end else begin
                pass_tests = pass_tests + 1;
                $display("[TB][FULL] PASS");
            end
        end
    endtask

    task run_full_case(
        input integer v0, input integer v1, input integer v2, input integer v3,
        input integer v4, input integer v5, input integer v6, input integer v7
    );
        begin
            value[0]=v0; value[1]=v1; value[2]=v2; value[3]=v3;
            value[4]=v4; value[5]=v5; value[6]=v6; value[7]=v7;

            build_cmp_from_values();
            build_golden_full();
            pulse_start();
            wait_done();
            check_full_sort();
        end
    endtask

    // ============================================================
    // PART 2: geofence-style test
    //
    // Only 0..5 are real vertices.
    // 6 and 7 are dummy lanes and MUST NOT appear in result[0:5].
    //
    // cmp meaning:
    //   cmp[a][b] = 1 means "a should come before b"
    //
    // We model 0..5 by angular rank.
    // Smaller rank means earlier in sorted order.
    //
    // We intentionally force dummies 6,7 to be the largest two.
    // If sorter is valid for geofence, final result[0:5] must be exactly
    // the 6 real vertex indices in order, and result[6:7] must be 6,7.
    // ============================================================
    task build_golden6;
        integer tmp;
        begin
            for (i = 0; i < 6; i = i + 1) golden6[i] = i;

            for (i = 0; i < 6; i = i + 1) begin
                for (j = i + 1; j < 6; j = j + 1) begin
                    if (rank6[golden6[j]] < rank6[golden6[i]] ||
                       ((rank6[golden6[j]] == rank6[golden6[i]]) && (golden6[j] < golden6[i]))) begin
                        tmp         = golden6[i];
                        golden6[i]  = golden6[j];
                        golden6[j]  = tmp;
                    end
                end
            end
        end
    endtask

    task build_cmp_geofence;
        begin
            // clear all
            for (i = 0; i < 8; i = i + 1)
                for (j = 0; j < 8; j = j + 1)
                    cmp[i][j] = 1'b0;

            // real vertices 0..5 ordered by rank6
            for (i = 0; i < 6; i = i + 1) begin
                for (j = 0; j < 6; j = j + 1) begin
                    if (rank6[i] < rank6[j])
                        cmp[i][j] = 1'b1;
                    else if (rank6[i] > rank6[j])
                        cmp[i][j] = 1'b0;
                    else
                        cmp[i][j] = (i <= j);
                end
            end

            // Make all real vertices come before dummies 6,7
            for (i = 0; i < 6; i = i + 1) begin
                cmp[i][6] = 1'b1;
                cmp[i][7] = 1'b1;
                cmp[6][i] = 1'b0;
                cmp[7][i] = 1'b0;
            end

            // dummy ordering: 6 before 7
            cmp[6][6] = 1'b1;
            cmp[6][7] = 1'b1;
            cmp[7][6] = 1'b0;
            cmp[7][7] = 1'b1;
        end
    endtask

    task check_geofence_sort;
        integer mismatch;
        integer seen [7:0];
        begin
            mismatch = 0;

            for (i = 0; i < 8; i = i + 1) seen[i] = 0;

            // first 6 outputs must be exactly the real vertices in expected order
            for (i = 0; i < 6; i = i + 1) begin
                if (result[i] > 3'd5)
                    mismatch = 1;
                if (result[i] !== golden6[i][2:0])
                    mismatch = 1;
                seen[result[i]] = seen[result[i]] + 1;
            end

            // last two must be dummies 6 and 7 in order
            if (result[6] !== 3'd6) mismatch = 1;
            if (result[7] !== 3'd7) mismatch = 1;

            // uniqueness check for 0..5
            for (i = 0; i < 6; i = i + 1) begin
                if (seen[i] != 1)
                    mismatch = 1;
            end

            total_tests = total_tests + 1;

            if (mismatch) begin
                $display("[TB][GEOFENCE] FAIL");
                $write("  rank6       = ");
                for (i = 0; i < 6; i = i + 1) begin
                    $write("%0d", rank6[i]);
                    if (i != 5) $write(" ");
                end
                $write("\n");

                $write("  golden6 idx = ");
                for (i = 0; i < 6; i = i + 1) begin
                    $write("%0d", golden6[i]);
                    if (i != 5) $write(" ");
                end
                $write("\n");

                print_result();
                $display("  ERROR: dummy index leaked into front half or ordering is wrong.\n");
            end else begin
                pass_tests = pass_tests + 1;
                $display("[TB][GEOFENCE] PASS");
            end
        end
    endtask

    task run_geofence_case(
        input integer r0, input integer r1, input integer r2,
        input integer r3, input integer r4, input integer r5
    );
        begin
            rank6[0]=r0; rank6[1]=r1; rank6[2]=r2;
            rank6[3]=r3; rank6[4]=r4; rank6[5]=r5;

            build_golden6();
            build_cmp_geofence();
            pulse_start();
            wait_done();
            check_geofence_sort();
        end
    endtask

    task run_geofence_random;
        integer perm [5:0];
        integer tmp;
        integer a, b;
        begin
            // generate random permutation 0..5
            for (a = 0; a < 6; a = a + 1) perm[a] = a;
            for (a = 5; a > 0; a = a - 1) begin
                b = $urandom_range(0, a);
                tmp     = perm[a];
                perm[a] = perm[b];
                perm[b] = tmp;
            end

            run_geofence_case(perm[0], perm[1], perm[2], perm[3], perm[4], perm[5]);
        end
    endtask

    // ----------------------------
    // optional cycle monitor
    // ----------------------------
    initial begin
        $display("time  rst_n start busy done | result");
        forever begin
            @(posedge clk);
            $write("%4t   %0b    %0b    %0b    %0b | ",
                $time, rst_n, start, busy, done);
            for (i = 0; i < 8; i = i + 1) begin
                $write("%0d", result[i]);
                if (i != 7) $write(" ");
            end
            $write("\n");
        end
    end

    // ----------------------------
    // main
    // ----------------------------
    initial begin
        total_tests = 0;
        pass_tests  = 0;

        do_reset();

        $display("\n========== FULL-SORT SANITY TESTS ==========\n");
        run_full_case(13, 2, 99, 7, 45, 1, 88, 20);
        run_full_case(8, 7, 6, 5, 4, 3, 2, 1);
        run_full_case(1, 2, 3, 4, 5, 6, 7, 8);
        run_full_case(10, 10, 3, 3, 50, 50, 1, 1);
        run_full_case(5, 5, 5, 5, 5, 5, 5, 5);
        run_full_case(42, 0, 17, 17, 99, 3, 42, 1);

        $display("\n========== GEOFENCE-SPECIFIC TESTS ==========\n");

        // Directed permutations
        run_geofence_case(0,1,2,3,4,5);
        run_geofence_case(5,4,3,2,1,0);
        run_geofence_case(2,5,0,4,1,3);
        run_geofence_case(3,0,5,1,4,2);
        run_geofence_case(1,4,2,5,0,3);
        run_geofence_case(4,2,5,0,3,1);

        // Random permutations
        for (t = 0; t < 100; t = t + 1)
            run_geofence_random();

        $display("\n[TB] SUMMARY: %0d / %0d passed", pass_tests, total_tests);

        if (pass_tests == total_tests)
            $display("[TB] ALL TESTS PASSED");
        else
            $display("[TB] SOME TESTS FAILED");

        #20;
        $finish;
    end

endmodule