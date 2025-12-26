/*
 * Copyright Grant Lemons for CSCI410
 * 2025-11-03
 *
 * These modules provide parameterized multiplexers and demultiplexers that
 * work with different type lengths (N) and ways to split/merge (W).
 * The multiplexer's in and the demultiplexer's out ports are packed arrays of
 * bus size N and count W.
 * The selector bus is size log2(W).
 */

module mux #(parameter W = 2, parameter N = 1) (
    input [(W*N)-1:0] in,
    input [$clog2(W)-1:0] sel,
    output [N-1:0] out
);
    wire [N-1:0] tmp [1:0];
    generate
        if (W == 2) begin
            assign tmp[0] = in[N-1:0];
            assign tmp[1] = in[(N*2)-1:N];
        end
        else begin
            mux #(W/2, N) m0 (in[(W*N/2)-1:0], sel[$clog2(W)-2:0], tmp[0]);
            mux #(W/2, N) m1 (in[(W*N)-1:W*N/2], sel[$clog2(W)-2:0], tmp[1]);
        end
    endgenerate
    assign out = sel[$clog2(W)-1] ? tmp[0] : tmp[1];
endmodule

module dmux #(parameter W = 2, parameter N = 1) (
    input [N-1:0] in,
    input [$clog2(W)-1:0] sel,
    output [(W*N)-1:0] out
);
    wire [N-1:0] tmp [1:0];
    assign tmp[0] = sel[$clog2(W)-1] ? 0 : in;
    assign tmp[1] = sel[$clog2(W)-1] ? in : 0;
    generate
        if (W == 2)
            assign out = { tmp[0], tmp[1] };
        else begin
            dmux #(W/2, N) d1 (tmp[0], sel[$clog2(W)-2:0], out[(W*N)-1:W*N/2]);
            dmux #(W/2, N) d0 (tmp[1], sel[$clog2(W)-2:0], out[(W*N/2)-1:0]);
        end
    endgenerate
endmodule