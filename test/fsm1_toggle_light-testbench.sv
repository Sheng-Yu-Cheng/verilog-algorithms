`timescale 1ns/1ps

module tb_fsm1_toggle_light;

    reg clk;
    reg rst_n;
    reg toggle;
    wire light;

    fsm1_toggle_light dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .toggle (toggle),
        .light  (light)
    );

    initial begin
        $fsdbDumpfile("tb_fsm1_toggle_light.fsdb");
        $fsdbDumpvars(0, tb_fsm1_toggle_light);
    end

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        toggle = 0;

        #12;
        rst_n = 1;

        // toggle once -> ON
        @(negedge clk); toggle = 1;
        @(negedge clk); toggle = 0;

        // wait
        repeat (2) @(negedge clk);

        // toggle again -> OFF
        @(negedge clk); toggle = 1;
        @(negedge clk); toggle = 0;

        // consecutive toggles
        @(negedge clk); toggle = 1;
        @(negedge clk); toggle = 1;
        @(negedge clk); toggle = 0;

        repeat (3) @(negedge clk);
        $finish;
    end

    initial begin
        $display("time\tclk rst_n toggle light");
        $monitor("%0t\t%b   %b     %b      %b", $time, clk, rst_n, toggle, light);
    end

endmodule