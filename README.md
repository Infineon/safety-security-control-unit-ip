# Safety and Security Control Unit

This repository contains the Safety and Security Control Unit (SSCU), a
synchronous RISC-V safety block that collects corrected and uncorrected error
indications, maintains group status in CSRs, and requests processor traps.

## Directory structure

- [`doc/`](doc/) - Architecture and integration documentation.
- [`ipcard/`](ipcard/) - IP metadata for the SSCU.
- [`sim/`](sim/) - Standalone SystemVerilog testbench.
- [`src/`](src/) - Synthesizable Verilog RTL.

## RTL

The top-level module is
[`Top_SoC_CPUCore_safety_management_unit`](src/Top_SoC_CPUCore_safety_management_unit.v).
It connects two independent trap-group processes to the group CSR interfaces
and exposes the group trap requests.

The RTL source list and compilation order are defined in
[`Bender.yml`](Bender.yml).

## Documentation

Start with [`doc/sscu.adoc`](doc/sscu.adoc) for the architecture, alarm
encoding, interfaces, and integration requirements.

## Simulation

The standalone testbench is [`sim/safety_unit_tb.sv`](sim/safety_unit_tb.sv)
and its simulation top module is `safety_unit_tb`. The testbench is not part of
the Bender RTL source list; compile it together with the RTL sources using the
SystemVerilog options required by the selected simulator.