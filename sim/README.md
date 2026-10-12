# Simulation

This directory contains the standalone SystemVerilog testbench for the SSCU.

## Testbench

[`safety_unit_tb.sv`](safety_unit_tb.sv) contains the `safety_unit_tb`
simulation top. It drives randomized corrected and uncorrected error vectors
for both groups and checks trap requests, CSR write enables, CSR data, masking,
and overflow encoding.

Compile the testbench together with the RTL files in [`../src/`](../src/),
using SystemVerilog mode and `safety_unit_tb` as the simulation top. The
testbench is intentionally kept outside [`../Bender.yml`](../Bender.yml),
which describes the synthesizable RTL package.