# RTL Source

This directory contains the Verilog RTL implementation of the Safety and
Security Control Unit.

## Top-level module

[`Top_SoC_CPUCore_safety_management_unit.v`](Top_SoC_CPUCore_safety_management_unit.v)
contains the `Top_SoC_CPUCore_safety_management_unit` module. It instantiates
the two group-process blocks and connects their CSR read, CSR write, and trap
signals.

## Implementation blocks

- `Top_SoC_CPUCore_safety_management_unit_trap1_group_process.v` implements
  group 1 error processing.
- `Top_SoC_CPUCore_safety_management_unit_trap2_group_process.v` implements
  group 2 error processing.
- `Top_CounterReg.v` implements the error counters.
- `Top_NextCsrLogic.v` computes the next CSR value and write enable.
- `Top_PriorityErrorEncoding.v` generates the prioritized alarm encoding.

Use [`../Bender.yml`](../Bender.yml) as the canonical RTL source list and
compilation order.