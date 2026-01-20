#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(languages: codly-languages, display-icon: false, lang-format: none, zebra-fill: luma(250))

#set text(font: "Charter", lang: "en", region: "us", size: 12pt)
#set page(
  "us-letter",
  header: context{
  if counter(page).get().first() > 1 [
    #par(leading: 0.5em)[
      Grant Lemons
      #h(1fr)
      #counter(page).get().first()/#counter(page).final().last()\
      #datetime.today().display()
    ]
  ]
  }
)
#set par(justify: true, spacing: 1.5em)

#align(top + center, [
  #text(18pt)[*FPGA and Verilog Primer*]\
  #text(14pt)[Elements of Computer Systems]\
  #datetime.today().display()
  #v(1.2em)
])

= What is an FPGA?
FPGA stands for Field Programmable Gate Array, and is effectively a programmable circuit board.
Programmable in this sense does not mean you'll be able to upload a binary generated from your imperative or functional programming language of choice, as you might with a microcontroller, but rather that the logic of the circuit is declaratively defined as code in a Hardware Description Language (HDL).

The most common HDLs are VHDL and Verilog, of which several varieties exist.
For this class we will use Verilog, which we will be both flashing onto actual FPGA development boards and simulating.

= Modules
The fundamental building block in Verilog is the _module_.
Modules encapsulate some unit of digital logic, and provide a defined interface of inputs and outputs to interact with.

Take, for instance the following example module, which models a NAND gate:
#figure(
  caption: "A basic NAND gate modeled as a module."
)[
  ```Verilog
  module nand_gate ( input a, input b, output out );
    assign c = ~(a & b); // Don't worry about this syntax yet
  endmodule
  ```
]<module>

The module definition lays out the ports that provide the interface to the module, and those are categorized into ```Verilog input```, ```Verilog output```, or ```Verilog inout``` inside the module.
The default type of these ports is ```Verilog wire```, which is analogous to (and you won't believe this) a wire, in that it represents a single bit (`0` or `1`) and connects components together.

An instance of a module is declared using the module name, an instance name, and the port mapping, like so:
```Verilog
nand_gate ng (a, b, out); // This sets out to a NAND b
```

You can also bind ports by name with the following syntax:
```Verilog
// awire, bwire, and outwire are the identifiers of local wires
// .a() is the identifier of the port
nand_gate ng (.a(awire), .b(bwire), .out(outwire));
```

= Scalars and Vectors
Single bits like this are called _scalars_. To represent more than one bit under a single identifier, you can define a _vector_ in the following format:
```Verilog
<type> [<msb>:<lsb>] <ident>
```
Declaring an 8-bit-wide vector as an input to a module, for instance, might look like the following:
```Verilog
module example ( input [7:0] a );
```
For convenience, several alternative data types exist as shortcuts to vectors, such as ```Verilog integer``` and ```Verilog real```, which are 32-bit and 64-bit wide vectors intended to store integer and floating-point values respectively.

= Loops
If a module needs to be repeated many times with similar inputs and outputs, you can use a loop.
These loops look a lot like those in imperative languages, but remember that they are declarative and combinational.
Each module is completely parallel at runtime, not run one-after-another.

Loops need to be declared inside of a ```Verilog generate``` block, and the index needs to be declared as a ```Verilog genvar```.
Also, base Verilog does not have a `++` or `+=` operator for the loop variable.
This may trip you up.

Here's an example of using a for-loop to make a multi-bit version of a logic gate.
#figure(
  caption: "A bitwise-AND gate for an 4-bit vector implemented with a for loop."
)[
  ```Verilog
  // assume module `and (input a, b, output out)` exists
  module and4 ( input [3:0] a, b, output [3:0] out );
      genvar i;
      generate
          for (i = 0; i < 4; i = i + 1) begin
              and lp (.a(a[i]), .b(b[i]) .out(out[i]));
          end
      endgenerate
  endmodule
  ```
]<loop>

This is exactly equivalent to the following:
#figure(
  caption: "A bitwise-AND gate for an 4-bit vector implemented without a for loop."
)[
  ```Verilog
  module and4 ( input [7:0] in, output [7:0] out );
      and g0 (.a(a[0]), .b(b[0]) .out(out[0]));
      and g1 (.a(a[1]), .b(b[1]) .out(out[1]));
      and g2 (.a(a[2]), .b(b[2]) .out(out[2]));
      and g3 (.a(a[3]), .b(b[3]) .out(out[3]));
  endmodule
  ```
]<noloop>

= Continuous Assignment (Project 2+ Only)

We've been using modules for logic gates so far to drive our combinational logic, but this can get messy fast.
We need lots of temporary wires to pass signals between gates, and even simple logic requires a lot of lines.

Thankfully Verilog has an alternative: Continuous Assignment.
Instead of using modules to define the value of a wire, we can use familiar operators common in other programming languages.

These include, but are not limited to:
#table(
  columns: (1fr, 2fr),
  align: center,
  stroke: none,
  table.header(
    [*Operator*], [*Description*],
  ),
  [\~], [Bitwise NOT],
  [|], [Bitwise OR],
  [^], [Bitwise XOR],
  [&], [Bitwise AND],
  [<<], [Bitwise Left Shift],
  [>>], [Bitwise Left Shift],
  [!], [Logical NOT],
  [bool ? t : f], [Ternary Operator],
  [==], [Equals],
  [!=], [Not Equals],
)

Continuous Assignment may be Explicit or Implicit. For explicit assignment, use the assign keyword to assign an already-declared wire:
```Verilog
wire out;
assign out = a & b;
```
Implicit assignment is assigning the value of a wire as it is declared:
```Verilog
wire signal = load ? in : out;
```

While we ask you not to use continuous assignment in Project 1 so you can get a grasp on how gates fit together, we recommend using them in Projects 2 & 3. You'll find they simplify your modules (and file structure) significantly.

= Parameters
Thus far, the only way we've been able to influence the behavior of a module is by passing it input.
Sometimes, however, we want to define modules with similar behavior that vary in some way, such as vector size.

In Project 1 we created different modules for a 1-bit AND gate and 16-bit AND gate. With parameters, we can generalize the logic:
```Verilog
module and #(parameter N = 1) (
  input [N-1:0] a, b,
  output [N-1:0] out
);
  assign out = a & b;
endmodule
```

Now, to use this gate for 1-bit AND, we can use it like so:
```Verilog
and #(1) g0 (a, b, out);
and g1 (a, b, out); // We set 1 as the default, so we could omit it as well
```
And for 16-bit, like so:
```Verilog
and #(16) g0 (a, b, out);
and #(.N(16)) g1 (a, b, out); // Like with ports, we can use a name or order
```

== Muxlib (Project 3)

In Project 1 we created several multiplexers and demultiplexers that behave differently. We created 1-bit 2-way, 16-bit 2-way, 1-bit 4-way, 16-bit 8-way, &c. To simplify this, I've created two parameterized gates `mux` and `dmux` for your use in Project 3 (#link(<ADX:muxlib>, "Appendix A")). They work recursively by changing the parameterizations of the recursive calls until they reach a two-way mux/dmux.
Each one has to parameters: $W$, the number of ways to mux/dmux, and $N$, the width of the data type.
You may find this helpful in your RAM implementations.

Note: the inputs and outputs are packed arrays, so you'd need to do:
```Verilog
mux #(2, 1) m ({a, b}, sel, out);
```

= Sequential Logic
Combinational Logic is any digital logic that doesn't have a time component.
No state is involved; the current output is entirely dependent on the current input.
To build a computer, we need some sort of stateful component that can preserve data over time, called a sequential chip.

== Clock Cycles
Computers have a physical clock element that alternates in cycles between high and low signals.
This signal is simultaneously accessible (effectively, though this is limited by the speed of light) by every sequential chip in the computer.

A Data Flip-Flop (or D-flip-flop) is a basic sequential chip that has a single-bit data input and output and a clock input.
The behavior is as follows, where $t$ is the current clock cycle: 
$ "out"(t) = "in"(t-1) $
Meaning the current output is the input from the previous clock cycle.

== Registers in Hardware

Using a D-flip-flop, we can model a register, which maintains it's current value until it is updated.

#figure(
  caption: "A single-bit hardware register implemented with a D-flip-flop and a multiplexer."
)[
  ```Verilog
  module bit(input in, load, output out);
      wire signal;
      mux mx (.a(out), .b(in), .sel(load), .out(signal));
      dff ff (.in(signal), .out(out));
  endmodule
  ```
]<bit>

== Registers in Verilog
Wires do not persist data like variables in imperative languages, they are purely combinational.
The output of a wire is entirely driven by some other value and cannot persist across clock cycles.

In @module:2, for instance, `c` is entirely driven by `a` and `b`; it does not store a value.
To persist values in Verilog, define a register using the `reg` keyword.

As an example, the clock module used in my D-flip-flop implementation in project 3 (#link(<ADX:dff>, "Appendix B")) is the source of the `clock` signal used elsewhere. As such, we declare it with the ```Verilog reg``` keyword.
```Verilog
module clock (output reg clock);
    initial begin
        clock = 0;
    end

    always begin
        #1 clock = ~clock;
    end
endmodule
```

There are two ways to assign to a register, using equals (`=`) or a double-left-arrow (`<=`).
Equals is blocking, while the double-left-arrow is non-blocking and and is performed on the next positive edge of the system clock.

#let code(file, title: auto, title-full: true) = {
  let title = if title == auto {
    if title-full { file } else { file.split("/").last() }
  } else { title }
  let header = if title != none {
    align(left, block(width: 100%, stroke: (bottom: 1pt), outset: 0.5em, title))
  }
  codly(header: header)
  raw(read(file), lang: "Verilog", block: true)
}

#page[#align(center)[
  = Appendix A: Muxlib Implementation <ADX:muxlib>
  #code("muxlib.v", title: "project-3/tests/muxlib.v")
]]

#page[#align(center)[
  = Appendix B: D-Flip-Flop Implementation <ADX:dff>
  #code("dff.v", title: "project-3/tests/dff.v")
]]
