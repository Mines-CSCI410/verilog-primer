/*
 * Copyright Grant Lemons for CSCI410
 * 2025-11-03
 */

module clock(output reg clock);
    initial begin
        clock = 0;
    end

    always begin
        #1 clock = ~clock;
    end
endmodule

module dff(input in, output out);
    wire clk;
    clock c (clk);
    clock_dff inner (in, clk, out);
endmodule

module clock_dff(input in, input clock, output reg out);
    initial begin
        out = 0;
    end
    always @(posedge clock) begin
        out = in;
    end
endmodule